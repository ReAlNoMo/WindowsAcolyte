# Isolated WPF windows; no system settings, downloads, or production module actions.
param([string]$RenderDirectory)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework
Add-Type @'
public static class ProcessingBusyProbe {
    [System.Runtime.InteropServices.DllImport("user32.dll")] public static extern System.IntPtr GetWindow(System.IntPtr h, uint command);
    [System.Runtime.InteropServices.DllImport("user32.dll")] public static extern System.IntPtr GetTopWindow(System.IntPtr h);
    [System.Runtime.InteropServices.DllImport("user32.dll")] public static extern System.IntPtr GetForegroundWindow();
    [System.Runtime.InteropServices.DllImport("user32.dll")] public static extern bool SetWindowPos(System.IntPtr h, System.IntPtr after, int x, int y, int w, int height, uint flags);
    [System.Runtime.InteropServices.DllImport("user32.dll")] public static extern System.IntPtr SendMessage(System.IntPtr h, uint message, System.IntPtr w, System.IntPtr l);
    public static int Rank(System.IntPtr h) {
        var next=GetTopWindow(System.IntPtr.Zero);
        for(int rank=0; rank<10000 && next!=System.IntPtr.Zero; rank++,next=GetWindow(next,2)) if(next==h) return rank;
        return -1;
    }
    public static void Hold(int milliseconds) {
        var clock = System.Diagnostics.Stopwatch.StartNew();
        while (clock.ElapsedMilliseconds < milliseconds) System.Threading.Thread.SpinWait(1000);
    }
}
'@
. (Join-Path $PSScriptRoot '..\modules\00-ProcessingOverlay.ps1')
$Global:PTS_Theme=@{Surface='#FFFFFF';Border='#6C8799';Primary='#00375F';TextDark='#00375F';TextMuted='#3C5669'}
$Global:PTS_ThemeDark=@{Surface='#003050';Border='#7292A6';Primary='#D69A25';TextDark='#FFFFFF';TextMuted='#CDDBE6'}
$Global:PTS_DarkModeEnabled=$false
$Global:PTS_ActiveOperations=@{}
$Global:PTS_Window=[Windows.Window]::new()
$Global:PTS_Window.WindowStartupLocation='Manual'; $Global:PTS_Window.Left=-20000; $Global:PTS_Window.Top=-20000
$Global:PTS_Window.Width=1000; $Global:PTS_Window.Height=700
$Global:PTS_Window.ShowActivated=$false; $Global:PTS_Window.ShowInTaskbar=$false
function Write-PTSExceptionReport { param($Context,$ModuleId,$Exception,$ErrorRecord); throw "Unexpected report: $Context $Exception $ErrorRecord" }
function Set-PTSFooterStatus { param($Text) }
$script:checks=0
function Assert-Processing($Condition,$Message) {
    if(-not $Condition){throw "FAILED: $Message"}
    $script:checks++; "PASS: $Message"
}
function Pump-UI([int]$Milliseconds=100) {
    $watch=[Diagnostics.Stopwatch]::StartNew()
    while($watch.ElapsedMilliseconds -lt $Milliseconds){
        [Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{},[Windows.Threading.DispatcherPriority]::ContextIdle)
        Start-Sleep -Milliseconds 10
    }
}
try {
    Initialize-PTSProcessingOverlay
    $service=$Global:PTS_ProcessingService
    $Global:PTS_Window.Show()
    $id=Start-PTSProcessing 'Fast work'
    Stop-PTSProcessing $id
    Pump-UI 100
    Assert-Processing (-not $service.Visible -and $service.Count -eq 0) 'Fast operations finish without showing the overlay'
    $first=Start-PTSProcessing 'Long work'
    [ProcessingBusyProbe]::Hold(600) # No STA wait/message pumping: this reproduces real module work.
    Assert-Processing $service.Visible 'Overlay appears while the main UI thread is blocked'
    $angle=$service.Angle
    Start-Sleep -Milliseconds 180
    Assert-Processing ([Math]::Abs($service.Angle-$angle) -gt 2) 'Ring continues rotating on its independent dispatcher'
    $ownerHandle=[Windows.Interop.WindowInteropHelper]::new($Global:PTS_Window).Handle
    Assert-Processing ([ProcessingBusyProbe]::GetWindow($service.Handle,4) -ne $ownerHandle) 'Overlay has no cross-thread native owner'
    Assert-Processing ([ProcessingBusyProbe]::GetWindow($ownerHandle,3) -eq $service.Handle) 'Peer overlay is positioned immediately above the main window'
    Assert-Processing ([ProcessingBusyProbe]::SendMessage($service.Handle,0x21,[IntPtr]::Zero,[IntPtr]::Zero).ToInt64() -eq 3) 'Mouse activation is rejected without discarding the click'
    Assert-Processing ([ProcessingBusyProbe]::GetForegroundWindow() -ne $service.Handle) 'Showing the overlay does not take foreground focus'
    $cover=[Windows.Window]::new(); $cover.WindowStartupLocation='Manual'; $cover.Left=-20000; $cover.Top=-20000
    $cover.ShowActivated=$false; $cover.ShowInTaskbar=$false; $cover.Show()
    $coverHandle=[Windows.Interop.WindowInteropHelper]::new($cover).Handle
    [ProcessingBusyProbe]::SetWindowPos($coverHandle,[IntPtr]::Zero,-20000,-20000,200,100,0x10) | Out-Null
    Pump-UI 100
    Assert-Processing (([ProcessingBusyProbe]::Rank($coverHandle) -lt [ProcessingBusyProbe]::Rank($service.Handle)) -and
        ([ProcessingBusyProbe]::Rank($service.Handle) -lt [ProcessingBusyProbe]::Rank($ownerHandle))) 'Another window above the app remains above its overlay'
    $cover.Close()
    $Global:PTS_Window.WindowState='Minimized'; Pump-UI 100
    Assert-Processing (-not $service.Visible) 'Minimizing the app hides the peer overlay'
    $Global:PTS_Window.WindowState='Normal'; Pump-UI 150
    Assert-Processing $service.Visible 'Restoring the app restores its busy overlay'
    $second=Start-PTSProcessing 'Overlapping work'
    Stop-PTSProcessing $first; Pump-UI
    Assert-Processing ($service.Visible -and $service.Count -eq 1) 'Finishing one operation does not hide another'
    Stop-PTSProcessing $second; Pump-UI 150
    Assert-Processing (-not $service.Visible -and $service.Count -eq 0) 'Last completion hides the overlay after queued UI work'
    $button=[Windows.Controls.Button]::new(); $button.Content='Slow action'
    $Global:PTS_Window.Content=$button
    $script:observed=$false
    $button.Add_Click({ Start-Sleep -Milliseconds 400; $script:observed=$Global:PTS_ProcessingService.Visible })
    $button.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
    Assert-Processing $script:observed 'Class handling covers a synchronous button action before its instance handler'
    Pump-UI 150
    Assert-Processing ($service.Count -eq 0 -and -not $service.Visible) 'Automatic action token is cleaned up after the handler'
    # A real nested modal loop must neither be covered nor prematurely finish
    # the click token. All test windows stay outside the visible desktop.
    $modalButton=[Windows.Controls.Button]::new(); $modalButton.Content='Confirm then work'
    $Global:PTS_Window.Content=$modalButton
    $modalButton.Add_Click({
        $script:dialog=[Windows.Window]::new()
        $script:dialog.Owner=$Global:PTS_Window
        $script:dialog.WindowStartupLocation='Manual'; $script:dialog.Left=-20000; $script:dialog.Top=-20000
        $script:dialog.Width=220; $script:dialog.Height=120; $script:dialog.ShowInTaskbar=$false; $script:dialog.ShowActivated=$false
        $script:dialogTimer=[Windows.Threading.DispatcherTimer]::new()
        $script:dialogTimer.Interval=[TimeSpan]::FromMilliseconds(350)
        $script:dialogTimer.Add_Tick({ $script:covered=$Global:PTS_ProcessingService.Visible; $script:dialogTimer.Stop(); $script:dialog.Close() })
        $script:dialogTimer.Start(); $script:dialog.ShowDialog() | Out-Null
        Start-Sleep -Milliseconds 350
        $script:afterDialogVisible=$Global:PTS_ProcessingService.Visible
    })
    $modalButton.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
    Assert-Processing (-not $script:covered) 'Owned modal confirmation is not covered by the overlay'
    Assert-Processing $script:afterDialogVisible 'Processing resumes for work after a nested confirmation dialog'
    Pump-UI 150
    Assert-Processing ($service.Count -eq 0) 'Modal action releases its scope only after its final handler returns'
    $combo=[Windows.Controls.ComboBox]::new()
    $combo.Items.Add('First') | Out-Null; $combo.Items.Add('Second') | Out-Null
    $Global:PTS_Window.Content=$combo
    $combo.Add_SelectionChanged({Start-Sleep -Milliseconds 350; $script:selectionVisible=$Global:PTS_ProcessingService.Visible})
    $combo.SelectedIndex=1
    Assert-Processing $script:selectionVisible 'Selection handlers share the same automatic processing lifecycle'
    Pump-UI 100
    Assert-Processing ($service.Count -eq 0) 'Selection completion releases its automatic token'
    $id=Start-PTSProcessing 'Theme check'
    Start-Sleep -Milliseconds 350
    $Global:PTS_DarkModeEnabled=$true; $service.SetPalette((Get-PTSProcessingPalette))
    Start-Sleep -Milliseconds 80
    if($RenderDirectory){
        [IO.Directory]::CreateDirectory($RenderDirectory) | Out-Null
        $service.Capture((Join-Path $RenderDirectory 'processing-Dark.png'))
        $Global:PTS_DarkModeEnabled=$false; $service.SetPalette((Get-PTSProcessingPalette)); Start-Sleep -Milliseconds 80
        $service.Capture((Join-Path $RenderDirectory 'processing-Light.png'))
    }
    Assert-Processing (-not $service.Fault) 'Theme changes run on the overlay dispatcher without cross-thread errors'
    Stop-PTSProcessing $id; Pump-UI 100
    # Existing registration contract drives background tasks after click return.
    $tokens=$null;$errors=$null
    $ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot '..\WindowsAcolyte.ps1'),[ref]$tokens,[ref]$errors)
    foreach($name in @('Get-PTSActiveOperations','Register-PTSActiveOperation','Unregister-PTSActiveOperation')) {
        $node=$ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq "Global:$name"},$true)
        . ([scriptblock]::Create($node.Extent.Text))
    }
    $script:cancelled=0
    Register-PTSActiveOperation -ModuleId 'fixture' -ModuleName 'Fixture' -Description 'Background fixture' -Cancel {$script:cancelled++}
    Start-Sleep -Milliseconds 350
    Assert-Processing $service.Visible 'Registered background operation remains visible independently of button events'
    $service.RequestCancellation(); $service.RequestCancellation(); Pump-UI 180
    Assert-Processing ($script:cancelled -eq 1 -and $Global:PTS_ActiveOperations.fixture.CancelRequested) 'Cancellation is marshalled to the main dispatcher once'
    Unregister-PTSActiveOperation 'fixture'; Pump-UI 150
    Assert-Processing (-not $service.Visible -and $service.Count -eq 0) 'Background completion releases its overlay token'
    Register-PTSActiveOperation -ModuleId 'fixture' -ModuleName 'Fixture' -Description 'First registration'
    Register-PTSActiveOperation -ModuleId 'fixture' -ModuleName 'Fixture' -Description 'Updated registration'
    Assert-Processing ($service.Count -eq 1) 'Repeated registration of one module does not leak overlay tokens'
    Unregister-PTSActiveOperation 'fixture'; Pump-UI 100
    # Exercise the real central module loader with synthetic modules, no settings.
    $Global:PTS_CategoryDisplayNames=@{Fixture='Fixture'}
    $Global:PTS_ActiveSidebarBtn=$null
    $Global:PTS_UI=@{BackBtn=[Windows.Controls.Button]::new();ContentHost=[Windows.Controls.ContentControl]::new();ContentScroller=[Windows.Controls.ScrollViewer]::new()}
    $Global:PTS_UI.ContentScroller.Content=$Global:PTS_UI.ContentHost
    $Global:PTS_Window.Content=$Global:PTS_UI.ContentScroller
    function Set-PTSHeader { param($Eyebrow,$Title,$Subtitle) }
    $node=$ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Global:Show-PTSModuleView'},$true)
    Add-Type 'public static class ProcessingTestDialogs { public static object Show(string a,string b,System.Windows.MessageBoxButton c,System.Windows.MessageBoxImage d) { return null; } }' -ReferencedAssemblies ([Windows.Window].Assembly.Location)
    . ([scriptblock]::Create($node.Extent.Text.Replace('[System.Windows.MessageBox]','[ProcessingTestDialogs]')))
    Show-PTSModuleView ([pscustomobject]@{Id='fixture';Name='Slow Fixture';Category='Fixture';Description='Test';Show={ Start-Sleep -Milliseconds 350; $script:loaderVisible=$Global:PTS_ProcessingService.Visible; [Windows.Controls.TextBlock]::new() }})
    Assert-Processing ($script:loaderVisible -and $Global:PTS_UI.ContentHost.Content -is [Windows.Controls.TextBlock]) 'Central loader covers module setup and installs the returned view'
    Show-PTSModuleView ([pscustomobject]@{Id='viewport-fixture';Name='Viewport Fixture';Category='Fixture';Description='Test';Show={ $grid=[Windows.Controls.Grid]::new();$grid.Tag='OwnScroll';$grid }})
    Assert-Processing ($Global:PTS_UI.ContentScroller.VerticalScrollBarVisibility -eq 'Disabled') 'A module with internal scrolling receives a finite shell viewport'
    Show-PTSModuleView ([pscustomobject]@{Id='normal-fixture';Name='Normal Fixture';Category='Fixture';Description='Test';Show={ [Windows.Controls.TextBlock]::new() }})
    Assert-Processing ($Global:PTS_UI.ContentScroller.VerticalScrollBarVisibility -eq 'Auto') 'Switching to a normal module restores shell scrolling'
    Pump-UI 100
    function Write-PTSExceptionReport { param($Context,$ModuleId,$Exception,$ErrorRecord); $script:lastReport=$Context }
    function Get-PowerToolsErrorLogPath { 'isolated-test-log' }
    Show-PTSModuleView ([pscustomobject]@{Id='fixture';Name='Failed Fixture';Category='Fixture';Description='Test';Show={throw 'simulated module failure'}})
    Pump-UI 100
    Assert-Processing ($script:lastReport -eq 'ModuleView.Load' -and $service.Count -eq 0) 'Module loader failure reports its error and releases the overlay'
    $failureButton=[Windows.Controls.Button]::new(); $failureButton.Content='Failing action'
    $Global:PTS_Window.Content=$failureButton
    $failureButton.Add_Click({throw 'simulated action failure'})
    $Global:PTS_Window.Dispatcher.Add_UnhandledException({param($sender,$eventArgs) $script:actionFailureHandled=$true; $eventArgs.Handled=$true})
    $null=$Global:PTS_Window.Dispatcher.BeginInvoke([action]{$failureButton.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))})
    Pump-UI 200
    Assert-Processing ($script:actionFailureHandled -and $service.Count -eq 0) 'Unhandled action failure cannot leave a stale processing scope'
    Assert-Processing (-not $service.Fault) 'Service has no dispatcher faults'
    $Global:PTS_Window.Close()
    Assert-Processing (-not $service.Visible -and $service.Count -eq 0) 'Owner close shuts down and clears the service'
    "PASS: $script:checks Processing overlay assertions"
} finally {
    if($cover){$cover.Close()}
    if($Global:PTS_ProcessingPoll){$Global:PTS_ProcessingPoll.Stop()}
    if($Global:PTS_ProcessingService){$Global:PTS_ProcessingService.Dispose()}
    if($Global:PTS_Window){$Global:PTS_Window.Close()}
}
