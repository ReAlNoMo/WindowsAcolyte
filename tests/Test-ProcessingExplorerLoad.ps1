# Read-only real Explorer module build in real shell XAML. No Apply or registry writes.
# Run separately with -Modal to cover the application's ShowDialog startup.
param([switch]$Modal)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework
Add-Type @'
public static class ExplorerLoadProbe {
    public static void Hold(int milliseconds) {
        var clock=System.Diagnostics.Stopwatch.StartNew();
        while(clock.ElapsedMilliseconds<milliseconds) System.Threading.Thread.SpinWait(1000);
    }
}
'@
$repo=Split-Path $PSScriptRoot -Parent
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'WindowsAcolyte.ps1'),[ref]$tokens,[ref]$errors)
if($errors.Count){throw ($errors.Message -join '; ')}
foreach($name in @('PTS_Theme','PTS_ThemeDark','PTS_CategoryDisplayNames')){
    $node=$ast.Find({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq ('$Global:'+$name)},$true)
    . ([scriptblock]::Create($node.Extent.Text))
}
foreach($name in @('New-PTSBrush','Update-PTSStyles','Set-PTSHeader','Set-PTSFooterStatus','Show-PTSModuleView')){
    $node=$ast.Find({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq "Global:$name"},$true)
    . ([scriptblock]::Create($node.Extent.Text))
}
$node=$ast.Find({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -match '\$xaml$'},$true)
. ([scriptblock]::Create($node.Extent.Text))
$Global:PTS_Window=[Windows.Markup.XamlReader]::Load([Xml.XmlNodeReader]::new($xaml))
$Global:PTS_Window.WindowState='Normal';$Global:PTS_Window.WindowStartupLocation='Manual'
$Global:PTS_Window.Left=-20000;$Global:PTS_Window.Top=-20000
$Global:PTS_Window.ShowActivated=$false;$Global:PTS_Window.ShowInTaskbar=$false
$Global:PTS_UI=@{}
foreach($name in @('ContentHost','ContentScroller','HeaderEyebrow','HeaderTitle','HeaderSubtitle','FooterStatus','BackBtn')){$Global:PTS_UI[$name]=$Global:PTS_Window.FindName($name)}
$Global:PTS_Brush=@{}
foreach($key in $Global:PTS_Theme.Keys){$Global:PTS_Brush[$key]=New-PTSBrush $Global:PTS_Theme[$key]}
Update-PTSStyles
$Global:PTS_DarkModeEnabled=$false;$Global:PTS_ActiveOperations=@{}
function Global:Get-PowerToolsWindow {$Global:PTS_Window}
function Global:Register-PowerToolsModule {
    param($Id,$Name,$Description,$Category,$Show)
    $script:module=[pscustomobject]@{Id=$Id;Name=$Name;Description=$Description;Category=$Category;Show=$Show}
}
function Global:Write-PTSExceptionReport {param($Context,$Exception,$ErrorRecord,$ModuleId) throw "Unexpected $Context $Exception $ErrorRecord"}
function Global:Get-PowerToolsErrorLogPath {'isolated-test-log'}
. (Join-Path $repo 'modules\00-ProcessingOverlay.ps1')
. (Join-Path $repo 'modules\02-ExplorerViewNormalizer.ps1')
$script:realShow=$script:module.Show
# Guarantee the slow path even on machines with a tiny view cache. Unlike
# Start-Sleep, this does not pump the STA's incoming synchronous window messages.
$script:module.Show={ [ExplorerLoadProbe]::Hold(350); & $script:realShow }
Initialize-PTSProcessingOverlay
$script:result=$null;$script:failure=$null
$Global:PTS_Window.Dispatcher.Add_UnhandledException({param($sender,$e) $script:failure=$e.Exception.ToString();$e.Handled=$true;$Global:PTS_Window.Close()})
$script:timer=[Windows.Threading.DispatcherTimer]::new()
$script:timer.Interval=[TimeSpan]::FromMilliseconds(250)
$script:timer.Add_Tick({
    $script:timer.Stop()
    $watch=[Diagnostics.Stopwatch]::StartNew()
    Show-PTSModuleView -Module $script:module
    $script:result=@{DurationMs=$watch.ElapsedMilliseconds;Visible=$Global:PTS_ProcessingService.Visible;
        Active=$Global:PTS_ProcessingService.Count;Fault=$Global:PTS_ProcessingService.Fault;
        ViewReady=($null -ne $Global:PTS_UI.ContentHost.Content.FindName('ApplyBtn'))}
    $Global:PTS_Window.Close()
})
$script:timer.Start()
try{
    if($Modal){$Global:PTS_Window.ShowDialog() | Out-Null}
    else{
        $Global:PTS_Window.Show()
        $frame=[Windows.Threading.DispatcherFrame]::new()
        $Global:PTS_Window.Add_Closed({$frame.Continue=$false})
        [Windows.Threading.Dispatcher]::PushFrame($frame)
    }
    if($script:failure){throw $script:failure}
    if(-not $script:result -or -not $script:result.Visible -or -not $script:result.ViewReady -or
        $script:result.Active -lt 1 -or $script:result.Fault){throw 'Real Explorer module load failed to display Processing... during the synchronous build.'}
    "PASS: Real Explorer module load, Modal=$Modal, $($script:result.DurationMs) ms, overlay visible, view ready, no faults"
}finally{
    $script:timer.Stop()
    if($Global:PTS_ProcessingPoll){$Global:PTS_ProcessingPoll.Stop()}
    if($Global:PTS_ProcessingService){$Global:PTS_ProcessingService.Dispose()}
    $Global:PTS_Window.Close()
}
