#Requires -Version 5.1
param([switch]$OnlineInstaller, [switch]$UpdateOnly)

# The desktop link uses Windows PowerShell so Store updates cannot break its target.
# Dot sourcing exposes the updater for tests without installing or launching anything.
function Get-WAUJson {
    param([string]$Uri)
    Invoke-RestMethod -Uri $Uri -Headers @{'User-Agent'='WindowsAcolyte-Updater'; 'Cache-Control'='no-cache'} -TimeoutSec 25 -ErrorAction Stop
}

function Save-WAUDownload {
    param([string]$Uri, [string]$Path)
    Invoke-WebRequest -Uri $Uri -OutFile $Path -UseBasicParsing -Headers @{'User-Agent'='WindowsAcolyte-Updater'; 'Cache-Control'='no-cache'} -TimeoutSec 60 -ErrorAction Stop | Out-Null
}

function Test-WAUManagedPath {
    param([string]$Path)
    # Only application files, never profiles, logs, backups or arbitrary remote paths.
    return $Path -cmatch '^(WindowsAcolyte\.ps1|Start-WindowsAcolyte\.ps1|README\.md|docs/README\.md|modules/[A-Za-z0-9_-]+\.ps1|logo/[A-Za-z0-9_-]+\.(png|ico))$'
}

function Get-WAUBlobHash {
    param([string]$Path)
    $bytes = [IO.File]::ReadAllBytes($Path)
    $header = [Text.Encoding]::ASCII.GetBytes("blob $($bytes.Length)`0")
    $hash = [Security.Cryptography.SHA1]::Create()
    try {
        $null = $hash.TransformBlock($header, 0, $header.Length, $header, 0)
        $null = $hash.TransformFinalBlock($bytes, 0, $bytes.Length)
        return ([BitConverter]::ToString($hash.Hash)).Replace('-', '').ToLowerInvariant()
    } finally { $hash.Dispose() }
}

function Get-WAURelease {
    $api = 'https://api.github.com/repos/ReAlNoMo/WindowsAcolyte'
    $commit = Get-WAUJson "$api/commits/main"
    if ($commit.sha -notmatch '^[0-9a-f]{40}$') { throw 'GitHub returned an invalid commit ID.' }
    $tree = Get-WAUJson "$api/git/trees/$($commit.sha)?recursive=1"
    if ($tree.truncated -ne $false -or -not $tree.tree) { throw 'GitHub returned an incomplete file list.' }
    $files = @($tree.tree | Where-Object { Test-WAUManagedPath $_.path })
    $seen = @{}
    foreach ($file in $files) {
        if ($seen.ContainsKey($file.path) -or $file.type -ne 'blob' -or $file.mode -notin @('100644','100755') -or $file.sha -notmatch '^[0-9a-f]{40}$') {
            throw 'GitHub returned an invalid or duplicate application file.'
        }
        $seen[$file.path] = $true
    }
    foreach ($required in @('WindowsAcolyte.ps1','Start-WindowsAcolyte.ps1','README.md','modules/08-DesktopShortcutCreator.ps1')) {
        if (-not $seen.ContainsKey($required)) { throw "Release is missing required file: $required" }
    }
    return @{Revision=$commit.sha; Files=$files}
}

function Set-WAUStatus {
    param([string]$Text)
    if ($script:WAUStatusLabel) {
        $script:WAUStatusLabel.Text = $Text
        [System.Windows.Forms.Application]::DoEvents()
    }
}

function Test-WAUStagedScripts {
    param([string]$Directory)
    if (-not (Test-Path -LiteralPath $Directory)) { return }
    $files = @(Get-ChildItem -LiteralPath $Directory -Recurse -File -Filter '*.ps1')
    if (-not $files.Count) { return }
    # The app uses PS7 syntax (including null-conditional access). Validate with
    # its actual runtime, not the PS5.1 parser hosting the desktop bootstrap.
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        $parserHost = Find-WAUPowerShell7
        $safeDirectory = $Directory.Replace("'", "''")
        $validation = @'
$ErrorActionPreference = 'Stop'
foreach ($file in Get-ChildItem -LiteralPath '__DIRECTORY__' -Recurse -File -Filter '*.ps1') {
    $tokens=$null; $errors=$null
    $null=[Management.Automation.Language.Parser]::ParseInput([IO.File]::ReadAllText($file.FullName),[ref]$tokens,[ref]$errors)
    if ($errors.Count) { throw ('Invalid PowerShell syntax: ' + $file.Name) }
}
'@
        $validation = $validation.Replace('__DIRECTORY__', $safeDirectory)
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($validation))
        $output = & $parserHost -NoProfile -NonInteractive -EncodedCommand $encoded 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Staged application scripts failed PowerShell 7 validation. $output" }
    } else {
        foreach ($file in $files) {
            $tokens=$null; $errors=$null
            $null=[Management.Automation.Language.Parser]::ParseInput([IO.File]::ReadAllText($file.FullName),[ref]$tokens,[ref]$errors)
            if ($errors.Count) { throw "Downloaded PowerShell file has syntax errors: $($file.Name)" }
        }
    }
    # The starter itself must also remain compatible with its PS5.1 host.
    $starter = Join-Path $Directory 'Start-WindowsAcolyte.ps1'
    if (Test-Path -LiteralPath $starter) {
        $tokens=$null; $errors=$null
        $null=[Management.Automation.Language.Parser]::ParseInput([IO.File]::ReadAllText($starter),[ref]$tokens,[ref]$errors)
        if ($errors.Count) { throw 'Downloaded starter is incompatible with the current host.' }
    }
}

function Sync-WAUInstallation {
    param([Parameter(Mandatory)][string]$InstallPath)
    $InstallPath = [IO.Path]::GetFullPath($InstallPath)
    [void][IO.Directory]::CreateDirectory($InstallPath)
    $lock = $null
    $work = $null
    try {
        # Serialize checks/updates from simultaneous clicks. Never run with a partial update.
        $lock = [IO.File]::Open((Join-Path $InstallPath '.update.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
        Set-WAUStatus 'Checking GitHub for the latest version...'
        $release = Get-WAURelease
        $statePath = Join-Path $InstallPath '.installed-release.json'
        $previous = @()
        if (Test-Path -LiteralPath $statePath) {
            $state = [IO.File]::ReadAllText($statePath) | ConvertFrom-Json -ErrorAction Stop
            $previous = @($state.Files)
            foreach ($path in $previous) {
                if (-not (Test-WAUManagedPath $path)) { throw 'Invalid managed path in local update state.' }
            }
        }
        $work = Join-Path $InstallPath ('.updates/' + [guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $changed = @()
        $paths = @($release.Files | ForEach-Object { $_.path })
        foreach ($file in $release.Files) {
            $destination = Join-Path $InstallPath $file.path
            if ((Test-Path -LiteralPath $destination -PathType Leaf) -and (Get-WAUBlobHash $destination) -eq $file.sha) { continue }
            Set-WAUStatus ("Downloading: " + $file.path)
            $staged = Join-Path (Join-Path $work 'new') $file.path
            [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($staged))
            # Every file comes from the same immutable commit, even if main changes mid-download.
            Save-WAUDownload "https://raw.githubusercontent.com/ReAlNoMo/WindowsAcolyte/$($release.Revision)/$($file.path)" $staged
            if ((Get-WAUBlobHash $staged) -ne $file.sha) { throw "Downloaded file failed integrity check: $($file.path)" }
            $changed += $file.path
        }
        Test-WAUStagedScripts (Join-Path $work 'new')
        $removed = @($previous | Where-Object { $_ -notin $paths })
        $operations = @($changed) + @($removed) + @('.installed-release.json')
        $newState = @{Revision=$release.Revision; CheckedUtc=[DateTime]::UtcNow.ToString('o'); Files=$paths} | ConvertTo-Json -Depth 4
        [IO.File]::WriteAllText((Join-Path $work 'state.json'), $newState)
        # Back up all destinations before mutating any application file.
        $existed = @{}
        foreach ($path in $operations) {
            $destination = Join-Path $InstallPath $path
            $existed[$path] = Test-Path -LiteralPath $destination -PathType Leaf
            if ($existed[$path]) {
                $backup = Join-Path (Join-Path $work 'old') $path
                [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($backup))
                [IO.File]::Copy($destination, $backup)
            }
        }
        Set-WAUStatus 'Applying verified update...'
        $applied = [Collections.Generic.List[string]]::new()
        try {
            foreach ($path in $operations) {
                $destination = Join-Path $InstallPath $path
                [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination))
                # Record first so a partially failed write is also rolled back.
                $applied.Add($path)
                if ($path -eq '.installed-release.json') { [IO.File]::Copy((Join-Path $work 'state.json'), $destination, $true) }
                elseif ($path -in $removed) { [IO.File]::Delete($destination) }
                else {
                    [IO.File]::Copy((Join-Path (Join-Path $work 'new') $path), $destination, $true)
                    $expected = $release.Files | Where-Object path -eq $path
                    if ((Get-WAUBlobHash $destination) -ne $expected.sha) { throw "Installed file failed integrity check: $path" }
                }
            }
        } catch {
            $updateFailure = $_
            $rollbackFailures = @()
            for ($index=$applied.Count-1; $index -ge 0; $index--) {
                $path = $applied[$index]
                try {
                    $destination = Join-Path $InstallPath $path
                    if ($existed[$path]) { [IO.File]::Copy((Join-Path (Join-Path $work 'old') $path), $destination, $true) }
                    else { [IO.File]::Delete($destination) }
                } catch { $rollbackFailures += $path }
            }
            if ($rollbackFailures.Count) {
                $retainedBackup = $work
                $work = $null
                throw "Update failed; rollback incomplete for $($rollbackFailures -join ', '). Recovery files: $retainedBackup. App start blocked."
            }
            throw $updateFailure
        }
        return [pscustomobject]@{Revision=$release.Revision; Updated=$changed.Count; Removed=$removed.Count}
    } finally {
        if ($work -and [IO.Directory]::Exists($work)) {
            # Validate the absolute cleanup target within this installation before recursive deletion.
            $safeRoot = [IO.Path]::GetFullPath((Join-Path $InstallPath '.updates')) + [IO.Path]::DirectorySeparatorChar
            $fullWork = [IO.Path]::GetFullPath($work)
            if ($fullWork.StartsWith($safeRoot, [StringComparison]::OrdinalIgnoreCase)) {
                try { [IO.Directory]::Delete($fullWork, $true) } catch { Write-Warning 'Could not remove temporary update files.' }
            }
        }
        if ($lock) { $lock.Dispose() }
    }
}

function Find-WAUPowerShell7 {
    $candidates = @()
    if ($env:ProgramFiles) { $candidates += (Join-Path $env:ProgramFiles 'PowerShell/7/pwsh.exe') }
    Get-Command pwsh.exe -All -ErrorAction SilentlyContinue | ForEach-Object { $candidates += $_.Source }
    foreach ($candidate in $candidates | Select-Object -Unique) {
        if ((Test-Path -LiteralPath $candidate) -and $candidate -notlike '*\.cache\codex-runtimes\*') {
            try {
                $major = & $candidate -NoProfile -Command '$PSVersionTable.PSVersion.Major' 2>$null
                if ([int]([string]($major | Select-Object -First 1)) -ge 7) { return $candidate }
            } catch {}
        }
    }
    throw 'PowerShell 7 was not found. Install it from https://aka.ms/powershell.'
}

function Invoke-WAULocalStart {
    param([string]$InstallPath, [switch]$OnlyUpdate)
    # Any check/download/apply failure propagates before the launch statement.
    $result = Sync-WAUInstallation -InstallPath $InstallPath
    if ($OnlyUpdate) { return $result }
    $pwsh = Find-WAUPowerShell7
    if ($script:WAUForm) { $script:WAUForm.Hide() }
    & $pwsh -NoProfile -ExecutionPolicy Bypass -STA -File (Join-Path $InstallPath 'WindowsAcolyte.ps1')
    if ($LASTEXITCODE -ne 0) { throw "WindowsAcolyte exited with code $LASTEXITCODE." }
}

if ($MyInvocation.InvocationName -ne '.') {
    $ErrorActionPreference = 'Stop'
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $script:WAUForm = $null
    $script:WAUStatusLabel = $null
    try {
        if (-not $UpdateOnly) {
            Add-Type -AssemblyName System.Windows.Forms
            $script:WAUForm = New-Object System.Windows.Forms.Form
            $script:WAUForm.Text = 'WindowsAcolyte - Update Check'
            $script:WAUForm.Width = 560; $script:WAUForm.Height = 145
            $script:WAUForm.StartPosition = 'CenterScreen'
            $script:WAUForm.FormBorderStyle = 'FixedDialog'
            $script:WAUForm.ControlBox = $false
            $script:WAUStatusLabel = New-Object System.Windows.Forms.Label
            $script:WAUStatusLabel.Dock = 'Fill'
            $script:WAUStatusLabel.Padding = 20
            $script:WAUStatusLabel.Text = 'Checking GitHub before starting WindowsAcolyte...'
            $script:WAUForm.Controls.Add($script:WAUStatusLabel)
            $script:WAUForm.Show()
        }
        # -OnlineInstaller is retained for existing links and uses the same checked update flow.
        Invoke-WAULocalStart -InstallPath (Join-Path $env:LOCALAPPDATA 'WindowsAcolyte') -OnlyUpdate:$UpdateOnly
    } catch {
        if ($UpdateOnly) { Write-Error $_; exit 1 }
        [System.Windows.Forms.MessageBox]::Show("Online check or update failed. WindowsAcolyte was not started.`n`n$($_.Exception.Message)`n`nCheck your internet connection and try again.", 'WindowsAcolyte - Start blocked', 'OK', 'Error') | Out-Null
        exit 1
    } finally {
        if ($script:WAUForm) { $script:WAUForm.Dispose() }
    }
}
