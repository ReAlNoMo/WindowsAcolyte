# Shortcut overlay configuration. No setting is changed until the user clicks an action.

function Global:SAV-GetPaths {
    $directory = Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) 'WindowsAcolyte\ShortcutArrowOverlay'
    return @{
        Directory = $directory
        Icon = Join-Path $directory 'transparent-arrow.ico'
        Backup = Join-Path $directory 'original-29.json'
        SubKey = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons'
    }
}

function Global:SAV-OpenRegistry {
    $view = if ([Environment]::Is64BitOperatingSystem) { [Microsoft.Win32.RegistryView]::Registry64 } else { [Microsoft.Win32.RegistryView]::Registry32 }
    return [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $view)
}

function Global:SAV-ReadValue {
    $root = SAV-OpenRegistry
    $key = $null
    try {
        $key = $root.OpenSubKey((SAV-GetPaths).SubKey, $false)
        if (-not $key -or $key.GetValueNames() -notcontains '29') {
            return @{Exists=$false; Kind='None'; Data=$null}
        }
        return @{
            Exists=$true
            Kind=$key.GetValueKind('29').ToString()
            Data=$key.GetValue('29', $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        }
    } finally { if ($key) { $key.Dispose() }; $root.Dispose() }
}

function Global:SAV-WriteValue {
    param([Parameter(Mandatory)]$State)
    $root = SAV-OpenRegistry
    $key = $null
    try {
        if ($State.Exists) {
            $kind = [Microsoft.Win32.RegistryValueKind]$State.Kind
            $data = switch ($kind) {
                'String' { [string]$State.Data }
                'ExpandString' { [string]$State.Data }
                'MultiString' { ,([string[]]$State.Data) }
                'DWord' { [int]$State.Data }
                'QWord' { [long]$State.Data }
                'Binary' { ,([byte[]]$State.Data) }
                'None' { ,([byte[]]$State.Data) }
                default { throw "Unsupported original registry type: $kind" }
            }
            $key = $root.CreateSubKey((SAV-GetPaths).SubKey, $true)
            $key.SetValue('29', $data, $kind)
        } else {
            $key = $root.OpenSubKey((SAV-GetPaths).SubKey, $true)
            if ($key) { $key.DeleteValue('29', $false) }
        }
    } finally { if ($key) { $key.Dispose() }; $root.Dispose() }
}

function Global:SAV-GetIconBytes {
    # Real transparent 32-bit ICO frames with transparent AND masks, not a DLL index.
    $sizes = @(16,24,32,48,64,128,256)
    $stream = [System.IO.MemoryStream]::new()
    $writer = [System.IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]$sizes.Count)
        $offset = 6 + 16 * $sizes.Count
        foreach ($size in $sizes) {
            $maskSize = [int]([math]::Ceiling($size / 32.0) * 4 * $size)
            $length = 40 + $size * $size * 4 + $maskSize
            $dimension = if ($size -eq 256) { 0 } else { $size }
            $writer.Write([byte]$dimension); $writer.Write([byte]$dimension)
            $writer.Write([byte]0); $writer.Write([byte]0)
            $writer.Write([uint16]1); $writer.Write([uint16]32)
            $writer.Write([uint32]$length); $writer.Write([uint32]$offset)
            $offset += $length
        }
        foreach ($size in $sizes) {
            $pixels = $size * $size * 4
            $maskSize = [int]([math]::Ceiling($size / 32.0) * 4 * $size)
            $writer.Write([uint32]40); $writer.Write([int]$size); $writer.Write([int]($size * 2))
            $writer.Write([uint16]1); $writer.Write([uint16]32); $writer.Write([uint32]0)
            $writer.Write([uint32]($pixels + $maskSize))
            1..4 | ForEach-Object { $writer.Write([uint32]0) }
            $writer.Write([byte[]]::new($pixels))
            $mask = [byte[]]::new($maskSize)
            for ($index=0; $index -lt $mask.Length; $index++) { $mask[$index] = 255 }
            $writer.Write($mask)
        }
        return ,$stream.ToArray()
    } finally { $writer.Dispose(); $stream.Dispose() }
}

function Global:SAV-TestIcon {
    $path = (SAV-GetPaths).Icon
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $false }
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $expected = [BitConverter]::ToString($sha.ComputeHash([byte[]](SAV-GetIconBytes))).Replace('-','') }
    finally { $sha.Dispose() }
    return ((Get-FileHash -LiteralPath $path -Algorithm SHA256 -EA Stop).Hash -eq $expected)
}

function Global:SAV-PrepareDirectory {
    $paths = SAV-GetPaths
    $directory = $paths.Directory
    foreach ($path in @((Split-Path -Parent $directory),$directory,$paths.Icon,$paths.Backup)) {
        if (Test-Path -LiteralPath $path) {
            if ((Get-Item -LiteralPath $path -Force -EA Stop).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Managed asset path is a link/junction; refusing elevated writes: $path"
            }
        }
    }
    if (-not (Test-Path -LiteralPath $directory)) { New-Item -ItemType Directory -Path $directory -Force -EA Stop | Out-Null }
    # All users can read the system-wide icon; only administrators/SYSTEM can modify it or the backup.
    $acl = [System.Security.AccessControl.DirectorySecurity]::new()
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($entry in @(@('S-1-5-18','FullControl'),@('S-1-5-32-544','FullControl'),@('S-1-5-32-545','ReadAndExecute'))) {
        $sid = [System.Security.Principal.SecurityIdentifier]::new($entry[0])
        $rule = [System.Security.AccessControl.FileSystemAccessRule]::new($sid, $entry[1], 'ContainerInherit,ObjectInherit', 'None', 'Allow')
        $acl.AddAccessRule($rule)
    }
    Set-Acl -LiteralPath $directory -AclObject $acl -EA Stop
}

function Global:SAV-ReadBackup {
    $paths = SAV-GetPaths
    if (-not (Test-Path -LiteralPath $paths.Backup -PathType Leaf)) { return $null }
    if ((Get-Item -LiteralPath $paths.Backup -Force -EA Stop).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw 'Original-value backup must be a regular file, not a link.'
    }
    $backup = Get-Content -LiteralPath $paths.Backup -Raw -EA Stop | ConvertFrom-Json -EA Stop
    if ($backup.Version -ne 1 -or $backup.SubKey -cne $paths.SubKey -or
        $backup.Previous.Exists -isnot [bool] -or
        ($backup.Previous.Exists -and $backup.Previous.Kind -notin @('String','ExpandString','MultiString','DWord','QWord','Binary','None'))) {
        throw 'Invalid original-value backup. No registry change was made.'
    }
    return $backup
}

function Global:SAV-SaveBackup {
    $paths = SAV-GetPaths
    if (Test-Path -LiteralPath $paths.Backup) { SAV-ReadBackup | Out-Null; return }
    $backup = @{Version=1;SubKey=$paths.SubKey;CreatedUtc=[DateTime]::UtcNow.ToString('o');Previous=(SAV-ReadValue)}
    $json = $backup | ConvertTo-Json -Depth 5
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($json)
    $file = [IO.File]::Open($paths.Backup, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $file.Write($bytes,0,$bytes.Length); $file.Flush($true) } finally { $file.Dispose() }
    SAV-ReadBackup | Out-Null
}

function Global:SAV-GetState {
    $paths = SAV-GetPaths
    $value = SAV-ReadValue
    $iconValid = SAV-TestIcon
    $managedValue = "$($paths.Icon),0"
    $owned = $value.Exists -and $value.Kind -eq 'String' -and $value.Data -ceq $managedValue
    $backup = SAV-ReadBackup
    return @{
        Value=$value; IconValid=$iconValid; Configured=($owned -and $iconValid)
        RepairNeeded=($owned -and -not $iconValid); BackupAvailable=($null -ne $backup)
    }
}

function Global:SAV-HideArrows {
    $state = SAV-GetState
    if ($state.Configured) { return $false }
    SAV-PrepareDirectory
    SAV-SaveBackup
    $paths = SAV-GetPaths
    if (-not $state.IconValid) { [IO.File]::WriteAllBytes($paths.Icon, [byte[]](SAV-GetIconBytes)) }
    if (-not (SAV-TestIcon)) { throw 'Transparent icon validation failed; registry was not changed.' }
    SAV-WriteValue @{Exists=$true;Kind='String';Data="$($paths.Icon),0"}
    if (-not (SAV-GetState).Configured) { throw 'Registry/icon verification failed after applying.' }
    return $true
}

function Global:SAV-RestoreOriginal {
    $paths = SAV-GetPaths
    $backup = SAV-ReadBackup
    if (-not $backup) { throw 'No original-value backup exists. No registry value was removed.' }
    $current = SAV-ReadValue
    if (-not ($current.Exists -and $current.Kind -eq 'String' -and $current.Data -ceq "$($paths.Icon),0")) {
        throw 'Value 29 was changed externally. Restore stopped to avoid replacing another customization.'
    }
    SAV-WriteValue $backup.Previous
    $restored = SAV-ReadValue
    # Compare fields independently; hash table / JSON object property order can differ.
    if ($restored.Exists -ne $backup.Previous.Exists -or $restored.Kind -ne $backup.Previous.Kind -or
        (ConvertTo-Json -InputObject $restored.Data -Compress) -ne (ConvertTo-Json -InputObject $backup.Previous.Data -Compress)) {
        throw 'Original registry value could not be verified after restore.'
    }
    # Retire this backup so a later Apply captures the then-current baseline.
    $archive = Join-Path $paths.Directory ('restored-29-{0}-{1}.json' -f (Get-Date -Format 'yyyyMMdd-HHmmss'),[guid]::NewGuid().ToString('N'))
    Move-Item -LiteralPath $paths.Backup -Destination $archive -EA Stop
    return $true
}

function Global:SAV-InitializeShellApi {
    if ('WindowsAcolyte.ShortcutShell' -as [type]) { return }
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace WindowsAcolyte {
    public static class ShortcutShell {
        [DllImport("user32.dll")] public static extern IntPtr GetShellWindow();
        [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr handle, out uint id);
    }
}
'@ -EA Stop
}

function Global:SAV-GetOwnExplorer {
    SAV-InitializeShellApi
    $handle = [WindowsAcolyte.ShortcutShell]::GetShellWindow()
    if ($handle -eq [IntPtr]::Zero) { return $null }
    [uint32]$explorerId = 0
    [void][WindowsAcolyte.ShortcutShell]::GetWindowThreadProcessId($handle,[ref]$explorerId)
    $process = Get-Process -Id $explorerId -EA SilentlyContinue
    if (-not $process) { return $null }
    $sessionId = (Get-Process -Id $PID).SessionId
    if ($process.ProcessName -ne 'explorer' -or $process.SessionId -ne $sessionId) { throw 'Shell is not Explorer in the current session.' }
    $cim = Get-CimInstance Win32_Process -Filter "ProcessId=$explorerId" -EA Stop
    $owner = Invoke-CimMethod -InputObject $cim -MethodName GetOwnerSid -EA Stop
    if ($owner.ReturnValue -ne 0 -or $owner.Sid -ne [Security.Principal.WindowsIdentity]::GetCurrent().User.Value) {
        throw 'Explorer belongs to another user. Sign out/in to refresh icons.'
    }
    return $process
}

function Global:SAV-RestartExplorer {
    $process = SAV-GetOwnExplorer
    if (-not $process) { throw 'No Explorer shell found. Start Explorer or sign out/in to refresh icons.' }
    $oldId = $process.Id
    Stop-Process -Id $oldId -Force -EA Stop
    # Windows normally restarts the shell itself. Avoid launching a second Explorer.
    for ($attempt=0; $attempt -lt 20; $attempt++) {
        Start-Sleep -Milliseconds 250
        $running = SAV-GetOwnExplorer
        if ($running -and $running.Id -ne $oldId) { return $running.Id }
    }
    Start-Process -FilePath (Join-Path $env:SystemRoot 'explorer.exe') -EA Stop | Out-Null
    for ($attempt=0; $attempt -lt 20; $attempt++) {
        Start-Sleep -Milliseconds 250
        $running = SAV-GetOwnExplorer
        if ($running -and $running.Id -ne $oldId) { return $running.Id }
    }
    throw 'Configuration saved, but Explorer restart could not be verified. Sign out/in to refresh icons.'
}

Register-PowerToolsModule `
    -Id 'shortcut-arrow-visibility' `
    -Name 'Shortcut Arrow Visibility' `
    -Description 'Hide shortcut-arrow overlays with a transparent icon, original-value backup and Explorer restart.' `
    -Category 'Windows Tweaks' `
    -RequiresAdmin $true `
    -Show {
    [xml]$viewXaml = @'
<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/><RowDefinition Height="*"/>
    </Grid.RowDefinitions>
    <Border Grid.Row="0" Background="{DynamicResource DynTileBg}" BorderBrush="{DynamicResource DynTileBorder}"
            BorderThickness="1.5" CornerRadius="10" Padding="16" Margin="0,0,0,12">
        <StackPanel>
            <TextBlock Text="SHORTCUT ARROWS" Foreground="{DynamicResource DynSectionLabel}" FontSize="10" FontWeight="Bold" Margin="0,0,0,6"/>
            <TextBlock Foreground="{DynamicResource DynTextDark}" FontSize="13" TextWrapping="Wrap"
                       Text="Hide the small arrow overlay, keeping shortcut icons and targets intact. Uses REG_SZ 29 under HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons."/>
            <TextBlock Foreground="{DynamicResource DynTextMuted}" FontSize="12" TextWrapping="Wrap" Margin="0,8,0,0"
                       Text="System-wide configuration for all users. Your Explorer shell restarts after confirmation; open Explorer windows can close. Finish file operations first. Other signed-in users need to restart Explorer or sign out/in separately. This registry customization may behave differently after Windows updates."/>
        </StackPanel>
    </Border>
    <Border Grid.Row="1" Background="{DynamicResource DynTileBg}" BorderBrush="{DynamicResource DynTileBorder}"
            BorderThickness="1.5" CornerRadius="10" Padding="16" Margin="0,0,0,12">
        <StackPanel>
            <TextBlock x:Name="StatusText" Foreground="{DynamicResource DynTextDark}" FontSize="14" FontWeight="SemiBold" TextWrapping="Wrap"/>
            <TextBlock x:Name="ValueText" Foreground="{DynamicResource DynTextMid}" FontSize="12" TextWrapping="Wrap" Margin="0,8,0,0"/>
            <TextBlock x:Name="AssetText" Foreground="{DynamicResource DynTextMuted}" FontSize="12" TextWrapping="Wrap" Margin="0,6,0,0"/>
            <TextBlock Foreground="{DynamicResource DynTextMuted}" FontSize="12" TextWrapping="Wrap" Margin="0,6,0,0"
                       Text="Configured verifies registry + icon file, not the visual result. Restore reinstates your original value/type; if none existed, only value 29 is removed. Other Shell Icons entries stay intact. Do not delete the ProgramData icon while this setting is used."/>
        </StackPanel>
    </Border>
    <WrapPanel Grid.Row="2" Margin="0,0,0,12">
        <Button x:Name="HideBtn" Content="Hide Arrows" Style="{DynamicResource PrimaryButton}" MinWidth="130" MinHeight="40" Padding="14,6" Margin="0,0,8,8"/>
        <Button x:Name="RestoreBtn" Content="Restore Previous Setting" Style="{DynamicResource SecondaryButton}" MinHeight="40" Padding="14,6" Margin="0,0,8,8"/>
        <Button x:Name="RecheckBtn" Content="Recheck" Style="{DynamicResource SecondaryButton}" MinHeight="40" Padding="14,6" Margin="0,0,8,8"/>
        <Button x:Name="RestartBtn" Content="Restart Explorer" Style="{DynamicResource SecondaryButton}" MinHeight="40" Padding="14,6" Margin="0,0,0,8"/>
    </WrapPanel>
    <Border Grid.Row="3" Background="{DynamicResource DynTileBg}" BorderBrush="{DynamicResource DynTileBorder}"
            BorderThickness="1.5" CornerRadius="10" Padding="12" MinHeight="110">
        <TextBox x:Name="LogText" Text="Ready. No setting changed." IsReadOnly="True" TextWrapping="Wrap"
                 Background="Transparent" Foreground="{DynamicResource DynTextMid}" BorderThickness="0"
                 VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="12"/>
    </Border>
</Grid>
'@
    $reader = [System.Xml.XmlNodeReader]::new($viewXaml)
    $view = [Windows.Markup.XamlReader]::Load($reader)
    foreach ($style in @('PrimaryButton','SecondaryButton')) { $view.Resources.Add($style,(Get-PowerToolsWindow).FindResource($style)) }
    $script:SAV_controls = @{}
    foreach ($name in @('StatusText','ValueText','AssetText','HideBtn','RestoreBtn','RecheckBtn','RestartBtn','LogText')) { $script:SAV_controls[$name] = $view.FindName($name) }

    function Global:SAV-Log {
        param([string]$Message)
        $script:SAV_controls.LogText.AppendText("`n[$(Get-Date -Format HH:mm:ss)] $Message")
        $script:SAV_controls.LogText.ScrollToEnd()
    }
    function Global:SAV-Refresh {
        try {
            $state = SAV-GetState
            $script:SAV_controls.StatusText.Text = if ($state.Configured) {'Configured: arrow overlay is transparent'} elseif ($state.RepairNeeded) {'Repair needed: managed transparent icon is missing or changed'} elseif ($state.Value.Exists) {'Custom overlay value exists; original setting will be backed up'} else {'Not configured: no value 29 exists'}
            $script:SAV_controls.ValueText.Text = if ($state.Value.Exists) {"29 ($($state.Value.Kind)): $($state.Value.Data)"} else {'29: absent'}
            $script:SAV_controls.AssetText.Text = "Icon: $((SAV-GetPaths).Icon)`nIcon validated: $($state.IconValid) | Original backup available: $($state.BackupAvailable)"
            $script:SAV_controls.HideBtn.IsEnabled = -not $state.Configured
            $script:SAV_controls.RestoreBtn.IsEnabled = $state.BackupAvailable -and $state.Value.Exists -and $state.Value.Kind -eq 'String' -and $state.Value.Data -ceq "$((SAV-GetPaths).Icon),0"
        } catch {
            $script:SAV_controls.StatusText.Text = "Check failed: $($_.Exception.Message)"
            $script:SAV_controls.HideBtn.IsEnabled = $false
            $script:SAV_controls.RestoreBtn.IsEnabled = $false
            SAV-Log $_.Exception.Message
        }
    }
    function Global:SAV-RunAction {
        param([ValidateSet('Hide','Restore','Restart')][string]$Action)
        $answer = [System.Windows.MessageBox]::Show("$Action shortcut-arrow setting?`n`nExplorer will restart in your current session. Open Explorer windows may close; finish copy/move operations first. Registry changes apply system-wide.`n`nContinue?",'Shortcut Arrow Visibility',[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Warning)
        if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
        foreach ($name in @('HideBtn','RestoreBtn','RecheckBtn','RestartBtn')) { $script:SAV_controls[$name].IsEnabled = $false }
        try {
            # Verify we can identify our own shell before making a registry change.
            if (-not (SAV-GetOwnExplorer)) { throw 'No current-user Explorer shell found. No registry change was made.' }
            $changed = switch ($Action) { 'Hide' {SAV-HideArrows} 'Restore' {SAV-RestoreOriginal} 'Restart' {$true} }
            if ($changed) {
                SAV-Log "Action $Action verified. Restarting current-user Explorer..."
                $newId = SAV-RestartExplorer
                SAV-Log "Explorer restart verified (PID $newId). Inspect a shortcut visually; if cached, sign out/in."
            } else { SAV-Log 'Already configured; no registry change or Explorer restart needed.' }
        } catch { SAV-Log "Action failed: $($_.Exception.Message)" }
        finally {
            $script:SAV_controls.RecheckBtn.IsEnabled = $true
            $script:SAV_controls.RestartBtn.IsEnabled = $true
            SAV-Refresh
        }
    }
    $script:SAV_controls.HideBtn.Add_Click({ SAV-RunAction Hide })
    $script:SAV_controls.RestoreBtn.Add_Click({ SAV-RunAction Restore })
    $script:SAV_controls.RestartBtn.Add_Click({ SAV-RunAction Restart })
    $script:SAV_controls.RecheckBtn.Add_Click({ SAV-Refresh })
    SAV-Refresh
    return $view
}
