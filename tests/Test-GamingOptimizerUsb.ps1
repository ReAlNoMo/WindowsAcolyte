# PowerShell 7 -STA. Real registry IO is redirected to one HKCU test key.
# Hub providers are simulated: no real device power policy is changed.
$ErrorActionPreference = 'Stop'
$modulePath = Join-Path $PSScriptRoot '..\modules\05-GamingOptimizer.ps1'
$tokens=$null; $errors=$null
$ast=[System.Management.Automation.Language.Parser]::ParseFile($modulePath,[ref]$tokens,[ref]$errors)
if ($errors.Count) {throw ($errors.Message -join '; ')}
foreach ($definition in $ast.FindAll({param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -like 'Global:GO-*'},$true)) {
    . ([scriptblock]::Create($definition.Extent.Text))
}
$assignment=$ast.Find({param($node) $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -eq '$script:GO_tweaks'},$true)
$next=$ast.Find({param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Global:GO-GetRiskColor'},$true)
. ([scriptblock]::Create($ast.Extent.Text.Substring($assignment.Extent.StartOffset,$next.Extent.StartOffset-$assignment.Extent.StartOffset)))
$registryTweak=$script:GO_tweaks | Where-Object Id -eq 30
$hubTweak=$script:GO_tweaks | Where-Object Id -eq 31
$script:GO_tweaks=@($registryTweak,$hubTweak)
$script:GO_hw=@{Build=26100;IsX3D=$false}
$testId=[guid]::NewGuid().ToString('N')
$script:testKey="HKCU:\Software\WindowsAcolyte-UsbTests-$testId"
$script:testDirectory=Join-Path ([IO.Path]::GetTempPath()) "WindowsAcolyte-UsbTests-$testId"
$script:realPath='HKLM:\SYSTEM\CurrentControlSet\Services\USBHUB3'
New-Item -Path $script:testKey -Force | Out-Null
New-Item -Path $script:testDirectory -ItemType Directory | Out-Null
$script:productionWrite=(Get-Command GO-SetDW).ScriptBlock
$script:productionDelete=(Get-Command GO-DelReg).ScriptBlock
$beforeRegistry=Get-ItemPropertyValue -LiteralPath $script:realPath -Name DisableSelectiveSuspend -EA SilentlyContinue
$beforeHubs=@(Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable | Where-Object InstanceName -like '*ROOT_HUB*' | Select-Object InstanceName,Enable | ConvertTo-Json -Compress)

function Global:GO-GetUsbBackupPath {param($Id) Join-Path $script:testDirectory "usb-$Id.json"}
# Exercise the production backup reader/archiver, using temporary JSON without machine ACL changes.
function Global:GO-WriteUsbBackup {param($Id,$Backup) $Backup | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (GO-GetUsbBackupPath $Id); GO-ReadUsbBackup $Id | Out-Null}
function Global:Get-Item {
    param($LiteralPath,$Path,[switch]$Force,$EA)
    $actual=if($LiteralPath){$LiteralPath}else{$Path}
    if ($actual -eq $script:realPath) {$actual=$script:testKey}
    Microsoft.PowerShell.Management\Get-Item -LiteralPath $actual -Force:$Force -EA Stop
}
function Global:Test-Path {
    param($LiteralPath,$Path,$PathType='Any',$EA)
    $actual=if($LiteralPath){$LiteralPath}else{$Path}
    if ($actual -eq $script:realPath) {return $true}
    Microsoft.PowerShell.Management\Test-Path -LiteralPath $actual -PathType $PathType
}
function Global:Set-ItemProperty {
    param($LiteralPath,$Path,$Name,$Value,$Type,[switch]$Force,$EA)
    $actual=if($LiteralPath){$LiteralPath}else{$Path}
    if ($actual -eq $script:realPath) {$actual=$script:testKey}
    if ($actual -ne $script:testKey) {throw 'Unexpected registry property write'}
    Microsoft.PowerShell.Management\Set-ItemProperty -LiteralPath $actual -Name $Name -Value $Value -Type $Type -Force:$Force -EA Stop
}
function Global:GO-SetDW {
    param($p,$n,$v)
    if ($p -ne $script:realPath -or $n -ne 'DisableSelectiveSuspend') {throw 'Unexpected registry write'}
    & $script:productionWrite $script:testKey $n $v
}
function Global:GO-DelReg {
    param($p,$n)
    if ($p -ne $script:realPath -or $n -ne 'DisableSelectiveSuspend') {throw 'Unexpected registry deletion'}
    & $script:productionDelete $script:testKey $n
}
function Reset-HubModel {
    $script:hubs=@(
        [pscustomobject]@{InstanceId='USB\ROOT_HUB30\TEST_A';FriendlyName='Root Hub A'},
        [pscustomobject]@{InstanceId='USB\ROOT_HUB30\TEST_B';FriendlyName='Root Hub B'}
    )
    $script:providers=@(
        [pscustomobject]@{InstanceName='USB\ROOT_HUB30\TEST_A_0';Enable=$true},
        [pscustomobject]@{InstanceName='USB\ROOT_HUB30\TEST_B_0';Enable=$false},
        [pscustomobject]@{InstanceName='USB\VID_NOT_A_HUB\OTHER_0';Enable=$true}
    )
    $script:writes=@(); $script:failInstance=''
}
function Global:Get-PnpDevice {param([switch]$PresentOnly,$EA) $script:hubs}
function Global:Get-CimInstance {
    param($Namespace,$ClassName,$EA)
    if ($Namespace -ne 'root\wmi' -or $ClassName -ne 'MSPower_DeviceEnable') {throw 'Unexpected CIM query'}
    $script:providers
}
function Global:Set-CimInstance {
    param($InputObject,$Property,$EA)
    if ($InputObject.InstanceName -notlike 'USB\ROOT_HUB*') {throw 'Non-hub write blocked'}
    if ($InputObject.InstanceName -eq $script:failInstance) {throw 'Simulated unsupported/read-only provider'}
    $script:writes += $InputObject.InstanceName
    ($script:providers | Where-Object InstanceName -eq $InputObject.InstanceName).Enable=$Property.Enable
}
$script:assertions=0
function Assert-Usb($Condition,$Message) {
    $script:assertions++
    if (-not $Condition) {throw "FAILED: $Message"}
    Write-Output "PASS: $Message"
}
try {
    Assert-Usb ($registryTweak.Optional -and $hubTweak.Optional) 'Both USB options are explicit opt-ins'
    Assert-Usb (-not (GO-IsRecommended 30) -and -not (GO-IsRecommended 31)) 'Neither USB option is automatically recommended'
    Assert-Usb (-not (& $registryTweak.Check)) 'Absent registry value is not applied'
    GO-ApplyVerifiedTweak $registryTweak
    Assert-Usb ((GO-ReadUsbRegistry).Kind -eq 'DWord' -and (GO-ReadUsbRegistry).Data -eq 1) 'Override writes exactly REG_DWORD 1'
    $baseline=(Get-FileHash -LiteralPath (GO-GetUsbBackupPath 30)).Hash
    GO-ApplyVerifiedTweak $registryTweak
    Assert-Usb ($baseline -eq (Get-FileHash -LiteralPath (GO-GetUsbBackupPath 30)).Hash) 'Repeated registry Apply preserves original absence'
    GO-ResetTweak $registryTweak
    Assert-Usb (-not (GO-ReadUsbRegistry).Exists) 'Reset removes only an originally absent value'
    foreach ($original in @(@{Exists=$true;Kind='String';Data='custom'},@{Exists=$true;Kind='DWord';Data=0},@{Exists=$true;Kind='DWord';Data=1})) {
        GO-RestoreUsbRegistryValue $original
        $before=GO-ReadUsbRegistry
        GO-ApplyVerifiedTweak $registryTweak
        GO-ResetTweak $registryTweak
        $after=GO-ReadUsbRegistry
        Assert-Usb ($after.Kind -eq $before.Kind -and $after.Data -ceq $before.Data) "Original $($before.Kind)=$($before.Data) is restored, not an assumed default"
    }
    GO-RestoreUsbRegistryValue @{Exists=$true;Kind='String';Data='1'}
    Assert-Usb (-not (& $registryTweak.Check)) 'String 1 is not confused with required DWORD 1'
    $failed=$false
    try { GO-ResetTweak $registryTweak } catch { $failed=$true }
    Assert-Usb ($failed -and (GO-ReadUsbRegistry).Kind -eq 'String') 'Reset without an app baseline preserves pre-existing settings'
    Set-Content -LiteralPath (GO-GetUsbBackupPath 30) -Value '{invalid json'
    Assert-Usb ((GO-GetTweakState $registryTweak).Status -eq 'CHECK ERROR') 'Corrupt baseline is visible as CHECK ERROR'
    Remove-Item -LiteralPath (GO-GetUsbBackupPath 30)
    Reset-HubModel
    Assert-Usb (GO-UsbHubControlAvailable) 'Exact root-hub/provider mapping is supported'
    Assert-Usb (-not (& $hubTweak.Check)) 'Mixed hub permissions are not falsely applied'
    GO-ApplyVerifiedTweak $hubTweak
    Assert-Usb (@($script:providers | Where-Object { $_.InstanceName -like '*ROOT_HUB*' -and $_.Enable }).Count -eq 0) 'Allow computer to turn off is false on every root hub'
    Assert-Usb $script:providers[2].Enable 'Unrelated USB devices are not changed'
    GO-ApplyVerifiedTweak $hubTweak
    $saved=GO-ReadUsbBackup 31
    Assert-Usb ($saved.Entries[0].Enabled -and -not $saved.Entries[1].Enabled) 'Repeated hub Apply preserves each distinct original Boolean'
    GO-ResetTweak $hubTweak
    Assert-Usb ($script:providers[0].Enable -and -not $script:providers[1].Enable) 'Reset restores mixed original hub permissions exactly'
    Reset-HubModel
    $script:failInstance=$script:providers[1].InstanceName
    $failed=$false
    try {GO-ApplyVerifiedTweak $hubTweak} catch {$failed=$true}
    Assert-Usb ($failed -and (GO-ReadUsbBackup 31).Entries.Count -eq 2) 'Partial provider failure retains all pre-write baselines'
    $script:failInstance=''
    GO-ApplyVerifiedTweak $hubTweak
    GO-ResetTweak $hubTweak
    Assert-Usb $script:providers[0].Enable 'Retry does not overwrite baseline of an already changed hub'
    Reset-HubModel
    GO-ApplyVerifiedTweak $hubTweak
    $script:hubs=@($script:hubs | Where-Object InstanceId -like '*TEST_A')
    $failed=$false
    try {GO-ResetTweak $hubTweak} catch {$failed=$true}
    Assert-Usb ($failed -and $null -ne (GO-ReadUsbBackup 31)) 'Disconnected hub retains its backup for later Restore'
    $script:hubs+= [pscustomobject]@{InstanceId='USB\ROOT_HUB30\TEST_B';FriendlyName='Root Hub B'}
    GO-ResetTweak $hubTweak
    Assert-Usb (-not (Test-Path -LiteralPath (GO-GetUsbBackupPath 31))) 'Reconnect allows complete restoration and backup archival'
    Reset-HubModel
    GO-ApplyVerifiedTweak $hubTweak
    $script:hubs += [pscustomobject]@{InstanceId='USB\ROOT_HUB30\TEST_C';FriendlyName='Root Hub C'}
    $script:providers += [pscustomobject]@{InstanceName='USB\ROOT_HUB30\TEST_C_0';Enable=$true}
    Assert-Usb (-not (& $hubTweak.Check)) 'New hub power permission is detected on recheck'
    GO-ApplyVerifiedTweak $hubTweak
    Assert-Usb ((GO-ReadUsbBackup 31).Entries.Count -eq 3) 'New hub merges into existing baseline before Apply'
    GO-ResetTweak $hubTweak
    Assert-Usb ($script:providers[0].Enable -and -not $script:providers[1].Enable -and $script:providers[3].Enable) 'New and original hubs restore their independent baseline states'
    Reset-HubModel
    $script:providers=@($script:providers | Where-Object InstanceName -notlike '*TEST_B*')
    $script:writes=@()
    Assert-Usb ((GO-GetTweakState $hubTweak).Status -eq 'UNAVAILABLE') 'Unsupported hub is visible as UNAVAILABLE'
    $failed=$false
    try {GO-ApplyVerifiedTweak $hubTweak} catch {$failed=$true}
    Assert-Usb ($failed -and $script:writes.Count -eq 0) 'Unsupported mapping prevents every device write'
    Reset-HubModel
    $script:hubs=@()
    Assert-Usb (-not (& $hubTweak.Check)) 'No root hubs is not a successful power-policy check'
    Reset-HubModel
    $script:providers+= [pscustomobject]@{InstanceName='USB\ROOT_HUB30\TEST_A_1';Enable=$true}
    Assert-Usb (-not (GO-UsbHubControlAvailable)) 'Ambiguous WMI mapping is rejected'
    Reset-HubModel

    Add-Type -AssemblyName PresentationFramework
    $script:window=[System.Windows.Window]::new()
    $script:window.Resources.Add('SecondaryButton',[System.Windows.Style]::new([System.Windows.Controls.Button]))
    function Global:Get-PowerToolsWindow {$script:window}
    function Global:Get-PowerToolsBrush {param($Name) [System.Windows.Media.Brushes]::Gray}
    $script:GO_tweakList=[System.Windows.Controls.ItemsControl]::new()
    $script:GO_checkboxes=@{}
    $script:GO_applyBtn=[System.Windows.Controls.Button]::new()
    $script:GO_estimate=[System.Windows.Controls.TextBlock]::new()
    $script:GO_impactText=[System.Windows.Controls.TextBlock]::new()
    GO-RenderList
    foreach ($mode in @('All','Missing','Safe','Recommended')) {
        GO-SelectTweaks $mode
        Assert-Usb (-not $script:GO_checkboxes[30].IsChecked -and -not $script:GO_checkboxes[31].IsChecked) "Bulk $mode does not opt into USB stability changes"
    }
    $script:GO_checkboxes[31].IsChecked=$true
    GO-UpdateApplyState
    Assert-Usb ($script:GO_estimate.Text -like '*stability*' -and $script:GO_estimate.Text -notlike '*FPS gain:*') 'USB-only selection makes no estimated FPS claim'
    $profile='{"SelectedTweakIds":[31]}' | ConvertFrom-Json
    $loaded=GO-ApplyProfileSelection $profile
    Assert-Usb ($loaded.Loaded -eq 1 -and $script:GO_checkboxes[31].IsChecked) 'Explicit profile selection can opt into the hub setting'
    GO-ApplyVerifiedTweak $hubTweak
    GO-RenderList
    Assert-Usb ($script:GO_states[31].Applied -and -not $script:GO_checkboxes[31].IsEnabled) 'WPF recognizes unchecked Allow permission after Apply'
    GO-ResetTweak $hubTweak
    GO-RenderList
    Assert-Usb (-not $script:GO_states[31].Applied) 'WPF detects restored hub permissions'
    Write-Output "PASS: $script:assertions USB stability assertions; no real USB policy changed."
} finally {
    Remove-Item -LiteralPath $script:testKey -Recurse -Force -EA Stop
    $resolved=[IO.Path]::GetFullPath($script:testDirectory)
    if ($resolved -ne (Join-Path ([IO.Path]::GetTempPath()) "WindowsAcolyte-UsbTests-$testId")) {throw 'Unsafe test cleanup target'}
    Remove-Item -LiteralPath $resolved -Recurse -Force -EA Stop
    $afterRegistry=Get-ItemPropertyValue -LiteralPath $script:realPath -Name DisableSelectiveSuspend -EA SilentlyContinue
    if ($beforeRegistry -ne $afterRegistry) {throw 'Actual USB registry value changed'}
    $afterHubs=@(CimCmdlets\Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable | Where-Object InstanceName -like '*ROOT_HUB*' | Select-Object InstanceName,Enable | ConvertTo-Json -Compress)
    if (($beforeHubs -join '') -ne ($afterHubs -join '')) {throw 'Actual hub power state changed'}
}
