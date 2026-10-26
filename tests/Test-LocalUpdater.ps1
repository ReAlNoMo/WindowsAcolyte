# Compatible with Windows PowerShell 5.1 and PowerShell 7. All downloads mocked.
$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path $PSScriptRoot -Parent) 'Start-WindowsAcolyte.ps1')
function Assert-Update($Condition, $Message) {
    if (-not $Condition) { throw $Message }
    Write-Output "PASS: $Message"
}
function Assert-Failure($Action, $Message) {
    $failed = $false
    try { & $Action | Out-Null } catch { $failed = $true }
    Assert-Update $failed $Message
}
$testRoot = Join-Path $env:TEMP ('WindowsAcolyte-Updater-Test-' + [guid]::NewGuid().ToString('N'))
$install = Join-Path $testRoot 'installed'
$fixtures = Join-Path $testRoot 'remote'
[void][IO.Directory]::CreateDirectory((Join-Path $fixtures 'modules'))
$script:revision = 'a' * 40
$script:entries = @()
$script:downloads = @()
$script:offline = $false
$script:corrupt = $false
$script:missingDownload = $false
$script:resolveCalls = 0
$script:jsonCalls = 0
function Write-Fixture($Path, $Content) {
    $target = Join-Path $fixtures $Path
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))
    [IO.File]::WriteAllText($target,$Content)
    $script:entries = @($script:entries | Where-Object path -ne $Path)
    $script:entries += [pscustomobject]@{path=$Path; sha=(Get-WAUBlobHash $target); type='blob'; mode='100644'}
}
function Get-WAUJson {
    param($Uri)
    $script:jsonCalls++
    if ($script:offline) { throw 'Simulated offline / API failure' }
    if ($Uri.EndsWith('/commits/main')) { return @{sha=$script:revision} }
    return @{truncated=$false;tree=$script:entries}
}
function Save-WAUDownload {
    param($Uri,$Path)
    if ($script:missingDownload) { throw 'Simulated interrupted download' }
    $prefix = 'https://raw.githubusercontent.com/ReAlNoMo/WindowsAcolyte/' + $script:revision + '/'
    if (-not $Uri.StartsWith($prefix)) { throw 'Download is not pinned to the selected commit' }
    $relative = $Uri.Substring($prefix.Length)
    $script:downloads += $relative
    [IO.File]::Copy((Join-Path $fixtures $relative),$Path,$true)
    if ($script:corrupt) { [IO.File]::AppendAllText($Path,'CORRUPT') }
}
function Find-WAUPowerShell7 { $script:resolveCalls++; throw 'Tests must never reach the launch step' }
try {
    Write-Fixture 'WindowsAcolyte.ps1' '# app v1'
    Write-Fixture 'Start-WindowsAcolyte.ps1' '# starter v1'
    Write-Fixture 'README.md' 'Readme v1'
    Write-Fixture 'modules/08-DesktopShortcutCreator.ps1' '# shortcuts v1'
    Write-Fixture 'modules/99-Old.ps1' '# retired module'
    $result = Sync-WAUInstallation $install
    Assert-Update ($result.Updated -eq 5) 'Initial install includes all managed files'
    [void][IO.Directory]::CreateDirectory((Join-Path $install 'GamingOptimizer'))
    [IO.File]::WriteAllText((Join-Path $install 'GamingOptimizer/private.json'),'private profile')
    [IO.File]::WriteAllText((Join-Path $install 'modules/Custom.ps1'),'# user module')
    $script:downloads = @()
    $before = $script:jsonCalls
    $result = Sync-WAUInstallation $install
    Assert-Update ($script:jsonCalls -eq $before+2 -and $result.Updated -eq 0 -and $script:downloads.Count -eq 0) 'Every start checks online; unchanged files are not downloaded'
    Remove-Item -LiteralPath (Join-Path $install 'modules/08-DesktopShortcutCreator.ps1')
    [IO.File]::WriteAllText((Join-Path $install 'WindowsAcolyte.ps1'),'# local damage')
    $result = Sync-WAUInstallation $install
    Assert-Update ($result.Updated -eq 2) 'Missing and modified files are repaired even on the same revision'
    $script:revision = 'b' * 40
    $script:entries = @($script:entries | Where-Object path -ne 'modules/99-Old.ps1')
    Write-Fixture 'modules/12-RecommendedTools.ps1' '# added recommendation module'
    $result = Sync-WAUInstallation $install
    Assert-Update ($result.Updated -eq 1 -and $result.Removed -eq 1 -and -not (Test-Path -LiteralPath (Join-Path $install 'modules/99-Old.ps1'))) 'New modules installed and retired managed modules removed'
    Assert-Update ((Test-Path -LiteralPath (Join-Path $install 'modules/Custom.ps1')) -and [IO.File]::ReadAllText((Join-Path $install 'GamingOptimizer/private.json')) -eq 'private profile') 'Custom files and private profiles retained'
    $script:offline = $true
    Assert-Failure { Invoke-WAULocalStart $install } 'Offline check blocks app launch'
    Assert-Update ($script:resolveCalls -eq 0) 'Launch step is never reached after a failed check'
    $script:offline = $false
    Write-Fixture 'WindowsAcolyte.ps1' '# app v2'
    $script:missingDownload = $true
    Assert-Failure { Sync-WAUInstallation $install } 'Interrupted download blocks update'
    $script:missingDownload = $false
    $script:corrupt = $true
    Assert-Failure { Sync-WAUInstallation $install } 'Corrupt download rejected'
    Assert-Update ([IO.File]::ReadAllText((Join-Path $install 'WindowsAcolyte.ps1')) -eq '# app v1') 'Failed staging leaves installed app unchanged'
    $script:corrupt = $false
    Write-Fixture 'WindowsAcolyte.ps1' 'function { invalid syntax'
    Assert-Failure { Sync-WAUInstallation $install } 'Invalid downloaded PowerShell rejected before activation'
    Write-Fixture 'WindowsAcolyte.ps1' '# app v2'
    # Ensure a prior successful write is rolled back when a later destination is locked.
    Write-Fixture 'README.md' 'Readme v2'
    $script:entries = @($script:entries | Sort-Object @{Expression={if($_.path -eq 'WindowsAcolyte.ps1'){0}else{1}}})
    $locked = [IO.File]::Open((Join-Path $install 'README.md'),'Open','Read','Read')
    try { Assert-Failure { Sync-WAUInstallation $install } 'File lock during apply triggers rollback' }
    finally { $locked.Dispose() }
    Assert-Update ([IO.File]::ReadAllText((Join-Path $install 'WindowsAcolyte.ps1')) -eq '# app v1') 'Earlier writes restored after apply failure'
    $lock = [IO.File]::Open((Join-Path $install '.update.lock'),'Open','ReadWrite','None')
    try { Assert-Failure { Sync-WAUInstallation $install } 'Simultaneous updater is blocked' }
    finally { $lock.Dispose() }
    $result = Sync-WAUInstallation $install
    Assert-Update ($result.Updated -eq 2) 'Retry succeeds after rollback and lock release'
    $state = [IO.File]::ReadAllText((Join-Path $install '.installed-release.json')) | ConvertFrom-Json
    Assert-Update ($state.Revision -eq $script:revision) 'Revision recorded only after successful apply'
    Assert-Update (-not (Test-WAUManagedPath '../outside.ps1') -and -not (Test-WAUManagedPath 'modules/../../outside.ps1') -and -not (Test-WAUManagedPath 'GamingOptimizer/private.json')) 'Remote paths cannot target unrelated data'
    $modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'modules/08-DesktopShortcutCreator.ps1'
    $tokens=$null; $errors=$null
    $ast = [Management.Automation.Language.Parser]::ParseFile($modulePath,[ref]$tokens,[ref]$errors)
    $bootstrapFunction = $ast.Find({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Global:DSC-EnsurePowerShell7Bootstrap'},$true)
    . ([scriptblock]::Create($bootstrapFunction.Extent.Text))
    $Global:PTS_RootPath = Split-Path $PSScriptRoot -Parent
    $bootstrap = DSC-EnsurePowerShell7Bootstrap -InstallPath $install
    Assert-Update ((Get-FileHash -LiteralPath $bootstrap).Hash -eq (Get-FileHash -LiteralPath (Join-Path $Global:PTS_RootPath 'Start-WindowsAcolyte.ps1')).Hash) 'Shortcut creator deploys the canonical update-aware starter'
    $script:entries += [pscustomobject]@{path='WindowsAcolyte.ps1';sha=('c'*40);mode='120000';type='blob'}
    Assert-Failure { Sync-WAUInstallation $install } 'Duplicate or symlink release entry rejected'
} finally {
    $expectedParent = [IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
    $resolved = [IO.Path]::GetFullPath($testRoot)
    if ($resolved.StartsWith($expectedParent,[StringComparison]::OrdinalIgnoreCase) -and [IO.Path]::GetFileName($resolved).StartsWith('WindowsAcolyte-Updater-Test-')) {
        [IO.Directory]::Delete($resolved,$true)
    }
}
