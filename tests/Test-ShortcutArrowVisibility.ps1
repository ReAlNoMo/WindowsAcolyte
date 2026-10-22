# PowerShell 7 -STA on Windows. Uses a unique HKCU key + temporary assets.
# Never writes the actual HKLM overlay or restarts a real Explorer process.
$ErrorActionPreference = 'Stop'
$modulePath = Join-Path $PSScriptRoot '..\modules\11-ShortcutArrowVisibility.ps1'
function Register-PowerToolsModule {
    param($Id,$Name,$Description,$Category,$RequiresAdmin,$Show)
    $script:registration = $PSBoundParameters
}
. $modulePath
$script:originalPaths = (Get-Command SAV-GetPaths).ScriptBlock
$script:originalRegistry = (Get-Command SAV-OpenRegistry).ScriptBlock
$beforeMachineValue = SAV-ReadValue | ConvertTo-Json -Depth 5 -Compress
$testId = [guid]::NewGuid().ToString('N')
$script:testDirectory = Join-Path ([IO.Path]::GetTempPath()) "WindowsAcolyte-ArrowTests-$testId"
$script:testSubKey = "Software\WindowsAcolyte-Tests\$testId"
New-Item -ItemType Directory -Path $script:testDirectory -EA Stop | Out-Null
function Global:SAV-GetPaths {
    return @{Directory=$script:testDirectory;Icon=(Join-Path $script:testDirectory 'transparent-arrow.ico');
        Backup=(Join-Path $script:testDirectory 'original-29.json');SubKey="$script:testSubKey\Shell Icons"}
}
function Global:SAV-OpenRegistry {
    [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::CurrentUser,[Microsoft.Win32.RegistryView]::Default)
}
function Global:SAV-PrepareDirectory { } # Production ACLs require elevation; test only touches own temp directory.
$script:assertions = 0
function Assert-Arrow($Condition,$Message) {
    $script:assertions++
    if (-not $Condition) { throw "FAILED: $Message" }
    Write-Output "PASS: $Message"
}
function Get-TestSibling {
    $root = SAV-OpenRegistry
    $key = $root.OpenSubKey((SAV-GetPaths).SubKey)
    try { $key.GetValue('3') } finally { $key.Dispose(); $root.Dispose() }
}
try {
    Add-Type -AssemblyName PresentationFramework
    Assert-Arrow ($script:registration.Category -eq 'Windows Tweaks' -and $script:registration.RequiresAdmin) 'Module registered under Windows Tools with administrator requirement'
    Assert-Arrow (-not (SAV-ReadValue).Exists) 'Absent key/value is detected without creating the key'
    $root = SAV-OpenRegistry
    $key = $root.CreateSubKey((SAV-GetPaths).SubKey)
    try { $key.SetValue('3','keep-folder-icon',[Microsoft.Win32.RegistryValueKind]::String) }
    finally { $key.Dispose(); $root.Dispose() }
    Assert-Arrow (SAV-HideArrows) 'Apply creates the transparent icon and registry string'
    $state = SAV-GetState
    Assert-Arrow ($state.Configured -and $state.BackupAvailable -and $state.Value.Kind -eq 'String') 'Registry, type, icon and baseline backup verified'
    $backupBefore = (Get-FileHash -LiteralPath (SAV-GetPaths).Backup).Hash
    Assert-Arrow (-not (SAV-HideArrows)) 'Repeated Apply is a no-op'
    Assert-Arrow ($backupBefore -eq (Get-FileHash -LiteralPath (SAV-GetPaths).Backup).Hash) 'Repeated Apply preserves original backup'

    $decoder = [System.Windows.Media.Imaging.BitmapDecoder]::Create([Uri](SAV-GetPaths).Icon,
        [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat,[System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad)
    Assert-Arrow ($decoder.Frames.Count -eq 7) 'ICO contains seven sizes for DPI scaling'
    foreach ($frame in $decoder.Frames) {
        $converted = [System.Windows.Media.Imaging.FormatConvertedBitmap]::new($frame,[System.Windows.Media.PixelFormats]::Bgra32,$null,0)
        $pixels = [byte[]]::new($converted.PixelWidth * $converted.PixelHeight * 4)
        $converted.CopyPixels($pixels,$converted.PixelWidth * 4,0)
        $transparent = $true
        for ($index=3; $index -lt $pixels.Length; $index+=4) { if ($pixels[$index] -ne 0) {$transparent=$false;break} }
        Assert-Arrow $transparent "ICO $($converted.PixelWidth)px frame is completely transparent"
    }

    [IO.File]::WriteAllBytes((SAV-GetPaths).Icon,[byte[]]@(0,1,2))
    Assert-Arrow (SAV-GetState).RepairNeeded 'Corrupted icon is detected'
    Assert-Arrow (SAV-HideArrows) 'Apply repairs corrupted icon'
    Assert-Arrow ($backupBefore -eq (Get-FileHash -LiteralPath (SAV-GetPaths).Backup).Hash) 'Repair preserves original backup'
    Remove-Item -LiteralPath (SAV-GetPaths).Icon -EA Stop
    Assert-Arrow (SAV-GetState).RepairNeeded 'Missing managed icon is detected'
    Assert-Arrow (SAV-HideArrows) 'Apply repairs a missing managed icon'
    Assert-Arrow (SAV-RestoreOriginal) 'Restore removes value 29 if originally absent'
    Assert-Arrow (-not (SAV-ReadValue).Exists) 'Originally absent 29 is absent after restore'
    Assert-Arrow ((Get-TestSibling) -eq 'keep-folder-icon') 'Unrelated Shell Icons value 3 is preserved'
    Assert-Arrow (-not (Test-Path -LiteralPath (SAV-GetPaths).Backup)) 'Completed restore retires the baseline backup'

    foreach ($original in @(
        @{Exists=$true;Kind='String';Data=''},
        @{Exists=$true;Kind='String';Data='C:\custom icon.dll,-7'},
        @{Exists=$true;Kind='ExpandString';Data='%SystemRoot%\custom.dll,-7'},
        @{Exists=$true;Kind='DWord';Data=-1},
        @{Exists=$true;Kind='QWord';Data=[long]::MaxValue},
        @{Exists=$true;Kind='Binary';Data=[byte[]]@(0,1,255)},
        @{Exists=$true;Kind='MultiString';Data=[string[]]@('first','second')},
        @{Exists=$true;Kind='None';Data=[byte[]]@(7,0,4)}
    )) {
        SAV-WriteValue $original
        $expected = SAV-ReadValue
        Assert-Arrow (SAV-HideArrows) "Custom $($original.Kind) override can be replaced after backup"
        Assert-Arrow (SAV-RestoreOriginal) "Original $($original.Kind) value restored"
        $actual = SAV-ReadValue
        Assert-Arrow ($actual.Kind -eq $expected.Kind -and
            (ConvertTo-Json -InputObject $actual.Data -Compress) -eq (ConvertTo-Json -InputObject $expected.Data -Compress)) "Original $($original.Kind) type/data preserved exactly"
    }

    SAV-WriteValue @{Exists=$false}
    SAV-HideArrows | Out-Null
    SAV-WriteValue @{Exists=$true;Kind='String';Data='external-change.ico,0'}
    $blocked = $false
    try { SAV-RestoreOriginal | Out-Null } catch { $blocked=$true }
    Assert-Arrow ($blocked -and (SAV-ReadValue).Data -eq 'external-change.ico,0') 'Restore refuses to overwrite an external customization'
    SAV-WriteValue @{Exists=$true;Kind='String';Data="$((SAV-GetPaths).Icon),0"}
    SAV-RestoreOriginal | Out-Null
    [IO.File]::WriteAllText((SAV-GetPaths).Backup,'{"Version":999}')
    $blocked = $false
    try { SAV-HideArrows | Out-Null } catch { $blocked=$true }
    Assert-Arrow ($blocked -and -not (SAV-ReadValue).Exists) 'Malformed backup blocks registry mutation'
    Remove-Item -LiteralPath (SAV-GetPaths).Backup -EA Stop

    # Restart orchestration only. These mocks never terminate/start real processes.
    $script:stopped = @(); $script:started=0; $script:polls=0; $script:restartMode='Auto'
    function Global:SAV-GetOwnExplorer {
        $script:polls++
        if ($script:restartMode -eq 'WrongOwner') { throw 'Explorer belongs to another user' }
        if ($script:polls -eq 1) { return [pscustomobject]@{Id=40001} }
        if ($script:restartMode -eq 'Auto' -or $script:started -gt 0) { return [pscustomobject]@{Id=40002} }
        return $null
    }
    function Global:Stop-Process { param($Id,[switch]$Force,$EA) $script:stopped += $Id }
    function Global:Start-Process { param($FilePath,$EA) $script:started++ }
    function Global:Start-Sleep { param($Milliseconds) }
    Assert-Arrow ((SAV-RestartExplorer) -eq 40002 -and $script:stopped.Count -eq 1 -and $script:started -eq 0) 'Auto-restarted Explorer is verified without launching a duplicate'
    $script:polls=0; $script:restartMode='Fallback'
    Assert-Arrow ((SAV-RestartExplorer) -eq 40002 -and $script:started -eq 1) 'Fallback restart starts Explorer only if auto-restart did not occur'
    $script:restartMode='WrongOwner'; $stoppedBefore=$script:stopped.Count
    $blocked=$false
    try { SAV-RestartExplorer | Out-Null } catch { $blocked=$true }
    Assert-Arrow ($blocked -and $script:stopped.Count -eq $stoppedBefore) 'Wrong-user shell cannot be terminated'

    $script:testWindow = [System.Windows.Window]::new()
    foreach ($name in @('PrimaryButton','SecondaryButton')) { $script:testWindow.Resources.Add($name,[System.Windows.Style]::new([System.Windows.Controls.Button])) }
    function Get-PowerToolsWindow { $script:testWindow }
    $view = & $script:registration.Show
    Assert-Arrow ($null -ne $view -and $null -ne $view.FindName('HideBtn')) 'Actual WPF module view loads'
    Assert-Arrow ($view.FindName('HideBtn').IsEnabled -and -not $view.FindName('RestoreBtn').IsEnabled) 'Initial WPF buttons reflect detected state'
    SAV-HideArrows | Out-Null
    SAV-Refresh
    Assert-Arrow (-not $view.FindName('HideBtn').IsEnabled -and $view.FindName('RestoreBtn').IsEnabled) 'WPF updates buttons after verified Apply'
    $view.Measure([System.Windows.Size]::new(600,[double]::PositiveInfinity))
    Assert-Arrow ($view.DesiredSize.Width -le 600) 'Narrow WPF layout fits without horizontal clipping'
    Write-Output "PASS: $script:assertions assertions. No real HKLM overlay or Explorer process changed."
} finally {
    $root = SAV-OpenRegistry
    try {
        if ($script:testSubKey -notlike 'Software\WindowsAcolyte-Tests\*' -or $script:testSubKey -notlike "*$testId") { throw 'Unsafe test registry cleanup target' }
        $root.DeleteSubKeyTree($script:testSubKey,$false)
    } finally { $root.Dispose() }
    $resolvedTestDirectory = [IO.Path]::GetFullPath($script:testDirectory)
    if ($resolvedTestDirectory -ne (Join-Path ([IO.Path]::GetTempPath()) "WindowsAcolyte-ArrowTests-$testId")) { throw 'Unsafe test directory cleanup target' }
    Remove-Item -LiteralPath $resolvedTestDirectory -Recurse -Force -EA Stop
    Set-Item Function:\SAV-GetPaths -Value $script:originalPaths
    Set-Item Function:\SAV-OpenRegistry -Value $script:originalRegistry
    $afterMachineValue = SAV-ReadValue | ConvertTo-Json -Depth 5 -Compress
    if ($beforeMachineValue -ne $afterMachineValue) { throw 'Actual HKLM overlay changed unexpectedly' }
}
