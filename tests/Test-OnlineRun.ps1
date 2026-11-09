# Simulates UAC and the elevated runner. All files are in a unique test directory.
$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path $PSScriptRoot -Parent) 'Start-WindowsAcolyte.ps1')
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('WindowsAcolyte-OnlineTest-' + [guid]::NewGuid().ToString('N'))
$cache = Join-Path $testRoot 'cache'
$session = Join-Path $testRoot 'runtime'
$fixture = Join-Path $testRoot 'fixture.ps1'
$expectedRevision = 'a' * 40
$script:admin = $false
$script:downloadMode = 'ok'
$script:downloads = 0
$script:launches = 0
$script:syncs = 0
$script:handoffs = 0

function Test-WAUAdministrator { $script:admin }
function Sync-WAUInstallation {
    param($InstallPath)
    if ($InstallPath -ne $cache) { throw 'Wrong cache path' }
    $script:syncs++
    [pscustomobject]@{ Revision=$expectedRevision }
}
function Start-Process {
    param($FilePath,$WorkingDirectory,$Verb,$WindowStyle,$ArgumentList,[switch]$Wait,[switch]$PassThru,$ErrorAction)
    if ($Verb -ne 'RunAs' -or -not $Wait -or -not $PassThru -or $WindowStyle -ne 'Hidden' -or $ArgumentList -contains '-File') {
        throw 'The protected handoff must await an elevated in-memory runner'
    }
    if ($FilePath -notmatch '\\WindowsPowerShell\\v1\.0\\powershell\.exe$') { throw 'Wrong elevation host' }
    $script:command = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($ArgumentList[-1]))
    if (($ArgumentList -join ' ').Length -gt 30000) { throw 'Encoded runner exceeds the Windows command line limit' }
    $tokens=$null; $errors=$null
    $null=[Management.Automation.Language.Parser]::ParseInput($script:command,[ref]$tokens,[ref]$errors)
    if ($errors.Count) { throw "Invalid UAC handoff: $($errors[0].Message)" }
    $script:handoffs++
    return [pscustomobject]@{ExitCode=0}
}
function Find-WAUProtectedPowerShell7 { 'Invoke-TestApp' }
function Get-WAURelease {
    param($Revision)
    if ($Revision -ne $expectedRevision) { throw 'Revision is not pinned' }
    $file = @{path='WindowsAcolyte.ps1'; sha=(Get-WAUBlobHash $fixture); size=[IO.FileInfo]::new($fixture).Length}
    @{Revision=$Revision; Files=@($file)}
}
function New-WAUProtectedSession {
    [void][IO.Directory]::CreateDirectory($session)
    $session
}
function Remove-WAUProtectedSession {
    param($Path)
    if ($Path -ne $session -or [IO.Path]::GetDirectoryName($Path) -ne $testRoot) { throw 'Wrong test cleanup path' }
    [IO.Directory]::Delete($Path, $true)
}
function Save-WAUDownload {
    param($Uri,$Path)
    $script:downloads++
    if ($Uri -notlike "*/$expectedRevision/WindowsAcolyte.ps1") { throw 'Download not pinned' }
    if ($script:downloadMode -eq 'failed') { throw 'Simulated download failure' }
    [IO.File]::Copy($fixture,$Path,$true)
    if ($script:downloadMode -eq 'corrupt') { [IO.File]::AppendAllText($Path,'corrupt') }
}
function Invoke-TestApp {
    $script:launches++
    if (-not (Test-Path -LiteralPath $session -PathType Container)) { throw 'Runtime missing during app execution' }
    if ((Get-WAUBlobHash (Join-Path $session 'WindowsAcolyte.ps1')) -ne (Get-WAUBlobHash $fixture)) {
        throw 'Unverified app reached execution'
    }
    if (Test-Path -LiteralPath (Join-Path $session 'modules/Extra.ps1')) { throw 'Unmanaged module reached execution' }
    if ($args -notcontains '-LogRoot') { throw 'Persistent log location missing' }
    $global:LASTEXITCODE=0
}

try {
    [void][IO.Directory]::CreateDirectory((Join-Path $cache 'modules'))
    [IO.File]::WriteAllText($fixture,'# trusted')
    $appCache = Join-Path $cache 'WindowsAcolyte.ps1'
    [IO.File]::WriteAllText($appCache,'# altered')
    [IO.File]::WriteAllText((Join-Path $cache 'modules/Extra.ps1'),'throw "unexpected module"')

    Invoke-WAUOnlineRun
    if ($script:syncs -ne 0 -or $script:command -notmatch "Invoke-WAUProtectedSession -Revision ''" -or $script:command -notmatch "FromBase64String\(''\)") { throw 'Online launch tried to use the permanent cache' }
    $null = Invoke-WAULocalStart -InstallPath $cache -OnlyUpdate
    if ($script:handoffs -ne 1 -or $script:syncs -ne 1) { throw 'Update-only requested elevation' }
    Invoke-WAULocalStart -InstallPath $cache
    $cacheArgument = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($cache))
    if ($script:handoffs -ne 2 -or $script:syncs -ne 2 -or $script:command -notmatch "-Revision '$expectedRevision'" -or $script:command -notmatch [regex]::Escape("FromBase64String('$cacheArgument')")) {
        throw 'Installed mode failed to pass the checked revision and cache to the runner'
    }
    'PASS: Online, installed and update-only use the expected handoff and cache policy'

    $script:admin = $true
    Invoke-WAUProtectedSession -Revision $expectedRevision -CachePath $cache
    if ($script:downloads -ne 1 -or $script:launches -ne 1 -or (Test-Path -LiteralPath $session)) { throw 'Corrupt cache was not safely replaced and cleaned' }
    [IO.File]::Copy($fixture,$appCache,$true)
    Invoke-WAUProtectedSession -Revision $expectedRevision -CachePath $cache
    if ($script:downloads -ne 1 -or $script:launches -ne 2 -or (Test-Path -LiteralPath $session)) { throw 'Verified cache was not safely reused' }
    'PASS: Altered cache repaired from the pinned release, extra module ignored, valid cache reused'

    foreach ($mode in @('failed','corrupt')) {
        $script:downloadMode=$mode
        $blocked=$false
        try { Invoke-WAUProtectedSession -Revision $expectedRevision }
        catch {
            if ($_.Exception.Message -notmatch 'Simulated download failure|Release file failed integrity check') { throw }
            $blocked=$true
        }
        if (-not $blocked -or $script:launches -ne 2 -or (Test-Path -LiteralPath $session)) { throw "Failure mode $mode did not block startup and clean up" }
    }
    'PASS: Failed and corrupt downloads block execution and clean up the isolated runtime'
} finally {
    $parent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
    $resolved = [IO.Path]::GetFullPath($testRoot)
    if ([IO.Path]::GetDirectoryName($resolved) -eq $parent -and [IO.Path]::GetFileName($resolved) -match '^WindowsAcolyte-OnlineTest-[0-9a-f]{32}$' -and [IO.Directory]::Exists($resolved)) {
        [IO.Directory]::Delete($resolved, $true)
    }
}
