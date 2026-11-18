# PowerShell 7 -STA on Windows. Only unique HKCU fixtures and temporary files are written.
param([string]$RenderDirectory)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework
$modulePath = Join-Path $PSScriptRoot '..\modules\02-ExplorerViewNormalizer.ps1'
function Register-PowerToolsModule { param($Id,$Name,$Description,$Category,$Show); $script:show=$Show }
. $modulePath
$id = [guid]::NewGuid().ToString('N')
$subKey = "Software\WindowsAcolyte-Tests\$id"
$testRoot = "HKCU:\$subKey"
$temp = Join-Path ([IO.Path]::GetTempPath()) "WindowsAcolyte-ExplorerTests-$id"
$scopes = [ordered]@{}
foreach ($name in (Get-EVNPaths).Scopes.Keys) { $scopes[$name]="$subKey\$name" }
# Embed fixture paths so the background worker receives the same safe configuration.
$scopeCode = ($scopes.GetEnumerator() | ForEach-Object { "'$($_.Key)'='$($_.Value)'" }) -join ';'
. ([scriptblock]::Create("function Global:Get-EVNPaths { [pscustomobject]@{ MachineTypes='$testRoot\MachineTypes';UserTypes='$testRoot\FolderTypes';BackupDirectory='$temp';Scopes=[ordered]@{$scopeCode} } }"))
$script:assertions = 0
function Assert-View($Condition, $Message) {
    if (-not $Condition) { throw "FAILED: $Message" }
    $script:assertions++
    "PASS: $Message"
}
function Set-FixtureValue($Path,$Name,$Value,$Kind='String') {
    if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -Force | Out-Null }
    $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($Path.Substring(6))
    try { $key.SetValue($Name, $Value, [Microsoft.Win32.RegistryValueKind]$Kind) } finally { $key.Dispose() }
}
function Get-SnapshotText {
    $file = Save-EVNViewBackup
    $json = Get-Content -LiteralPath $file -Raw | ConvertFrom-Json
    ConvertTo-Json -InputObject $json.Scopes -Depth 12 -Compress
}
function Wait-ViewWork {
    $watch = [Diagnostics.Stopwatch]::StartNew()
    while ($script:EVN_job -and $watch.Elapsed.TotalSeconds -lt 30) {
        [Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{}, [Windows.Threading.DispatcherPriority]::Background)
        Start-Sleep -Milliseconds 25
    }
    if ($script:EVN_job) { throw 'View worker timed out.' }
}
try {
    $types = @(
        @('Generic','{5C4F28B5-F869-4E84-8E60-F11DB97C5CC7}'),
        @('Documents','{7D49D726-3C21-4F05-99AA-FDC2C9474656}'),
        @('Pictures','{B3690E58-E961-423B-B687-386EBFD83239}'),
        @('Downloads','{885A186E-A440-4ADA-812B-DB871B942259}'),
        @('Future.Custom','{11111111-2222-3333-4444-555555555555}')
    )
    foreach ($type in $types) {
        $p = "$testRoot\MachineTypes\$($type[1])"
        Set-FixtureValue $p CanonicalName $type[0]
        Set-FixtureValue "$p\TopViews\{00000000-0000-0000-0000-000000000000}" GroupBy 'System.DateModified'
        Set-FixtureValue "$p\TopViews\{00000000-0000-0000-0000-000000000000}" ColumnList 'keep-machine-columns'
    }
    Set-FixtureValue "$testRoot\MachineTypes\{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}" CanonicalName 'NonEditableType'
    Set-FixtureValue "$testRoot\MachineTypes\$($types[0][1])" '' 'default-value'
    $generic = $types[0][1]
    $saved = "$testRoot\Bags\42\Shell\$generic"
    $dialog = "$testRoot\Bags\42\ComDlg\$generic"
    $legacyDialog = "$testRoot\LegacyBags\8\ComDlgLegacy\$generic"
    foreach ($p in @($saved,$dialog,$legacyDialog)) {
        Set-FixtureValue $p GroupView -1 DWord
        Set-FixtureValue $p 'GroupByKey:PID' 14 DWord
        Set-FixtureValue $p 'GroupByKey:FMTID' '{B725F130-47EF-101A-A5F1-02608C9EEBAC}'
        Set-FixtureValue $p ColInfo ([byte[]]@(0,3,255)) Binary
    }
    $userView = "$testRoot\FolderTypes\$generic\TopViews\{00000000-0000-0000-0000-000000000000}"
    Set-FixtureValue $userView ColumnList 'keep-user-columns'
    Set-FixtureValue "$testRoot\DefaultStreams" Legacy ([byte[]]@(1,2)) Binary
    $roundtrip = "$testRoot\Bags\Typed"
    foreach ($v in @(
        @('', '', 'String'), @('Expand','%SystemRoot%\literal','ExpandString'),
        @('Multi',[string[]]@('one','two'),'MultiString'), @('EmptyMulti',[string[]]@(),'MultiString'),
        @('Bytes',[byte[]]@(0,255),'Binary'), @('Empty',[byte[]]@(),'Binary'),
        @('Signed',-1,'DWord'), @('Large',[long]::MaxValue,'QWord'), @('None',[byte[]]@(4,5),'None')
    )) { Set-FixtureValue $roundtrip $v[0] $v[1] $v[2] }
    $machineBefore = Get-ItemProperty "$testRoot\MachineTypes\$generic\TopViews\{00000000-0000-0000-0000-000000000000}"
    $state = Get-EVNGroupingState
    Assert-View (-not $state.Configured -and $state.MissingTemplates -eq 4 -and $state.Conflicts -ge 3) 'Missing user defaults and grouped saved Shell/ComDlg/legacy views detected'
    $baseline = Get-SnapshotText
    $backup = Save-EVNViewBackup
    Set-EVNNoGrouping
    $state = Get-EVNGroupingState
    Assert-View ($state.Configured -and $state.Conflicts -eq 0 -and $state.MissingTemplates -eq 0) 'All discovered types, including an unknown future type, normalized'
    Assert-View ((Get-ItemProperty $userView).ColumnList -eq 'keep-user-columns') 'Existing user template columns preserved'
    Assert-View ((Test-Path "$testRoot\FolderTypes\{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}") -and
        (Get-Item "$testRoot\FolderTypes\$generic").GetValue('') -eq 'default-value') 'Complete type catalog and unnamed default values copied'
    Assert-View ((Get-ItemProperty $saved).ColInfo[2] -eq 255) 'Saved per-folder columns preserved'
    Assert-View ((Get-ItemProperty $dialog).GroupView -eq 0 -and (Get-ItemProperty $legacyDialog).'GroupByKey:PID' -eq 0) 'Modern and legacy file-dialog grouping repaired'
    Assert-View (-not (Test-Path "$testRoot\DefaultStreams")) 'Conflicting legacy binary template defaults cleared'
    Assert-View ((Get-ItemProperty "$testRoot\MachineTypes\$generic\TopViews\{00000000-0000-0000-0000-000000000000}").GroupBy -eq $machineBefore.GroupBy) 'Machine template fixture unchanged'
    $normalized = Get-SnapshotText
    Set-EVNNoGrouping
    Assert-View ((Get-SnapshotText) -ceq $normalized) 'Repeated normalization is idempotent and preserves unrelated values'
    Set-FixtureValue $saved 'GroupByKey:PID' 14 DWord
    Assert-View (-not (Get-EVNGroupingState).Configured) 'New saved-view conflict defeats positive status'
    $rescue = Restore-EVNViewBackup $backup
    Assert-View (Test-Path -LiteralPath $rescue) 'Restore first saves the current state as a rescue snapshot'
    Assert-View ((Get-SnapshotText) -ceq $baseline) 'Restore round-trips all value types, absent keys, and original grouping'
    $bad = Get-Content $backup -Raw | ConvertFrom-Json
    $bad.Scopes[0].Id = 'ArbitraryRoot'
    $badFile = Join-Path $temp 'invalid.json'
    $bad | ConvertTo-Json -Depth 12 | Set-Content $badFile
    $blocked=$false
    try { Restore-EVNViewBackup $badFile | Out-Null } catch { $blocked=$true }
    Assert-View ($blocked -and (Get-SnapshotText) -ceq $baseline) 'Invalid backup rejected before mutation'
    $bad = Get-Content $backup -Raw | ConvertFrom-Json
    $bad.Scopes[0].Nodes[0].Path = '..\Outside'
    $bad | ConvertTo-Json -Depth 12 | Set-Content $badFile
    $blocked=$false
    try { Restore-EVNViewBackup $badFile | Out-Null } catch { $blocked=$true }
    Assert-View ($blocked -and (Get-SnapshotText) -ceq $baseline) 'Invalid relative path rejected before mutation'

    # Load real theme palettes, styles and shell XAML without starting the application.
    $tokens=$null; $parseErrors=$null
    $appAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot '..\WindowsAcolyte.ps1'),[ref]$tokens,[ref]$parseErrors)
    foreach ($name in @('PTS_Theme','PTS_ThemeDark')) {
        $node=$appAst.Find({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq ('$Global:'+$name)},$true)
        . ([scriptblock]::Create($node.Extent.Text))
    }
    foreach ($name in @('New-PTSBrush','Update-PTSStyles')) {
        $node=$appAst.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq "Global:$name"},$true)
        . ([scriptblock]::Create($node.Extent.Text))
    }
    $node=$appAst.Find({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -match '\$xaml$'},$true)
    . ([scriptblock]::Create($node.Extent.Text))
    $script:hostWindow = [Windows.Markup.XamlReader]::Load([Xml.XmlNodeReader]::new($xaml))
    $Global:PTS_Window=$script:hostWindow
    function Get-PowerToolsWindow { $script:hostWindow }
    $Global:PTS_Brush = @{}
    foreach ($name in $Global:PTS_Theme.Keys) { $Global:PTS_Brush[$name]=New-PTSBrush $Global:PTS_Theme[$name] }
    Update-PTSStyles
    function Register-PTSActiveOperation { param($ModuleId,$ModuleName,$Description); $script:active=$true }
    function Unregister-PTSActiveOperation { param($ModuleId); $script:active=$false }
    $view = & $script:show
    $script:hostWindow.Content=$view
    Assert-View ($null -ne $view.FindName('RestoreViewsBtn') -and $script:EVN_restore.IsEnabled) 'WPF view builds with restore action and backup availability'
    Assert-View ($script:EVN_optionControls['clear_saved_views'].Content -match '\[ACTION\]') 'Reset is shown as a one-time action'
    foreach ($cb in $script:EVN_optionControls.Values) { $cb.IsChecked=$false }
    $script:EVN_apply.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
    Assert-View (-not $script:EVN_job -and (Get-SnapshotText) -ceq $baseline) 'Empty selection makes no changes and does not revert settings'
    # Exercise the real background worker with fixture paths; do not restart Explorer.
    EVN-StartWork -Selected @('disable_grouping')
    Assert-View ($script:active -and -not $script:EVN_apply.IsEnabled) 'Busy worker disables controls and registers the navigation guard'
    Wait-ViewWork
    Assert-View ((Get-EVNGroupingState).Configured -and -not $script:active -and $script:EVN_apply.IsEnabled) 'Background apply completes, rechecks status and releases controls'
    Assert-View ($script:EVN_logBox.Text -notmatch '\[FAIL\]') 'Worker reports no errors'
    EVN-StartWork -RestoreFile $backup
    Wait-ViewWork
    Assert-View ((Get-SnapshotText) -ceq $baseline -and $script:EVN_logBox.Text -notmatch '\[FAIL\]') 'Background restore returns to original views and updates status'
    EVN-StartWork -Selected @('clear_saved_views','disable_grouping')
    Wait-ViewWork
    Assert-View ((Get-EVNGroupingState).Configured -and -not (Test-Path -LiteralPath $saved)) 'Explicit reset runs before grouping repair and removes saved layouts only when selected'
    # Prove backup failure prevents all subsequent registry writes.
    $script:EVN_options['disable_grouping'].Apply = { throw 'UNEXPECTED action reached' }
    $backupDefinition = (Get-Command Save-EVNViewBackup).Definition
    function Global:Save-EVNViewBackup { throw 'simulated backup failure' }
    $beforeFailure = Get-EVNGroupingState | ConvertTo-Json -Compress
    EVN-StartWork -Selected @('disable_grouping')
    Wait-ViewWork
    Assert-View ($script:EVN_logBox.Text -match 'simulated backup failure' -and $script:EVN_logBox.Text -notmatch 'UNEXPECTED action reached' -and (Get-EVNGroupingState | ConvertTo-Json -Compress) -ceq $beforeFailure) 'Backup failure aborts the worker before mutation'
    . ([scriptblock]::Create("function Global:Save-EVNViewBackup { $backupDefinition }"))
    foreach ($themeName in @('Light','Dark')) {
        $palette=if($themeName -eq 'Dark'){$Global:PTS_ThemeDark}else{$Global:PTS_Theme}
        foreach ($name in $palette.Keys) {
            if ($Global:PTS_Brush[$name].IsFrozen) { $Global:PTS_Brush[$name]=New-PTSBrush $palette[$name] }
            else { $Global:PTS_Brush[$name].Color=[Windows.Media.ColorConverter]::ConvertFromString($palette[$name]) }
        }
        Update-PTSStyles
        $view.Measure([Windows.Size]::new(1100,1000)); $view.Arrange([Windows.Rect]::new(0,0,1100,1000)); $view.UpdateLayout()
        Assert-View ($script:EVN_infoText.Foreground.Color -eq $Global:PTS_Brush.TextMid.Color -and
            $script:EVN_restore.ActualHeight -gt 0) "$themeName theme updates the existing view and displays the restore button"
        if ($RenderDirectory) {
            [IO.Directory]::CreateDirectory($RenderDirectory) | Out-Null
            $bitmap = [Windows.Media.Imaging.RenderTargetBitmap]::new(1100,1000,96,96,[Windows.Media.PixelFormats]::Pbgra32)
            $bitmap.Render($view)
            $encoder=[Windows.Media.Imaging.PngBitmapEncoder]::new(); $encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
            $stream=[IO.File]::Create((Join-Path $RenderDirectory "explorer-view-normalizer-$themeName.png"))
            try { $encoder.Save($stream) } finally { $stream.Dispose() }
        }
    }
    "PASS: $script:assertions Explorer View Normalizer assertions"
} finally {
    if ($script:EVN_job) { $script:EVN_job.Worker.Stop(); $script:EVN_job.Worker.Dispose() }
    if ($script:EVN_workTimer) { $script:EVN_workTimer.Stop() }
    # Unique, verified test roots only. Never remove real Explorer keys.
    if ($testRoot -match '^HKCU:\\Software\\WindowsAcolyte-Tests\\[0-9a-f]{32}$') { Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue }
    if (([IO.Path]::GetFullPath($temp)) -eq (Join-Path ([IO.Path]::GetTempPath()) "WindowsAcolyte-ExplorerTests-$id")) { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }
}
