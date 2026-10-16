# Run with PowerShell 7 -STA on Windows. Registry writes stay in a unique HKCU test key.
$ErrorActionPreference = 'Stop'
$modulePath = Join-Path $PSScriptRoot '..\modules\05-GamingOptimizer.ps1'
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($modulePath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }

foreach ($name in @('GO-GetReg', 'GO-SetDW', 'GO-TestDWord', 'GO-ApplyVerifiedTweak', 'GO-IsRecommended',
    'GO-RenderList', 'GO-ApplyRecommendedPreselection', 'GO-HandleMutex', 'GO-UpdateApplyState',
    'GO-GetRiskColor', 'GO-GetRiskLabel', 'GO-GetTweakState', 'GO-GetStateSnapshot', 'GO-SelectTweaks',
    'GO-GetProfileSelection', 'GO-ApplyProfileSelection')) {
    $definition = $ast.Find({ param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq "Global:$name"
    }, $true)
    if (-not $definition) { throw "Missing function: $name" }
    . ([scriptblock]::Create($definition.Extent.Text))
}
$tweakAssignment = $ast.Find({ param($node)
    $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
    $node.Left.Extent.Text -eq '$script:GO_tweaks'
}, $true)
if (-not $tweakAssignment) { throw 'Missing tweak definitions' }
. ([scriptblock]::Create($tweakAssignment.Extent.Text))

function Assert-Result($Condition, $Message) {
    if (-not $Condition) { throw $Message }
    Write-Output "PASS: $Message"
}

$script:testRegistryPath = 'HKCU:\Software\WindowsAcolyte-Tests-' + [guid]::NewGuid().ToString('N')
$script:readRegistry = (Get-Command GO-GetReg).ScriptBlock
$script:writeDWord = (Get-Command GO-SetDW).ScriptBlock
# Redirect only the registry IO; execute the actual production Apply/Check blocks.
function Global:GO-GetReg {
    param($p, $n)
    if ($script:useSignedValue) { return -1 }
    & $script:readRegistry $script:testRegistryPath $n
}
function Global:GO-SetDW {
    param($p, $n, $v)
    & $script:writeDWord $script:testRegistryPath $n $v
}

try {
    $network = $script:GO_tweaks | Where-Object Id -eq 8
    $competitive = $script:GO_tweaks | Where-Object Id -eq 9
    $aaa = $script:GO_tweaks | Where-Object Id -eq 10

    Assert-Result (-not (& $network.Check)) 'Missing network value is not reported as applied'
    GO-ApplyVerifiedTweak $network
    $persisted = Get-ItemPropertyValue $script:testRegistryPath NetworkThrottlingIndex
    Assert-Result ($persisted -eq [uint32]::MaxValue) 'Network disable value persists as DWORD 0xFFFFFFFF'
    . ([scriptblock]::Create($tweakAssignment.Extent.Text))
    $network = $script:GO_tweaks | Where-Object Id -eq 8
    Assert-Result (& $network.Check) 'Recreated module definitions recognize persisted network setting'
    $script:useSignedValue = $true
    Assert-Result (& $network.Check) 'Signed DWORD representation -1 is also recognized'
    $script:useSignedValue = $false

    GO-ApplyVerifiedTweak $aaa
    Assert-Result ((& $aaa.Check) -and -not (& $competitive.Check)) 'AAA and Competitive are exclusive'
    Assert-Result (-not (GO-IsRecommended 9)) 'Reopening does not preselect Competitive over active AAA'
    GO-ApplyVerifiedTweak $competitive
    Assert-Result ((& $competitive.Check) -and -not (& $aaa.Check)) 'Explicit Competitive selection replaces AAA'
    Assert-Result (-not (GO-IsRecommended 10)) 'Reopening does not preselect AAA over active Competitive'
    & $script:writeDWord $script:testRegistryPath Win32PrioritySeparation 0x26
    Assert-Result ((GO-IsRecommended 9) -and -not (GO-IsRecommended 10)) 'Default state recommends only one priority preset'

    $rejected = $false
    try { GO-ApplyVerifiedTweak @{ Label='No-op'; Apply={}; Check={ $false } } }
    catch { $rejected = $true }
    Assert-Result $rejected 'A write without matching readback is not reported as successful'
    $rejected = $false
    try { GO-ApplyVerifiedTweak @{ Label='Write failure'; Apply={ Write-Error 'Simulated write failure' }; Check={ $true } } }
    catch { $rejected = $true }
    Assert-Result $rejected 'Nonterminating write errors become failed operations'
    $rejected = $false
    try { & $script:writeDWord 'MissingGamingTestDrive:\Invalid' Value 1 }
    catch { $rejected = $true }
    Assert-Result $rejected 'Registry helper propagates creation/write errors'

    # Exercise the real WPF render/preselection path without opening a window.
    Add-Type -AssemblyName PresentationFramework
    $script:testWindow = [System.Windows.Window]::new()
    $script:testWindow.Resources.Add('SecondaryButton', [System.Windows.Style]::new([System.Windows.Controls.Button]))
    function Global:Get-PowerToolsWindow { return $script:testWindow }
    function Global:Get-PowerToolsBrush { param($Name) return [System.Windows.Media.Brushes]::Gray }
    $script:GO_tweaks = @($network, $competitive, $aaa)
    $script:GO_tweakList = [System.Windows.Controls.ItemsControl]::new()
    $script:GO_checkboxes = @{}
    $script:GO_applyBtn = [System.Windows.Controls.Button]::new()
    $script:GO_estimate = [System.Windows.Controls.TextBlock]::new()
    $script:GO_impactText = [System.Windows.Controls.TextBlock]::new()
    GO-ApplyVerifiedTweak $aaa
    GO-RenderList
    GO-ApplyRecommendedPreselection
    $status = $script:GO_checkboxes[9].Parent.Children | Where-Object {
        $_ -is [System.Windows.Controls.TextBlock] -and [System.Windows.Controls.Grid]::GetColumn($_) -eq 1
    }
    Assert-Result ($status.Text -eq 'ALTERNATIVE') 'WPF marks inactive priority preset as ALTERNATIVE'
    Assert-Result (-not $script:GO_checkboxes[8].IsEnabled) 'WPF recognizes network setting as already applied'
    Assert-Result (-not $script:GO_checkboxes[10].IsEnabled) 'WPF recognizes active AAA preset'
    Assert-Result (-not $script:GO_checkboxes[9].IsChecked) 'WPF preselection preserves current priority mode'
    $script:GO_checkboxes[9].IsChecked = $true
    GO-ApplyVerifiedTweak $competitive
    GO-RenderList
    GO-ApplyRecommendedPreselection
    Assert-Result (-not $script:GO_checkboxes[9].IsEnabled) 'WPF reload recognizes explicitly applied Competitive preset'
    Assert-Result (-not $script:GO_checkboxes[10].IsChecked) 'WPF reload does not select opposing AAA preset'
    foreach ($mode in @('All','Missing','Safe','Recommended')) {
        GO-SelectTweaks $mode
        Assert-Result (-not $script:GO_checkboxes[10].IsChecked) "WPF bulk selection $mode preserves active Competitive preset"
    }
    $competitive.Note = 'Replaces AAA mode (#10). Reset selects 38 (0x26).'
    $aaa.Note = 'Replaces Competitive mode (#9). Reset selects 38 (0x26).'
    GO-RenderList
    $script:GO_checkboxes[10].IsChecked = $true
    GO-UpdateApplyState
    Assert-Result ($script:GO_impactText.Text -like '*Replaces Competitive*') 'Selection impact is visible before applying'
    Assert-Result ($script:GO_checkboxes[10].Content.Children.Count -eq 2) 'Conflict note appears directly below the priority option'
    $profileIds = @(GO-GetProfileSelection)
    Assert-Result (8 -in $profileIds -and 10 -in $profileIds -and 9 -notin $profileIds) 'Profile save includes applied settings and pending priority replacement without conflict'
    GO-SelectTweaks None
    $script:GO_cbRestore = [System.Windows.Controls.CheckBox]::new()
    $script:GO_cbRegBkp = [System.Windows.Controls.CheckBox]::new()
    $script:GO_cbAutoReb = [System.Windows.Controls.CheckBox]::new()
    $profile = '{"SelectedTweakIds":[8,10],"Settings":{"CreateRestorePoint":false,"ExportRegistry":true,"PromptReboot":false}}' | ConvertFrom-Json
    Assert-Result ($profile.SelectedTweakIds[0] -is [long]) 'Profile fixture reproduces JSON Int64 IDs'
    $loaded = GO-ApplyProfileSelection $profile
    Assert-Result ($loaded.Loaded -eq 1 -and $loaded.Skipped -eq 1 -and $script:GO_checkboxes[10].IsChecked) 'Profile load normalizes Int64 IDs and selects the desired alternative'
    Assert-Result ($script:GO_cbRegBkp.IsChecked -and -not $script:GO_cbAutoReb.IsChecked) 'Profile restores Boolean backup/reboot preferences'
    foreach ($invalid in @('{"SelectedTweakIds":[9,10]}','{"SelectedTweakIds":[999]}','{"SelectedTweakIds":[10],"Settings":{"PromptReboot":"false"}}')) {
        $rejected = $false
        try { GO-ApplyProfileSelection ($invalid | ConvertFrom-Json) | Out-Null } catch { $rejected = $true }
        Assert-Result ($rejected -and $script:GO_checkboxes[10].IsChecked) 'Invalid/conflicting profile rejected before altering UI selection'
    }
    $unavailable = @{Id=30;Group='Test';Label='Unavailable';Risk=0;Available={$false};UnavailableReason='No compatible adapter';Check={throw 'Must not run'}}
    $badCheck = @{Id=31;Group='Test';Label='Bad check';Risk=0;Check={throw 'Access denied'}}
    $script:GO_tweaks = @($unavailable,$badCheck)
    GO-RenderList
    Assert-Result (-not $script:GO_checkboxes[30].IsEnabled -and $script:GO_states[30].Status -eq 'UNAVAILABLE') 'Unavailable option is disabled and labeled'
    Assert-Result (-not $script:GO_checkboxes[31].IsEnabled -and $script:GO_states[31].Status -eq 'CHECK ERROR') 'Failed check is disabled and labeled instead of MISSING'
} finally {
    if (Test-Path -LiteralPath $script:testRegistryPath) {
        Remove-Item -LiteralPath $script:testRegistryPath -Recurse -Force
    }
}
