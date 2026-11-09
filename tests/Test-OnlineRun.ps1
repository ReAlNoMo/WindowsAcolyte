# Simulates the elevated process; no real app or privileged operations are started.
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
. (Join-Path $root 'Start-WindowsAcolyte.ps1')
$testRoot=Join-Path ([IO.Path]::GetTempPath()) ('WindowsAcolyte-OnlineTest-'+[guid]::NewGuid().ToString('N'))
$originalLocal=$env:LOCALAPPDATA
[void][IO.Directory]::CreateDirectory($testRoot)
$env:LOCALAPPDATA=$testRoot
$script:session=$null;$script:failSync=$false;$script:failLaunch=$false;$script:launches=0
function Sync-WAUInstallation {
    param($InstallPath)
    $script:session=$InstallPath
    [void][IO.Directory]::CreateDirectory($InstallPath)
    [IO.File]::WriteAllText((Join-Path $InstallPath 'WindowsAcolyte.ps1'),'# simulated app')
    if($script:failSync){throw 'Simulated download failure'}
    return @{Revision='test'}
}
function Find-WAUPowerShell7 {return 'pwsh.exe'}
function Start-Process {
    param($FilePath,$ArgumentList,$Verb,[switch]$Wait,[switch]$PassThru,$ErrorAction)
    $script:launches++
    if(-not $Wait -or -not $PassThru -or $Verb -ne 'RunAs'){throw 'App lifetime is not awaited'}
    if(-not (Test-Path -LiteralPath (Join-Path $script:session 'WindowsAcolyte.ps1'))){throw 'Temporary app missing during launch'}
    if(($ArgumentList -join ' ') -notmatch '-LogRoot'){throw 'Persistent log location missing'}
    if($script:failLaunch){throw 'Simulated elevation cancellation'}
    return [pscustomobject]@{ExitCode=0}
}
try {
    $profile=Join-Path $testRoot 'WindowsAcolyte/GamingOptimizer/profile.json'
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($profile))
    [IO.File]::WriteAllText($profile,'original')
    Invoke-WAUOnlineRun
    if(Test-Path -LiteralPath $script:session){throw 'Temporary app remains after exit'}
    if([IO.File]::ReadAllText($profile) -ne 'original'){throw 'Profile changed'}
    'PASS: temporary copy exists while app runs, then is removed; profile preserved'
    $script:failSync=$true;$before=$script:launches
    try {Invoke-WAUOnlineRun;throw 'Download failure was ignored'} catch {if($_.Exception.Message -ne 'Simulated download failure'){throw}}
    if((Test-Path -LiteralPath $script:session) -or $script:launches -ne $before){throw 'Failed download did not block launch or cleanup'}
    'PASS: download failure blocks launch and cleans temporary files'
    $script:failSync=$false;$script:failLaunch=$true
    try {Invoke-WAUOnlineRun;throw 'Elevation cancellation was ignored'} catch {if($_.Exception.Message -ne 'Simulated elevation cancellation'){throw}}
    if(Test-Path -LiteralPath $script:session){throw 'Temporary app remains after cancellation'}
    'PASS: cancelled elevation cleans temporary files'
} finally {
    $env:LOCALAPPDATA=$originalLocal
    $parent=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
    $resolved=[IO.Path]::GetFullPath($testRoot)
    if($resolved.StartsWith($parent,[StringComparison]::OrdinalIgnoreCase) -and [IO.Path]::GetFileName($resolved).StartsWith('WindowsAcolyte-OnlineTest-')){Remove-Item -LiteralPath $resolved -Recurse -Force}
}
