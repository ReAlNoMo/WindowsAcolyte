# PowerShell 7 -STA. Native input reads are real; all writes and power plans are simulated.
param([string]$RenderPath)
$ErrorActionPreference='Stop'
$path=Join-Path $PSScriptRoot '..\modules\05-GamingOptimizer.ps1'
$tokens=$null; $errors=$null
$ast=[System.Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)
if ($errors.Count) {throw ($errors.Message -join '; ')}
foreach ($definition in $ast.FindAll({param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -like 'Global:GO-*'},$true)) {
    . ([scriptblock]::Create($definition.Extent.Text))
}
$assignment=$ast.Find({param($node) $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -eq '$script:GO_tweaks'},$true)
$next=$ast.Find({param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Global:GO-GetRiskColor'},$true)
. ([scriptblock]::Create($ast.Extent.Text.Substring($assignment.Extent.StartOffset,$next.Extent.StartOffset-$assignment.Extent.StartOffset)))
$script:GO_tweaks=@($script:GO_tweaks | Where-Object Id -in @(32,33,34,35))
$script:GO_hw=@{Build=26100;IsX3D=$false}
$script:realRead=(Get-Command GO-ReadInputState).ScriptBlock
$script:realBackupPath=(Get-Command GO-GetUsbBackupPath).ScriptBlock
$before=@{}
foreach ($id in @(32,33,35,36)) {$before[$id]=& $script:realRead $id; GO-ValidateInputState $id $before[$id]}
$beforePower=(& powercfg.exe /query) -join "`n"
$testId=[guid]::NewGuid().ToString('N')
$script:testDirectory=Join-Path ([IO.Path]::GetTempPath()) "WindowsAcolyte-InputTests-$testId"
New-Item -ItemType Directory -Path $script:testDirectory | Out-Null
$script:sid='S-1-5-21-100-200-300-1001'
function Global:GO-GetInputUserSid {$script:sid}
function Global:GO-GetUsbBackupPath {param($Id) Join-Path $script:testDirectory "optional-$Id-$script:sid.json"}
function Global:GO-WriteUsbBackup {param($Id,$Backup) $Backup | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (GO-GetUsbBackupPath $Id); GO-ReadUsbBackup $Id | Out-Null}
function Copy-State($State) { $State | ConvertTo-Json -Depth 8 | ConvertFrom-Json -AsHashtable }
function Reset-InputModel {
    $script:inputStates=@{
        32=@{Flags=127;Wait=300;Delay=500;Repeat=60;Bounce=0}
        33=@{Flags=511}
        35=@{Values=@(6,10,1)}
        36=@{Speed=7}
    }
    $script:ignoreInputWrite=$false; $script:failInputWrite=$false; $script:inputWrites=0
}
function Global:GO-ReadInputState {param($Id) Copy-State $script:inputStates[$Id]}
function Global:GO-WriteInputState {
    param($Id,$State)
    GO-ValidateInputState $Id $State
    if ($script:failInputWrite) {throw 'Simulated native API failure'}
    $script:inputWrites++
    if (-not $script:ignoreInputWrite) {$script:inputStates[$Id]=Copy-State $State}
}
function Reset-PlanModel {
    $script:planA='11111111-1111-1111-1111-111111111111'
    $script:planB='22222222-2222-2222-2222-222222222222'
    $script:plans=@{}
    $script:plans[$script:planA]=@{AC=1;DC=0}
    $script:plans[$script:planB]=@{AC=0;DC=1}
    $script:active=$script:planA; $script:failDC=$false; $script:planWrites=@(); $script:language='de'
}
function Global:GO-InvokeNative {
    param($FilePath,$Arguments)
    if ($FilePath -ne 'powercfg.exe') {throw 'Unexpected native command'}
    switch ($Arguments[0]) {
        '/getactivescheme' {return "Energieschema-GUID: $script:active (Model)"}
        '/query' {
            $guid=$Arguments[1]
            if (-not $script:plans.ContainsKey($guid)) {throw 'Power plan is missing'}
            $state=$script:plans[$guid]
            $labels=if($script:language -eq 'de'){@('Aktueller Wechselstromindex','Aktueller Gleichstromindex')}else{@('Current AC Power Setting Index','Current DC Power Setting Index')}
            return @("Power Setting GUID: $($Arguments[3])","  $($labels[0]): 0x$($state.AC.ToString('x8'))","  $($labels[1]): 0x$($state.DC.ToString('x8'))")
        }
        '/setacvalueindex' {
            if (-not $script:plans.ContainsKey($Arguments[1])) {throw 'Power plan is missing'}
            $script:plans[$Arguments[1]].AC=[int]$Arguments[4]; $script:planWrites+='AC'
        }
        '/setdcvalueindex' {
            if ($script:failDC) {throw 'Simulated DC policy failure'}
            $script:plans[$Arguments[1]].DC=[int]$Arguments[4]; $script:planWrites+='DC'
        }
        '/setactive' {
            if ($Arguments[1] -ne $script:active) {throw 'An inactive plan must not be selected'}
            $script:planWrites+='RefreshCurrent'
        }
        default {throw "Unexpected powercfg operation: $($Arguments[0])"}
    }
}
$script:assertions=0
function Assert-Input($Condition,$Message) {
    $script:assertions++
    if (-not $Condition) {throw "FAILED: $Message"}
    "PASS: $Message"
}
function Expect-InputFailure($Action,$Message) {
    $failed=$false
    try {& $Action} catch {$failed=$true}
    Assert-Input $failed $Message
}
try {
    Reset-InputModel; Reset-PlanModel
    $pathA=& $script:realBackupPath 32
    $machinePathA=& $script:realBackupPath 34
    $script:sid='S-1-5-21-100-200-300-1002'
    Assert-Input ($pathA -ne (& $script:realBackupPath 32) -and $machinePathA -eq (& $script:realBackupPath 34)) 'Production backup paths separate user preferences from machine power-plan policies'
    $script:sid='S-1-5-21-100-200-300-1001'
    Assert-Input (@($script:GO_tweaks | Where-Object {-not $_.Optional}).Count -eq 0) 'Every new input option is manual opt-in'
    foreach ($id in @(32,33,34,35)) {Assert-Input (-not (GO-IsRecommended $id)) "#$id is not auto-recommended"}
    foreach ($id in @(32,33,35)) {
        $original=GO-ReadInputState $id
        $tweak=$script:GO_tweaks | Where-Object Id -eq $id
        GO-ApplyVerifiedTweak $tweak
        Assert-Input (& $tweak.Check) "#$id applies and verifies its exact target"
        if ($id -in @(32,33)) {
            Assert-Input ($script:inputStates[$id].Flags -eq ($original.Flags -band (-bnot 5))) "#$id clears only enabled + hotkey flags"
        }
        if ($id -eq 32) {
            Assert-Input ($script:inputStates[32].Wait -eq 300 -and $script:inputStates[32].Repeat -eq 60) 'Filter Keys original timings remain intact'
        }
        if ($id -eq 35) {
            Assert-Input ($script:inputStates[35].Values[0] -eq 6 -and $script:inputStates[35].Values[1] -eq 10 -and $script:inputStates[36].Speed -eq 7) 'Disabling pointer acceleration does not change thresholds or speed'
        }
        GO-ApplyVerifiedTweak $tweak
        Assert-Input (GO-InputStatesEqual $id $original (GO-ReadUsbBackup $id).State) "#$id repeat Apply preserves the first baseline"
        GO-ResetTweak $tweak
        Assert-Input (GO-InputStatesEqual $id $original (GO-ReadInputState $id)) "#$id Reset restores original configuration"
        Expect-InputFailure {GO-ResetTweak $tweak} "#$id Reset without baseline refuses to change preferences"
    }
    GO-ApplyInputOption 36 15
    GO-ApplyInputOption 36 12
    Assert-Input ($script:inputStates[36].Speed -eq 12 -and (GO-ReadUsbBackup 36).State.Speed -eq 7) 'Explicit custom speed preserves the original across repeat Apply'
    GO-ResetInputOption 36
    Assert-Input ($script:inputStates[36].Speed -eq 7) 'Custom pointer speed Reset restores the original'
    Expect-InputFailure {GO-ApplyInputOption 36 21} 'Out-of-range pointer speed is rejected before a write'
    $script:ignoreInputWrite=$true
    Expect-InputFailure {GO-ApplyInputOption 32} 'A successful API call without matching readback is not reported as applied'
    Assert-Input ($null -ne (GO-ReadUsbBackup 32)) 'Failed readback retains original baseline'
    $script:ignoreInputWrite=$false; GO-ResetInputOption 32
    $script:failInputWrite=$true
    Expect-InputFailure {GO-ApplyInputOption 33} 'Native API failure propagates to the caller'
    Assert-Input ($null -ne (GO-ReadUsbBackup 33)) 'Native API failure retains original baseline'
    $script:failInputWrite=$false; GO-ResetInputOption 33
    GO-ApplyInputOption 32
    $backup=GO-ReadUsbBackup 32
    $backup.UserSid='S-1-5-21-100-200-300-9999'
    $backup | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (GO-GetUsbBackupPath 32)
    $tweak=$script:GO_tweaks | Where-Object Id -eq 32
    Assert-Input ((GO-GetTweakState $tweak).Status -eq 'CHECK ERROR') 'A baseline owned by another user is visibly rejected'
    Expect-InputFailure {GO-ResetInputOption 32} 'Another user baseline cannot be restored'
    $backup.UserSid=$script:sid; $backup | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (GO-GetUsbBackupPath 32)
    GO-ResetInputOption 32
    GO-ApplyInputOption 36 13
    $backup=GO-ReadUsbBackup 36; $backup.State.Speed=99
    $backup | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (GO-GetUsbBackupPath 36)
    $writesBefore=$script:inputWrites
    Expect-InputFailure {GO-ResetInputOption 36} 'Malformed pointer baseline is rejected before a native write'
    Assert-Input ($script:inputWrites -eq $writesBefore) 'Invalid baseline cannot modify a preference'
    $backup.State.Speed=7; $backup | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (GO-GetUsbBackupPath 36)
    GO-ResetInputOption 36

    foreach ($language in @('de','en')) {
        $script:language=$language
        $state=GO-GetUsbPlanState
        Assert-Input ($state.AC -eq 1 -and $state.DC -eq 0) "Power plan parser works with $language labels"
    }
    $tweak=$script:GO_tweaks | Where-Object Id -eq 34
    GO-ApplyVerifiedTweak $tweak
    GO-ApplyVerifiedTweak $tweak
    Assert-Input ((GO-ReadUsbBackup 34).Plans.Count -eq 1 -and (GO-ReadUsbBackup 34).Plans[0].AC -eq 1) 'USB policy repeat Apply retains original AC/DC baseline'
    $script:active=$script:planB
    Assert-Input (-not (& $tweak.Check)) 'Switching plans causes USB policy status to re-evaluate'
    Assert-Input ((GO-GetTweakState $tweak).Message -like '*AC=0, DC=1*') 'Current plan AC and DC values are visible separately'
    GO-ApplyVerifiedTweak $tweak
    Assert-Input ((GO-ReadUsbBackup 34).Plans.Count -eq 2) 'Second power plan has an independent saved baseline'
    GO-ResetTweak $tweak
    Assert-Input ($script:plans[$script:planA].AC -eq 1 -and $script:plans[$script:planA].DC -eq 0 -and $script:plans[$script:planB].AC -eq 0 -and $script:plans[$script:planB].DC -eq 1) 'Reset restores independent AC/DC values on all saved plans'
    Assert-Input ($script:active -eq $script:planB) 'Reset does not switch to an inactive saved plan'
    $script:failDC=$true
    Expect-InputFailure {GO-ApplyVerifiedTweak $tweak} 'Partial AC/DC write failure is reported'
    Assert-Input ((GO-ReadUsbBackup 34).Plans[0].DC -eq 1) 'Partial write failure preserves original DC policy'
    $script:failDC=$false; GO-ResetTweak $tweak
    GO-ApplyVerifiedTweak $tweak
    $script:plans.Remove($script:planB)
    Expect-InputFailure {GO-ResetTweak $tweak} 'Missing power plan blocks complete baseline archival'
    Assert-Input ($null -ne (GO-ReadUsbBackup 34)) 'Missing plan retains recovery baseline'
    $script:plans[$script:planB]=@{AC=0;DC=0}; GO-ResetTweak $tweak
    Assert-Input ($script:plans[$script:planB].DC -eq 1) 'Returned power plan can be restored on retry'
    $script:plans[$script:planB].DC=2
    Assert-Input ((GO-GetTweakState $tweak).Status -eq 'CHECK ERROR') 'Unsupported USB policy values are not silently treated as missing'
    $script:plans[$script:planB].DC=1

    Add-Type -AssemblyName PresentationFramework
    $script:window=[System.Windows.Window]::new()
    $script:window.Resources.Add('SecondaryButton',[System.Windows.Style]::new([System.Windows.Controls.Button]))
    function Global:Get-PowerToolsWindow {$script:window}
    function Global:Get-PowerToolsBrush {param($Name) [System.Windows.Media.Brushes]::Gray}
    function Global:GO-AddLog {param($Msg,$Type) $script:lastLog=$Msg}
    $script:GO_tweakList=[System.Windows.Controls.ItemsControl]::new()
    $script:GO_checkboxes=@{}; $script:GO_applyBtn=[System.Windows.Controls.Button]::new()
    $script:GO_estimate=[System.Windows.Controls.TextBlock]::new(); $script:GO_impactText=[System.Windows.Controls.TextBlock]::new()
    GO-RenderList
    Assert-Input (-not $script:GO_speedReset.IsEnabled) 'Speed Reset is disabled when no original baseline exists'
    foreach ($mode in @('All','Missing','Safe','Recommended')) {
        GO-SelectTweaks $mode
        Assert-Input (@($script:GO_checkboxes.Values | Where-Object IsChecked).Count -eq 0) "Bulk $mode leaves all input options unselected"
    }
    $writesBefore=$script:inputWrites
    $script:GO_speedSlider.Value=16
    Assert-Input ($script:inputWrites -eq $writesBefore -and $script:GO_speedApply.IsEnabled) 'Moving the speed slider only selects a target, without a Windows write'
    $script:GO_speedApply.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
    Assert-Input ($script:inputStates[36].Speed -eq 16 -and $script:GO_speedReset.IsEnabled) 'Explicit speed button applies and exposes Reset'
    GO-ResetInputOption 36
    GO-ApplyVerifiedTweak ($script:GO_tweaks | Where-Object Id -eq 32)
    GO-RenderList
    Assert-Input ($script:GO_states[32].Applied -and -not $script:GO_checkboxes[32].IsEnabled) 'WPF recognizes verified Filter Keys configuration'
    GO-ResetInputOption 32
    function Global:GO-GetLocalUpdateStatus {'Local test history only; availability UNKNOWN; no online scan.'}
    $script:opened=''
    function Global:Start-Process {param($FilePath,$EA) if($FilePath -ne 'ms-settings:windowsupdate'){throw 'Unexpected process launch'}; $script:opened=$FilePath}
    $script:GO_updateRefresh.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
    Assert-Input ($script:GO_updateText.Text -like '*UNKNOWN*') 'Update card does not claim the machine is up to date'
    $script:GO_updateOpen.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
    Assert-Input ($script:opened -eq 'ms-settings:windowsupdate') 'Update button only opens the Settings page'
    function Global:GO-GetLocalUpdateStatus {throw 'Simulated unavailable Windows Update agent'}
    $script:GO_updateRefresh.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
    Assert-Input ($script:GO_updateText.Text -like '*unavailable*UNKNOWN*') 'Unavailable local update history remains visibly unknown'
    Assert-Input ($ast.Extent.Text -notmatch 'MouseDataQueueSize|KeyboardDataQueueSize|useplatformclock|disabledynamictick') 'No unproven queue or boot-timer tweaks were introduced'
    if ($RenderPath) {
        GO-RenderList
        $script:GO_tweakList.Width=900
        $script:GO_tweakList.Background=[System.Windows.Media.Brushes]::White
        $script:GO_tweakList.Measure([System.Windows.Size]::new(900,[double]::PositiveInfinity))
        $height=[math]::Ceiling($script:GO_tweakList.DesiredSize.Height)
        $script:GO_tweakList.Arrange([System.Windows.Rect]::new(0,0,900,$height))
        $script:GO_tweakList.UpdateLayout()
        $bitmap=[System.Windows.Media.Imaging.RenderTargetBitmap]::new(900,$height,96,96,[System.Windows.Media.PixelFormats]::Pbgra32)
        $bitmap.Render($script:GO_tweakList)
        $encoder=[System.Windows.Media.Imaging.PngBitmapEncoder]::new()
        $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
        $stream=[IO.File]::Create($RenderPath)
        try {$encoder.Save($stream)} finally {$stream.Dispose()}
        "Rendered WPF controls: $RenderPath"
    }
    "PASS: $script:assertions input/stability assertions; all preference and power-plan writes simulated."
} finally {
    $resolved=[IO.Path]::GetFullPath($script:testDirectory)
    if ($resolved -ne (Join-Path ([IO.Path]::GetTempPath()) "WindowsAcolyte-InputTests-$testId")) {throw 'Unsafe test cleanup target'}
    Remove-Item -LiteralPath $resolved -Recurse -Force
    foreach ($id in @(32,33,35,36)) {
        if (-not (GO-InputStatesEqual $id $before[$id] (& $script:realRead $id))) {throw "Actual input preference $id changed"}
    }
    $afterPower=(& powercfg.exe /query) -join "`n"
    if ($beforePower -ne $afterPower) {throw 'Actual power plan changed'}
}
