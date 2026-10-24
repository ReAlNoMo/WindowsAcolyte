# PowerShell 7 on Windows. Default: isolated model tests, no system-setting writes.
# -ReadOnly: execute all production status checks against the current machine.
param([switch]$ReadOnly)
$ErrorActionPreference = 'Stop'
$modulePath = Join-Path $PSScriptRoot '..\modules\05-GamingOptimizer.ps1'
$tokens = $null; $parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($modulePath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
foreach ($definition in $ast.FindAll({ param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -like 'Global:GO-*'
}, $true)) { . ([scriptblock]::Create($definition.Extent.Text)) }
$assignment = $ast.Find({ param($node)
    $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -eq '$script:GO_tweaks'
}, $true)
$nextFunction = $ast.Find({ param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Global:GO-GetRiskColor'
}, $true)
# Load definitions and visible relation notes, without executing module startup.
. ([scriptblock]::Create($ast.Extent.Text.Substring($assignment.Extent.StartOffset,
    $nextFunction.Extent.StartOffset - $assignment.Extent.StartOffset)))
$script:GO_hw = @{Build=[Environment]::OSVersion.Version.Build;IsX3D=$false}
if ($ReadOnly) {
    foreach ($tweak in $script:GO_tweaks) {
        $state = GO-GetTweakState $tweak
        [pscustomobject]@{Id=$tweak.Id;Option=$tweak.Label;Status=$state.Status;Detail=$(if ($state.Status -eq 'CHECK ERROR') {$state.Message} else {$tweak.Note})}
    }
    exit
}

# Optional input/USB controls use separate baseline/provider tests; never execute their
# machine-backed operations through the legacy registry/native-command model.
$script:GO_tweaks = @($script:GO_tweaks | Where-Object { $_.Id -le 29 })

$script:assertions = 0
function Assert-Audit($Condition, $Message) {
    $script:assertions++
    if (-not $Condition) { throw "FAILED: $Message" }
}
$script:originalNative = (Get-Command GO-InvokeNative).ScriptBlock
$script:fsPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'
$script:balanced = '381b4222-f694-41f0-9685-ff5bb260df2e'
function Reset-Model {
    $script:registry = @{}
    $script:plans = @(@{Guid=$script:balanced;Name='Ausbalanciert'})
    $script:activePlan = $script:balanced
    $script:tcp = @{AutoTuningLevelLocal='Normal';EcnCapability='Enabled';Timestamps='Enabled'}
    $script:offload = @{ReceiveSideScaling='Disabled';ReceiveSegmentCoalescing='Enabled'}
    $script:service = @{Name='DiagTrack';StartType='Automatic';Status='Running'}
    $script:adapters = @(
        @{Name='Ethernet';Status='Up';InterfaceType=6;InterfaceGuid='{00000000-0000-0000-0000-000000000001}';Physical=$true},
        @{Name='Wi-Fi';Status='Up';InterfaceType=71;InterfaceGuid='{00000000-0000-0000-0000-000000000002}';Physical=$true},
        @{Name='VPN';Status='Up';InterfaceType=6;InterfaceGuid='{00000000-0000-0000-0000-000000000003}';Physical=$false}
    )
    $script:serviceFailure = $false
    $script:commandFailure = $false
}
function Global:GO-GetReg { param($p,$n) $script:registry["$p|$n"] }
function Global:GO-SetDW { param($p,$n,$v) $script:registry["$p|$n"] = $v }
function Global:GO-SetStr { param($p,$n,$v) $script:registry["$p|$n"] = $v }
function Global:GO-DelReg { param($p,$n) $script:registry.Remove("$p|$n") }
function Global:Get-NetAdapter {
    param([switch]$Physical, $EA)
    $script:adapters | Where-Object { -not $Physical -or $_.Physical } | ForEach-Object { [pscustomobject]$_ }
}
function Global:Get-NetTCPSetting { param($SettingName,$EA) [pscustomobject]$script:tcp }
function Global:Get-NetOffloadGlobalSetting { param($EA) [pscustomobject]$script:offload }
function Global:Get-Service { param($Name,$EA) [pscustomobject]$script:service }
function Global:Set-Service {
    param($Name,$StartupType,$EA)
    if ($script:serviceFailure) { throw 'Simulated access denied' }
    $script:service.StartType = $StartupType
}
function Global:Stop-Service {
    param($Name,[switch]$Force,$EA)
    if ($script:serviceFailure) { throw 'Simulated access denied' }
    $script:service.Status = 'Stopped'
}
function Global:GO-InvokeNative {
    param($FilePath, [string[]]$Arguments)
    if ($script:commandFailure) { throw 'Simulated native failure' }
    switch ($FilePath) {
        'fsutil.exe' {
            if ($Arguments[0] -ne 'behavior' -or $Arguments[1] -ne 'set') { throw 'Unexpected fsutil operation' }
            $name = switch ($Arguments[2]) {
                'disable8dot3' {'NtfsDisable8dot3NameCreation'}
                'disablelastaccess' {'NtfsDisableLastAccessUpdate'}
                default { throw 'Unexpected fsutil setting' }
            }
            GO-SetDW $script:fsPath $name ([int]$Arguments[3])
        }
        'netsh.exe' {
            $name,$value = $Arguments[4] -split '='
            $enabled = if ($value -eq 'disabled') {'Disabled'} else {'Enabled'}
            switch ($name) {
                'autotuninglevel' { $script:tcp.AutoTuningLevelLocal = $value }
                'ecncapability' { $script:tcp.EcnCapability = $enabled }
                'timestamps' { $script:tcp.Timestamps = $enabled }
                'rss' { $script:offload.ReceiveSideScaling = $enabled }
                'rsc' { $script:offload.ReceiveSegmentCoalescing = $enabled }
                default { throw 'Unexpected TCP setting' }
            }
        }
        'powercfg.exe' {
            switch ($Arguments[0]) {
                '/list' { foreach ($plan in $script:plans) { "Energieschema-GUID: $($plan.Guid) ($($plan.Name))" } }
                '/getactivescheme' {
                    $plan = $script:plans | Where-Object { $_.Guid -eq $script:activePlan } | Select-Object -First 1
                    "Energieschema-GUID: $($plan.Guid) ($($plan.Name))"
                }
                '/duplicatescheme' { $script:plans += @{Guid=$Arguments[2];Name='Hoechstleistung'} }
                '/changename' { ($script:plans | Where-Object { $_.Guid -eq $Arguments[1] }).Name = $Arguments[2] }
                '/setactive' { $script:activePlan = if ($Arguments[1] -eq 'SCHEME_BALANCED') {$script:balanced} else {$Arguments[1]} }
                default { throw 'Unexpected powercfg operation' }
            }
        }
        default { throw "Unexpected native executable: $FilePath" }
    }
}

Assert-Audit ($script:GO_tweaks.Count -eq 29) 'All 29 selectable options included'
foreach ($tweak in $script:GO_tweaks) {
    Reset-Model
    $initial = @(& $tweak.Check)
    Assert-Audit ($initial.Count -eq 1 -and $initial[0] -is [bool]) "#$($tweak.Id) returns one Boolean"
    Assert-Audit (-not $initial[0]) "#$($tweak.Id) baseline not falsely applied"
    GO-ApplyVerifiedTweak $tweak
    Assert-Audit (GO-GetTweakState $tweak).Applied "#$($tweak.Id) applied configuration passes"
    # Every registry field written must be covered by Check, not just the first.
    foreach ($key in @($script:registry.Keys)) {
        $value = $script:registry[$key]
        $script:registry.Remove($key)
        Assert-Audit (-not (& $tweak.Check)) "#$($tweak.Id) detects missing field $key"
        $script:registry[$key] = $value
    }
    GO-ResetTweak $tweak
    Assert-Audit (-not (& $tweak.Check)) "#$($tweak.Id) reset clears applied status"
    Write-Output "PASS: #$($tweak.Id) $($tweak.Label) - Apply/Check/Reset"
}

# Any Apply that turns off another option must be an explicit priority alternative.
$applyRelations = @()
foreach ($first in $script:GO_tweaks) {
    foreach ($second in $script:GO_tweaks) {
        if ($first.Id -eq $second.Id) { continue }
        Reset-Model
        GO-ApplyVerifiedTweak $first
        GO-ApplyVerifiedTweak $second
        if (-not (& $first.Check)) { $applyRelations += "$($first.Id)>$($second.Id)" }
    }
}
Assert-Audit (($applyRelations | Sort-Object) -join ',' -eq '10>9,9>10') 'All 812 ordered Apply pairs have only declared priority conflicts'

$resetRelations = @()
foreach ($first in $script:GO_tweaks) {
    foreach ($second in $script:GO_tweaks) {
        if ($first.Id -eq $second.Id) { continue }
        Reset-Model
        GO-ApplyVerifiedTweak $first
        GO-ResetTweak $second
        if (-not (& $first.Check)) {
            $resetRelations += "$($first.Id)>$($second.Id)"
            Assert-Audit (-not [string]::IsNullOrWhiteSpace($second.Note)) 'Cross-setting reset has a visible note'
        }
    }
}
Assert-Audit (@(Compare-Object @('10>9','1>2','2>1','9>10') $resetRelations).Count -eq 0) "All 812 ordered Reset pairs have only declared VBS/HVCI and priority interactions (found: $($resetRelations -join ', '))"

Reset-Model
$lastAccess = $script:GO_tweaks | Where-Object Id -eq 22
foreach ($value in @(1,3,2147483649,2147483651,-2147483647,-2147483645)) {
    GO-SetDW $script:fsPath NtfsDisableLastAccessUpdate $value
    Assert-Audit (& $lastAccess.Check) "LastAccess recognizes disabled numeric state $value"
}
foreach ($value in @(0,2,2147483648,2147483650)) {
    GO-SetDW $script:fsPath NtfsDisableLastAccessUpdate $value
    Assert-Audit (-not (& $lastAccess.Check)) "LastAccess rejects enabled numeric state $value"
}
$eightDotThree = $script:GO_tweaks | Where-Object Id -eq 23
foreach ($value in @(0,1,2,3)) {
    GO-SetDW $script:fsPath NtfsDisable8dot3NameCreation $value
    Assert-Audit ((& $eightDotThree.Check) -eq ($value -eq 1)) "8.3 policy recognizes numeric state $value regardless of fsutil language"
}
$nagle = $script:GO_tweaks | Where-Object Id -eq 16
$script:adapters = @()
Assert-Audit ((GO-GetTweakState $nagle).Status -eq 'UNAVAILABLE') 'No physical adapter is unavailable, not applied'
Reset-Model
GO-ApplyVerifiedTweak $nagle
Assert-Audit (@($script:registry.Keys | Where-Object { $_ -like '*000000000003*' }).Count -eq 0) 'VPN is not configured'
Assert-Audit (@($script:registry.Keys | Where-Object { $_ -like '*000000000002*' }).Count -eq 3) 'Wi-Fi is configured and verified'

$tcpTweak = $script:GO_tweaks | Where-Object Id -eq 17
foreach ($field in @('AutoTuningLevelLocal','EcnCapability','Timestamps','ReceiveSideScaling','ReceiveSegmentCoalescing')) {
    Reset-Model
    GO-ApplyVerifiedTweak $tcpTweak
    if ($script:tcp.ContainsKey($field)) { $script:tcp[$field] = 'Wrong' } else { $script:offload[$field] = 'Wrong' }
    Assert-Audit (-not (& $tcpTweak.Check)) "TCP check includes $field"
}
$telemetry = $script:GO_tweaks | Where-Object Id -eq 26
foreach ($field in @('StartType','Status')) {
    Reset-Model
    GO-ApplyVerifiedTweak $telemetry
    $script:service[$field] = 'Wrong'
    Assert-Audit (-not (& $telemetry.Check)) "Telemetry check includes service $field"
}
Reset-Model
$script:serviceFailure = $true
$failed = $false
try { GO-ApplyVerifiedTweak $telemetry } catch { $failed = $true }
Assert-Audit $failed 'Service errors fail the operation'
foreach ($id in @(5,17,22,23)) {
    Reset-Model
    $script:commandFailure = $true
    $failed = $false
    try { GO-ApplyVerifiedTweak ($script:GO_tweaks | Where-Object Id -eq $id) } catch { $failed = $true }
    Assert-Audit $failed "Native failures for #$id do not report success"
}
Reset-Model
$nativeFailure = $false
try { & $script:originalNative (Get-Process -Id $PID).Path @('-NoProfile','-Command','exit 7') | Out-Null }
catch { $nativeFailure = $_.Exception.Message -like '*exit 7*' }
Assert-Audit $nativeFailure 'Production native wrapper propagates actual nonzero exit code'
$nvme = $script:GO_tweaks | Where-Object Id -eq 24
$script:GO_hw.Build = 22000
Assert-Audit ((GO-GetTweakState $nvme).Status -eq 'UNAVAILABLE') 'Experimental override gated below supported build'
$script:GO_hw.Build = 26100
Assert-Audit (-not (GO-IsRecommended 24)) 'Experimental override never automatically selected'
$badResult = @{Check={ $false; $false }}
Assert-Audit ((GO-GetTweakState $badResult).Status -eq 'CHECK ERROR') 'Array truthiness cannot become applied status'

$script:auditLog = @()
function Global:GO-AddLog { param($Msg,$Type) $script:auditLog += "$Type $Msg" }
Reset-Model
$hvci = $script:GO_tweaks | Where-Object Id -eq 1
$vbs = $script:GO_tweaks | Where-Object Id -eq 2
GO-ApplyVerifiedTweak $hvci
$before = GO-GetStateSnapshot
GO-ResetTweak $vbs
$after = GO-GetStateSnapshot
GO-LogStateChanges $before $after 'Reset VBS'
Assert-Audit (@($script:auditLog | Where-Object { $_ -like '*Memory Integrity*' }).Count -eq 1) 'Reset invalidating HVCI is logged visibly'

# Backup failure handling, without creating a real restore point or exporting hives.
$script:GO_cbRestore = @{IsChecked=$true}
$script:GO_cbRegBkp = @{IsChecked=$false}
$script:restoreCreated = $false
$script:restoreDescription = ''
function Global:Enable-ComputerRestore { param($Drive,$EA) }
function Global:Checkpoint-Computer { param($Description,$RestorePointType,$EA) $script:restoreDescription=$Description }
function Global:Get-ComputerRestorePoint {
    param($EA)
    if ($script:restoreCreated) { [pscustomobject]@{Description=$script:restoreDescription} }
}
Assert-Audit (-not (GO-CreateBackup $PSScriptRoot)) 'Restore-point frequency/no-op failure cannot report backup success'
$script:restoreCreated = $true
Assert-Audit (GO-CreateBackup $PSScriptRoot) 'Restore-point success requires verified creation'
$script:GO_cbRestore.IsChecked = $false
$script:GO_cbRegBkp.IsChecked = $true
$script:commandFailure = $true
Assert-Audit (-not (GO-CreateBackup $PSScriptRoot)) 'Registry export failure propagates to the Apply backup gate'
Write-Output "PASS: $script:assertions assertions; 29 option lifecycles; 812 Apply pairs + 812 Reset pairs. No machine settings changed."
