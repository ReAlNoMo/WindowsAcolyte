# Module: Windows 11 Gaming Optimizer v2.1
# Comprehensive gaming tweaks with profile support, backup, and detailed info.

Register-PowerToolsModule `
    -Id            "gaming-optimizer" `
    -Name          "Windows 11 Gaming Optimizer" `
    -Description   "Review gaming settings with plain-English explanations, technical details and clear configuration status." `
    -Category      "Performance" `
    -RequiresAdmin $true `
    -Show          {

    [xml]$viewXaml = @"
<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- ROW 0: Hardware Info -->
    <Border Grid.Row="0" x:Name="HWInfoBorder"
            BorderThickness="1.5" CornerRadius="8" Padding="12,8" Margin="0,0,0,6">
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0">
                <TextBlock Text="DETECTED HARDWARE" Foreground="{DynamicResource DynSectionLabel}" FontSize="9"
                           FontWeight="Bold" Margin="0,0,0,2"/>
                <TextBlock x:Name="HardwareText" FontSize="11" TextWrapping="Wrap" Text="Detecting..."/>
            </StackPanel>
        </Grid>
    </Border>

    <!-- ROW 1: Backup Options (intentional warning colors) -->
    <Border Grid.Row="1" Background="{DynamicResource DynAccentSoft}" BorderBrush="{DynamicResource DynAccent}"
            BorderThickness="1.5" CornerRadius="8" Padding="12,6" Margin="0,0,0,6">
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" Text="BACKUP:" Foreground="{DynamicResource DynTextDark}" FontSize="10"
                       FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,12,0"/>
            <CheckBox Grid.Column="1" x:Name="CbRestorePoint"
                      Content="Create Restore Point" IsChecked="True"
                      FontSize="11" Foreground="{DynamicResource DynTextDark}" VerticalAlignment="Center"/>
            <CheckBox Grid.Column="2" x:Name="CbRegBackup"
                      Content="Export Registry (.reg)" IsChecked="True"
                      FontSize="11" Foreground="{DynamicResource DynTextDark}" VerticalAlignment="Center"/>
            <CheckBox Grid.Column="3" x:Name="CbAutoReboot"
                      Content="Prompt for Reboot" IsChecked="True"
                      FontSize="11" Foreground="{DynamicResource DynTextDark}" VerticalAlignment="Center"/>
        </Grid>
    </Border>

    <!-- ROW 2: Selection toolbar; wraps instead of hiding controls at narrow widths. -->
    <WrapPanel Grid.Row="2" Margin="0,0,0,8">
        <TextBlock Text="SELECT CHANGES:" Foreground="{DynamicResource DynSectionLabel}" FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,8,6"/>
        <Button x:Name="SelectAllBtn" Content="All" Style="{DynamicResource SecondaryButton}" Padding="10,5" FontSize="11" Margin="0,0,4,6"/>
        <Button x:Name="SelectMissingBtn" Content="Missing Only" Style="{DynamicResource SecondaryButton}" Padding="10,5" FontSize="11" Margin="0,0,4,6"/>
        <Button x:Name="SelectSafeBtn" Content="Low Risk Only" Style="{DynamicResource SecondaryButton}" Padding="10,5" FontSize="11" Margin="0,0,4,6"/>
        <Button x:Name="SelectNoneBtn" Content="None" Style="{DynamicResource SecondaryButton}" Padding="10,5" FontSize="11" Margin="0,0,12,6"/>
        <Button x:Name="LoadProfileBtn" Content="Load Profile" Style="{DynamicResource SecondaryButton}" Padding="10,5" FontSize="11" Margin="0,0,4,6"/>
        <Button x:Name="SaveProfileBtn" Content="Save Profile" Style="{DynamicResource SecondaryButton}" Padding="10,5" FontSize="11" Margin="0,0,4,6"/>
    </WrapPanel>
    <!-- ROW 3: TWEAK LIST -->
    <Border Grid.Row="3" x:Name="TweakListBorder"
            BorderThickness="1.5" CornerRadius="8" Margin="0,0,0,6">
        <ItemsControl x:Name="TweakList" Margin="6,6,6,6"/>
    </Border>

    <!-- ROW 4: Estimate bar -->
    <Border Grid.Row="4" x:Name="EstimateBar"
            BorderThickness="1" CornerRadius="6" Padding="12,6" Margin="0,6,0,6">
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0" Margin="0,0,12,0">
                <TextBlock x:Name="EstimateText" FontSize="11" TextWrapping="Wrap"
                           Text="No changes selected. Read the descriptions and choose only what you need."/>
                <TextBlock x:Name="ImpactText" FontSize="11" TextWrapping="Wrap" Margin="0,4,0,0"
                           Foreground="{DynamicResource DynTextDark}"
                           Text="APPLIED = configuration verified. Reboot-marked settings may not be effective until restart."/>
            </StackPanel>
            <TextBlock Grid.Column="1" Text="Details = plain-English + technical explanation"
                       Foreground="{DynamicResource DynTextMuted}" FontSize="10" FontStyle="Italic" VerticalAlignment="Center"/>
        </Grid>
    </Border>

    <!-- ROW 5: Action buttons -->
    <Grid Grid.Row="5" Margin="0,0,0,6">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="140"/>
            <ColumnDefinition Width="180"/>
        </Grid.ColumnDefinitions>
        <Button Grid.Column="0" x:Name="ApplyBtn" Content="Apply Selected"
                Style="{DynamicResource PrimaryButton}" Height="40" FontSize="13"
                Margin="0,0,6,0" IsEnabled="False"/>
        <Button Grid.Column="1" x:Name="RecheckBtn" Content="Recheck All"
                Style="{DynamicResource SecondaryButton}" Height="40" FontSize="11" Margin="0,0,6,0"/>
        <Button Grid.Column="2" x:Name="RevertBtn" Content="Reset Managed Settings"
                Style="{DynamicResource SecondaryButton}" Height="40" FontSize="11"/>
    </Grid>

    <!-- ROW 6: Activity Log (fixed height) -->
    <Border Grid.Row="6" x:Name="LogAreaBorder"
            BorderThickness="1.5" CornerRadius="8" Height="140">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <Grid Grid.Row="0" Margin="12,6,12,2">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Text="ACTIVITY LOG" Foreground="{DynamicResource DynSectionLabel}" FontSize="9"
                           FontWeight="Bold" VerticalAlignment="Center"/>
                <Button x:Name="ClearLogBtn" Grid.Column="1" Content="Clear"
                        Style="{DynamicResource SecondaryButton}" Padding="8,3" FontSize="10"/>
            </Grid>
            <ScrollViewer Grid.Row="1" x:Name="LogScroller" VerticalScrollBarVisibility="Auto">
                <TextBlock x:Name="LogBox"
                           FontFamily="Cascadia Code, Consolas, Courier New"
                           FontSize="10" Padding="12,2,12,8" TextWrapping="Wrap"
                           LineHeight="16" Text="Ready. Detecting hardware and checking current status..."/>
            </ScrollViewer>
        </Grid>
    </Border>
</Grid>
"@

    $win    = Get-PowerToolsWindow
    $reader = New-Object System.Xml.XmlNodeReader $viewXaml
    $view   = [Windows.Markup.XamlReader]::Load($reader)

    foreach ($k in @("PrimaryButton","SecondaryButton")) {
        $view.Resources.Add($k, $win.FindResource($k))
    }

    $script:GO_hwText          = $view.FindName("HardwareText")
    $script:GO_hwInfoBorder    = $view.FindName("HWInfoBorder")
    $script:GO_cbRestore       = $view.FindName("CbRestorePoint")
    $script:GO_cbRegBkp        = $view.FindName("CbRegBackup")
    $script:GO_cbAutoReb       = $view.FindName("CbAutoReboot")
    $script:GO_tweakList       = $view.FindName("TweakList")
    $script:GO_tweakListBorder = $view.FindName("TweakListBorder")
    $script:GO_estimateBar     = $view.FindName("EstimateBar")
    $script:GO_estimate        = $view.FindName("EstimateText")
    $script:GO_impactText      = $view.FindName("ImpactText")
    $script:GO_logAreaBorder   = $view.FindName("LogAreaBorder")
    $script:GO_applyBtn        = $view.FindName("ApplyBtn")
    $script:GO_recheckBtn      = $view.FindName("RecheckBtn")
    $script:GO_revertBtn       = $view.FindName("RevertBtn")
    $script:GO_selAll          = $view.FindName("SelectAllBtn")
    $script:GO_selMissing      = $view.FindName("SelectMissingBtn")
    $script:GO_selSafe         = $view.FindName("SelectSafeBtn")
    $script:GO_selNone         = $view.FindName("SelectNoneBtn")
    $script:GO_loadProfBtn     = $view.FindName("LoadProfileBtn")
    $script:GO_saveProfBtn     = $view.FindName("SaveProfileBtn")
    $script:GO_clearLog        = $view.FindName("ClearLogBtn")
    $script:GO_logBox          = $view.FindName("LogBox")
    $script:GO_logScroller     = $view.FindName("LogScroller")
    $script:GO_initText        = "Ready. Detecting hardware and checking current status..."
    $script:GO_checkboxes      = @{}
    $script:GO_detailWindows   = @{}
    $script:GO_profilePath     = Join-Path $env:LOCALAPPDATA "WindowsAcolyte\GamingOptimizer"
    if (-not (Test-Path $script:GO_profilePath)) { New-Item -ItemType Directory -Path $script:GO_profilePath -Force | Out-Null }

    # Apply theme-aware colors
    $script:GO_hwInfoBorder.Background     = $Global:PTS_Brush["Surface"]
    $script:GO_hwInfoBorder.BorderBrush    = $Global:PTS_Brush["Border"]
    $script:GO_hwText.Foreground           = $Global:PTS_Brush["TextDark"]
    $script:GO_tweakListBorder.Background  = $Global:PTS_Brush["Surface"]
    $script:GO_tweakListBorder.BorderBrush = $Global:PTS_Brush["Border"]
    $script:GO_estimateBar.Background      = $Global:PTS_Brush["LogBg"]
    $script:GO_estimateBar.BorderBrush     = $Global:PTS_Brush["LogBorder"]
    $script:GO_estimate.Foreground         = $Global:PTS_Brush["TextDark"]
    $script:GO_logAreaBorder.Background    = $Global:PTS_Brush["LogBg"]
    $script:GO_logAreaBorder.BorderBrush   = $Global:PTS_Brush["LogBorder"]
    $script:GO_logBox.Foreground           = $Global:PTS_Brush["TextMuted"]


    function Global:GO-AddLog {
        param([string]$Msg, [string]$Type = "INFO")
        $ts  = Get-Date -Format "HH:mm:ss"
        $tag = switch ($Type) { "OK"{"[OK]  "} "FAIL"{"[FAIL]"} "WARN"{"[WARN]"} default{"[INFO]"} }
        $entry = "[$ts]  $tag  $Msg`n"
        if ($script:GO_logBox.Text -eq $script:GO_initText) { $script:GO_logBox.Text = $entry }
        else { $script:GO_logBox.Text += $entry }
        $script:GO_logScroller.Dispatcher.Invoke([action]{ $script:GO_logScroller.ScrollToEnd() })
    }

    function Global:GO-GetReg {
        param($p,$n)
        try { return (Get-ItemProperty -LiteralPath $p -Name $n -EA Stop).$n }
        catch {
            if ($_.CategoryInfo.Category -in @('ObjectNotFound','InvalidArgument')) { return $null }
            throw
        }
    }
    function Global:GO-SetDW   { param($p,$n,$v) if(-not(Test-Path $p)){New-Item -Path $p -Force -EA Stop|Out-Null}; Set-ItemProperty -Path $p -Name $n -Value $v -Type DWord -Force -EA Stop }
    function Global:GO-SetStr  { param($p,$n,$v) if(-not(Test-Path $p)){New-Item -Path $p -Force -EA Stop|Out-Null}; Set-ItemProperty -Path $p -Name $n -Value $v -Type String -Force -EA Stop }
    function Global:GO-DelReg {
        param($p,$n)
        if (Test-Path -LiteralPath $p) {
            $key = Get-Item -LiteralPath $p -EA Stop
            if ($key.GetValueNames() -contains $n) { Remove-ItemProperty -LiteralPath $p -Name $n -Force -EA Stop }
        }
    }

    function Global:GO-InvokeNative {
        param([string]$FilePath, [string[]]$Arguments)
        $ErrorActionPreference = 'Stop'
        $output = & $FilePath @Arguments 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "$FilePath failed (exit $LASTEXITCODE): $($output -join ' ')"
        }
        return $output
    }

    function Global:GO-GetGamingAdapters {
        # Active physical Ethernet and Wi-Fi, excluding virtual/VPN adapters.
        return @(Get-NetAdapter -Physical -EA Stop | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceType -in @(6,71) })
    }

    function Global:GO-TestTCPSettings {
        $tcp = Get-NetTCPSetting -SettingName Internet -EA Stop
        $offload = Get-NetOffloadGlobalSetting -EA Stop
        return ($tcp.AutoTuningLevelLocal -eq 'Normal' -and $tcp.EcnCapability -eq 'Disabled' -and
                $tcp.Timestamps -eq 'Disabled' -and $offload.ReceiveSideScaling -eq 'Enabled' -and
                $offload.ReceiveSegmentCoalescing -eq 'Disabled')
    }

    function Global:GO-GetUsbBackupPath {
        param([ValidateRange(30,36)][int]$Id)
        $file = if ($Id -in @(32,33,35,36)) { "input-original-$Id-$(GO-GetInputUserSid).json" } else { "usb-original-$Id.json" }
        return (Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) "WindowsAcolyte\GamingOptimizer\$file")
    }

    function Global:GO-ReadUsbBackup {
        param([ValidateRange(30,36)][int]$Id)
        $path = GO-GetUsbBackupPath $Id
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
        $backup = Get-Content -LiteralPath $path -Raw -EA Stop | ConvertFrom-Json -EA Stop
        if ($backup.Version -ne 1 -or $backup.Id -ne $Id) { throw "Invalid optional-setting backup: $path" }
        if ($Id -eq 30) {
            if ($backup.State.Exists -isnot [bool] -or ($backup.State.Exists -and
                $backup.State.Kind -notin @('String','ExpandString','MultiString','DWord','QWord','Binary','None'))) {
                throw 'Invalid original USB registry state.'
            }
        } elseif ($Id -eq 31) {
            $names = @{}
            foreach ($entry in $backup.Entries) {
                if ($entry.Enabled -isnot [bool] -or $entry.DeviceId -notmatch '^USB\\ROOT_HUB[^\\]*\\' -or
                    $entry.InstanceName -notmatch ('^' + [regex]::Escape($entry.DeviceId) + '_\d+$') -or $names.ContainsKey($entry.InstanceName)) {
                    throw 'Invalid or ambiguous USB hub backup entry.'
                }
                $names[$entry.InstanceName] = $true
            }
            if ($names.Count -eq 0) { throw 'USB hub backup is empty.' }
        } elseif ($Id -eq 34) {
            $plans = @{}
            foreach ($plan in $backup.Plans) {
                if ($plan.Guid -notmatch '^[a-fA-F0-9]{8}(-[a-fA-F0-9]{4}){3}-[a-fA-F0-9]{12}$' -or
                    $plans.ContainsKey($plan.Guid) -or ($plan.AC -isnot [long] -and $plan.AC -isnot [int]) -or
                    ($plan.DC -isnot [long] -and $plan.DC -isnot [int]) -or $plan.AC -notin @(0,1) -or $plan.DC -notin @(0,1)) {
                    throw 'Invalid USB power-plan baseline.'
                }
                $plans[$plan.Guid] = $true
            }
            if ($plans.Count -eq 0) { throw 'USB power-plan backup is empty.' }
        } else {
            if ($backup.UserSid -ne (GO-GetInputUserSid)) { throw 'Input baseline belongs to another Windows user.' }
            GO-ValidateInputState $Id $backup.State
        }
        return $backup
    }

    function Global:GO-WriteUsbBackup {
        param([ValidateRange(30,36)][int]$Id, $Backup)
        $path = GO-GetUsbBackupPath $Id
        $directory = Split-Path -Parent $path
        foreach ($asset in @((Split-Path -Parent $directory),$directory,$path)) {
            if ((Test-Path -LiteralPath $asset) -and ((Get-Item -LiteralPath $asset -Force -EA Stop).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                throw "USB backup path must not be a link/junction: $asset"
            }
        }
        if (-not (Test-Path -LiteralPath $directory)) { New-Item -ItemType Directory -Path $directory -Force -EA Stop | Out-Null }
        $acl = [Security.AccessControl.DirectorySecurity]::new()
        $acl.SetAccessRuleProtection($true,$false)
        foreach ($rule in @(@('S-1-5-18','FullControl'),@('S-1-5-32-544','FullControl'),@('S-1-5-32-545','ReadAndExecute'))) {
            $sid = [Security.Principal.SecurityIdentifier]::new($rule[0])
            $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($sid,$rule[1],'ContainerInherit,ObjectInherit','None','Allow'))
        }
        Set-Acl -LiteralPath $directory -AclObject $acl -EA Stop
        $temporary = "$path.$([guid]::NewGuid().ToString('N')).tmp"
        try {
            $Backup | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $temporary -Encoding UTF8 -EA Stop
            Move-Item -LiteralPath $temporary -Destination $path -Force -EA Stop
        } finally { if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -EA Stop } }
        GO-ReadUsbBackup $Id | Out-Null
    }

    function Global:GO-ArchiveUsbBackup {
        param([int]$Id)
        $path = GO-GetUsbBackupPath $Id
        $archive = "$path.restored-$([guid]::NewGuid().ToString('N'))"
        Move-Item -LiteralPath $path -Destination $archive -EA Stop
    }

    function Global:GO-ReadUsbRegistry {
        $path = 'HKLM:\SYSTEM\CurrentControlSet\Services\USBHUB3'
        $key = Get-Item -LiteralPath $path -EA Stop
        if ($key.GetValueNames() -notcontains 'DisableSelectiveSuspend') { return @{Exists=$false;Kind='None';Data=$null} }
        return @{Exists=$true;Kind=$key.GetValueKind('DisableSelectiveSuspend').ToString();
            Data=$key.GetValue('DisableSelectiveSuspend',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)}
    }

    function Global:GO-RestoreUsbRegistryValue {
        param($State)
        $path = 'HKLM:\SYSTEM\CurrentControlSet\Services\USBHUB3'
        if (-not $State.Exists) { GO-DelReg $path 'DisableSelectiveSuspend'; return }
        $kind = [Microsoft.Win32.RegistryValueKind]$State.Kind
        $data = switch ($kind) {
            'DWord' {[int]$State.Data}; 'QWord' {[long]$State.Data}
            'String' {[string]$State.Data}; 'ExpandString' {[string]$State.Data}
            'MultiString' {,([string[]]$State.Data)}; 'Binary' {,([byte[]]$State.Data)}; 'None' {,([byte[]]$State.Data)}
        }
        Set-ItemProperty -LiteralPath $path -Name DisableSelectiveSuspend -Value $data -Type $kind -Force -EA Stop
    }

    function Global:GO-EnableUsbRegistryOverride {
        if (-not (GO-ReadUsbBackup 30)) {
            GO-WriteUsbBackup 30 @{Version=1;Id=30;State=(GO-ReadUsbRegistry)}
        }
        GO-SetDW 'HKLM:\SYSTEM\CurrentControlSet\Services\USBHUB3' 'DisableSelectiveSuspend' 1
    }

    function Global:GO-ResetUsbRegistryOverride {
        $backup = GO-ReadUsbBackup 30
        if (-not $backup) { throw 'No saved USBHUB3 baseline. Existing registry setting was left unchanged.' }
        GO-RestoreUsbRegistryValue $backup.State
        $actual = GO-ReadUsbRegistry
        if ($actual.Exists -ne $backup.State.Exists -or $actual.Kind -ne $backup.State.Kind -or
            (ConvertTo-Json -InputObject $actual.Data -Compress) -ne (ConvertTo-Json -InputObject $backup.State.Data -Compress)) {
            throw 'Original USBHUB3 state could not be verified.'
        }
        GO-ArchiveUsbBackup 30
    }

    function Global:GO-GetUsbHubTargets {
        $hubs = @(Get-PnpDevice -PresentOnly -EA Stop | Where-Object { $_.InstanceId -match '^USB\\ROOT_HUB[^\\]*\\' })
        $power = @(Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable -EA Stop)
        foreach ($hub in $hubs) {
            $matched = @($power | Where-Object { $_.InstanceName -match ('^' + [regex]::Escape($hub.InstanceId) + '_\d+$') })
            [pscustomobject]@{DeviceId=$hub.InstanceId;Name=$hub.FriendlyName;Supported=($matched.Count -eq 1 -and $matched[0].Enable -is [bool]);
                Provider=$(if ($matched.Count -eq 1) {$matched[0]} else {$null})}
        }
    }

    function Global:GO-UsbHubControlAvailable {
        $targets = @(GO-GetUsbHubTargets)
        return ($targets.Count -gt 0 -and @($targets | Where-Object { -not $_.Supported }).Count -eq 0)
    }

    function Global:GO-TestUsbHubPowerOff {
        $targets = @(GO-GetUsbHubTargets)
        return ($targets.Count -gt 0 -and @($targets | Where-Object { -not $_.Supported -or $_.Provider.Enable -ne $false }).Count -eq 0)
    }

    function Global:GO-SetUsbHubPower {
        param($Provider,[bool]$Enabled)
        Set-CimInstance -InputObject $Provider -Property @{Enable=$Enabled} -EA Stop | Out-Null
    }

    function Global:GO-DisableUsbHubPowerOff {
        $targets = @(GO-GetUsbHubTargets)
        if (-not $targets.Count -or @($targets | Where-Object { -not $_.Supported }).Count) {
            throw 'Not all present USB root hubs expose unambiguous power-management control.'
        }
        $backup = GO-ReadUsbBackup 31
        $entries = @(if ($backup) { $backup.Entries })
        foreach ($target in $targets) {
            if ($target.Provider.InstanceName -notin @($entries.InstanceName)) {
                $entries += @{DeviceId=$target.DeviceId;Name=$target.Name;InstanceName=$target.Provider.InstanceName;Enabled=[bool]$target.Provider.Enable}
            }
        }
        # Save every newly encountered hub BEFORE the first write, even on a retry.
        GO-WriteUsbBackup 31 @{Version=1;Id=31;Entries=$entries}
        foreach ($target in $targets) { GO-SetUsbHubPower $target.Provider $false }
    }

    function Global:GO-ResetUsbHubPowerOff {
        $backup = GO-ReadUsbBackup 31
        if (-not $backup) { throw 'No saved USB hub baseline. Hub settings were left unchanged.' }
        $targets = @(GO-GetUsbHubTargets)
        $pending = @()
        foreach ($entry in $backup.Entries) {
            $match = @($targets | Where-Object { $_.Supported -and $_.DeviceId -eq $entry.DeviceId -and $_.Provider.InstanceName -eq $entry.InstanceName })
            if ($match.Count -ne 1) { $pending += $entry.Name; continue }
            GO-SetUsbHubPower $match[0].Provider $entry.Enabled
        }
        $updated = @(GO-GetUsbHubTargets)
        foreach ($entry in $backup.Entries) {
            $match = @($updated | Where-Object { $_.Supported -and $_.Provider.InstanceName -eq $entry.InstanceName })
            if ($match.Count -eq 1 -and $match[0].Provider.Enable -ne $entry.Enabled) { throw "USB hub restore verification failed: $($entry.Name)" }
        }
        if ($pending.Count) { throw "USB baseline retained for disconnected/unsupported hubs: $($pending -join ', '). Reconnect and retry Reset." }
        GO-ArchiveUsbBackup 31
    }

    function Global:GO-GetInputUserSid {
        return [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    }

    function Global:GO-EnsureInputInterop {
        if ('WindowsAcolyteInputV1.Native' -as [type]) { return }
        Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
namespace WindowsAcolyteInputV1 {
    [StructLayout(LayoutKind.Sequential)]
    public struct FilterKeys { public uint Size, Flags, Wait, Delay, Repeat, Bounce; }
    [StructLayout(LayoutKind.Sequential)]
    public struct StickyKeys { public uint Size, Flags; }
    public static class Native {
        [DllImport("user32.dll", EntryPoint="SystemParametersInfoW", SetLastError=true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        static extern bool Filter(uint action, uint size, ref FilterKeys data, uint flags);
        [DllImport("user32.dll", EntryPoint="SystemParametersInfoW", SetLastError=true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        static extern bool Sticky(uint action, uint size, ref StickyKeys data, uint flags);
        [DllImport("user32.dll", EntryPoint="SystemParametersInfoW", SetLastError=true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        static extern bool Mouse(uint action, uint size, [In, Out] int[] data, uint flags);
        [DllImport("user32.dll", EntryPoint="SystemParametersInfoW", SetLastError=true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        static extern bool Speed(uint action, uint size, IntPtr data, uint flags);
        static void Check(bool ok) { if (!ok) throw new Win32Exception(Marshal.GetLastWin32Error()); }
        public static FilterKeys ReadFilter() {
            var data = new FilterKeys { Size = (uint)Marshal.SizeOf(typeof(FilterKeys)) };
            Check(Filter(0x32, data.Size, ref data, 0)); return data;
        }
        public static void WriteFilter(FilterKeys data) {
            data.Size = (uint)Marshal.SizeOf(typeof(FilterKeys)); Check(Filter(0x33, data.Size, ref data, 3));
        }
        public static StickyKeys ReadSticky() {
            var data = new StickyKeys { Size = (uint)Marshal.SizeOf(typeof(StickyKeys)) };
            Check(Sticky(0x3A, data.Size, ref data, 0)); return data;
        }
        public static void WriteSticky(StickyKeys data) {
            data.Size = (uint)Marshal.SizeOf(typeof(StickyKeys)); Check(Sticky(0x3B, data.Size, ref data, 3));
        }
        public static int[] ReadMouse() { var data = new int[3]; Check(Mouse(3, 0, data, 0)); return data; }
        public static void WriteMouse(int[] data) { Check(Mouse(4, 0, data, 3)); }
        public static int ReadSpeed() { var data = new int[1]; Check(Mouse(0x70, 0, data, 0)); return data[0]; }
        public static void WriteSpeed(int speed) {
            if (speed < 1 || speed > 20) throw new ArgumentOutOfRangeException("speed");
            Check(Speed(0x71, 0, new IntPtr(speed), 3));
        }
    }
}
'@ -EA Stop
    }

    function Global:GO-ValidateInputState {
        param([ValidateSet(32,33,35,36)][int]$Id, $State)
        $fields = switch ($Id) { 32 {@('Flags','Wait','Delay','Repeat','Bounce')} 33 {@('Flags')} 35 {@('Values')} 36 {@('Speed')} }
        foreach ($field in $fields) {
            if ($null -eq $State.$field) { throw "Incomplete input baseline: $field" }
            if ($field -ne 'Values' -and $State.$field -is [array]) { throw "Input baseline field must be scalar: $field" }
            foreach ($value in @($State.$field)) {
                if ($value -isnot [int] -and $value -isnot [long] -and $value -isnot [uint32]) { throw "Non-numeric input baseline: $field" }
                $maximum = if ($field -eq 'Flags') { 511 } elseif ($field -in @('Wait','Delay','Repeat','Bounce')) { 20000 } else { [int]::MaxValue }
                if ($value -lt 0 -or $value -gt $maximum) { throw "Out-of-range input baseline: $field" }
            }
        }
        if ($Id -eq 35 -and (@($State.Values).Count -ne 3 -or $State.Values[2] -notin @(0,1,2))) { throw 'Invalid mouse acceleration baseline.' }
        if ($Id -eq 36 -and $State.Speed -notin 1..20) { throw 'Invalid pointer-speed baseline.' }
    }

    function Global:GO-ReadInputState {
        param([ValidateSet(32,33,35,36)][int]$Id)
        GO-EnsureInputInterop
        switch ($Id) {
            32 { $data = [WindowsAcolyteInputV1.Native]::ReadFilter(); return @{Flags=[int]$data.Flags;Wait=[int]$data.Wait;Delay=[int]$data.Delay;Repeat=[int]$data.Repeat;Bounce=[int]$data.Bounce} }
            # Transient latched/locked modifier state is not a persistent preference.
            33 { return @{Flags=[int]([WindowsAcolyteInputV1.Native]::ReadSticky().Flags -band 511)} }
            35 { return @{Values=@([WindowsAcolyteInputV1.Native]::ReadMouse())} }
            36 { return @{Speed=[WindowsAcolyteInputV1.Native]::ReadSpeed()} }
        }
    }

    function Global:GO-WriteInputState {
        param([ValidateSet(32,33,35,36)][int]$Id, $State)
        GO-ValidateInputState $Id $State
        GO-EnsureInputInterop
        switch ($Id) {
            32 {
                $data = [WindowsAcolyteInputV1.FilterKeys]::new()
                foreach ($field in @('Flags','Wait','Delay','Repeat','Bounce')) { $data.$field = [uint32]$State.$field }
                [WindowsAcolyteInputV1.Native]::WriteFilter($data)
            }
            33 { $data = [WindowsAcolyteInputV1.StickyKeys]::new(); $data.Flags = [uint32]$State.Flags; [WindowsAcolyteInputV1.Native]::WriteSticky($data) }
            35 { [WindowsAcolyteInputV1.Native]::WriteMouse([int[]]$State.Values) }
            36 { [WindowsAcolyteInputV1.Native]::WriteSpeed([int]$State.Speed) }
        }
    }

    function Global:GO-InputStatesEqual {
        param([int]$Id, $Expected, $Actual)
        $fields = switch ($Id) { 32 {@('Flags','Wait','Delay','Repeat','Bounce')} 33 {@('Flags')} 35 {@('Values')} 36 {@('Speed')} }
        foreach ($field in $fields) {
            if ((ConvertTo-Json -InputObject $Expected.$field -Compress) -ne (ConvertTo-Json -InputObject $Actual.$field -Compress)) { return $false }
        }
        return $true
    }

    function Global:GO-ApplyInputOption {
        param([ValidateSet(32,33,35,36)][int]$Id, [int]$TargetSpeed)
        if ($Id -eq 36 -and $TargetSpeed -notin 1..20) { throw 'Choose a pointer speed from 1 to 20.' }
        $state = GO-ReadInputState $Id
        if (-not (GO-ReadUsbBackup $Id)) {
            GO-WriteUsbBackup $Id @{Version=1;Id=$Id;UserSid=(GO-GetInputUserSid);State=$state}
        }
        $desired = @{}
        foreach ($key in $state.Keys) { $desired[$key] = $state[$key] }
        switch ($Id) {
            32 { $desired.Flags = [int]$state.Flags -band (-bnot 5) }
            33 { $desired.Flags = [int]$state.Flags -band (-bnot 5) }
            35 { $desired.Values = @($state.Values); $desired.Values[2] = 0 }
            36 { $desired.Speed = $TargetSpeed }
        }
        GO-WriteInputState $Id $desired
        if (-not (GO-InputStatesEqual $Id $desired (GO-ReadInputState $Id))) { throw 'Input setting readback did not match; original baseline retained.' }
    }

    function Global:GO-ResetInputOption {
        param([ValidateSet(32,33,35,36)][int]$Id)
        $backup = GO-ReadUsbBackup $Id
        if (-not $backup) { throw 'No original input state saved for this Windows user; nothing changed.' }
        GO-WriteInputState $Id $backup.State
        if (-not (GO-InputStatesEqual $Id $backup.State (GO-ReadInputState $Id))) { throw 'Original input state could not be verified; baseline retained.' }
        GO-ArchiveUsbBackup $Id
    }

    function Global:GO-GetUsbPlanState {
        param([string]$Guid)
        if (-not $Guid) {
            $active = (GO-InvokeNative 'powercfg.exe' @('/getactivescheme')) -join ' '
            $match = [regex]::Match($active,'[a-fA-F0-9]{8}(-[a-fA-F0-9]{4}){3}-[a-fA-F0-9]{12}')
            if (-not $match.Success) { throw 'Active power-plan GUID could not be read.' }
            $Guid = $match.Value
        }
        if ($Guid -notmatch '^[a-fA-F0-9]{8}(-[a-fA-F0-9]{4}){3}-[a-fA-F0-9]{12}$') { throw 'Invalid power-plan GUID.' }
        $output = (GO-InvokeNative 'powercfg.exe' @('/query',$Guid,'2a737441-1930-4402-8d77-b2bebba308a3','48e6b7a6-50f5-4782-a5d4-53bb8f07e226')) -join "`n"
        # powercfg labels are localized; the final two hex indexes are AC and DC.
        $indexes = [regex]::Matches($output,'(?im)^.*:\s*0x([0-9a-f]+)\s*$')
        if ($indexes.Count -ne 2) { throw 'USB selective-suspend AC/DC indexes are unavailable or ambiguous.' }
        $ac = [Convert]::ToInt32($indexes[0].Groups[1].Value,16); $dc = [Convert]::ToInt32($indexes[1].Groups[1].Value,16)
        if ($ac -notin @(0,1) -or $dc -notin @(0,1)) { throw 'Unexpected USB selective-suspend indexes.' }
        return @{Guid=$Guid.ToLowerInvariant();AC=$ac;DC=$dc}
    }

    function Global:GO-WriteUsbPlanState {
        param($State)
        GO-InvokeNative 'powercfg.exe' @('/setacvalueindex',$State.Guid,'2a737441-1930-4402-8d77-b2bebba308a3','48e6b7a6-50f5-4782-a5d4-53bb8f07e226',[string]$State.AC) | Out-Null
        GO-InvokeNative 'powercfg.exe' @('/setdcvalueindex',$State.Guid,'2a737441-1930-4402-8d77-b2bebba308a3','48e6b7a6-50f5-4782-a5d4-53bb8f07e226',[string]$State.DC) | Out-Null
        # Apply only if this plan is still active; never deliberately activate
        # an inactive saved plan while restoring its settings.
        $active = (GO-InvokeNative 'powercfg.exe' @('/getactivescheme')) -join ' '
        if ($active -match [regex]::Escape($State.Guid)) {
            GO-InvokeNative 'powercfg.exe' @('/setactive',$State.Guid) | Out-Null
        }
    }

    function Global:GO-DisableUsbPlanSuspend {
        $state = GO-GetUsbPlanState
        $backup = GO-ReadUsbBackup 34
        $plans = @(if ($backup) { $backup.Plans })
        if ($state.Guid -notin @($plans.Guid)) { $plans += $state }
        GO-WriteUsbBackup 34 @{Version=1;Id=34;Plans=$plans}
        GO-WriteUsbPlanState @{Guid=$state.Guid;AC=0;DC=0}
        $verified = GO-GetUsbPlanState $state.Guid
        if ($verified.AC -ne 0 -or $verified.DC -ne 0) { throw 'USB plan write verification failed; baseline retained.' }
    }

    function Global:GO-ResetUsbPlanSuspend {
        $backup = GO-ReadUsbBackup 34
        if (-not $backup) { throw 'No saved USB plan baseline; existing policies remain unchanged.' }
        $failed = @()
        foreach ($plan in $backup.Plans) {
            try {
                GO-WriteUsbPlanState $plan
                $actual = GO-GetUsbPlanState $plan.Guid
                if ($actual.AC -ne $plan.AC -or $actual.DC -ne $plan.DC) { throw 'Readback mismatch' }
            } catch { $failed += "$($plan.Guid): $_" }
        }
        if ($failed.Count) { throw "USB plan baseline retained. Restore incomplete: $($failed -join '; ')" }
        GO-ArchiveUsbBackup 34
    }

    function Global:GO-GetLocalUpdateStatus {
        $session=$null; $searcher=$null; $history=$null; $system=$null
        try {
            $session = New-Object -ComObject Microsoft.Update.Session -EA Stop
            $searcher = $session.CreateUpdateSearcher()
            $count = [math]::Min(100,$searcher.GetTotalHistoryCount())
            $latest = $null
            if ($count -gt 0) {
                $history = $searcher.QueryHistory(0,$count)
                $latest = $history | Where-Object { $_.Operation -eq 1 -and $_.ResultCode -eq 2 } | Select-Object -First 1
            }
            $system = New-Object -ComObject Microsoft.Update.SystemInfo -EA Stop
            $last = if ($latest) { "$($latest.Date.ToString('yyyy-MM-dd HH:mm')) - $($latest.Title)" } else { 'No successful install found in the last 100 local events.' }
            return "Read: $(Get-Date -Format 'yyyy-MM-dd HH:mm') | Windows $([Environment]::OSVersion.Version)`nLast recorded successful update: $last`nWindows Update reboot pending: $($system.RebootRequired). Local history only - update availability/completeness is UNKNOWN. No online scan, install or restart."
        } finally {
            foreach ($com in @($history,$searcher,$session,$system)) {
                if ($null -ne $com -and [Runtime.InteropServices.Marshal]::IsComObject($com)) { [Runtime.InteropServices.Marshal]::ReleaseComObject($com) | Out-Null }
            }
        }
    }

    function Global:GO-OpenWindowsUpdate {
        Start-Process -FilePath 'ms-settings:windowsupdate' -EA Stop | Out-Null
    }

    function Global:GO-GetPowerSchemes {
        foreach ($line in (GO-InvokeNative 'powercfg.exe' @('/list'))) {
            if ($line -match '([0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12})\s*\((.*?)\)') {
                [pscustomobject]@{ Guid=$matches[1]; Name=$matches[2] }
            }
        }
    }

    function Global:GO-TestUltimatePlan {
        $activeText = (GO-InvokeNative 'powercfg.exe' @('/getactivescheme')) -join ' '
        $activeGuid = [regex]::Match($activeText, '[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}').Value
        if (-not $activeGuid) { throw 'Could not read the active power plan GUID.' }
        if ($activeGuid -in @('e9a42b02-d5df-448d-aa00-03f14749eb61','7e195a58-faf5-4a60-9f6b-72328419de91')) { return $true }
        $active = GO-GetPowerSchemes | Where-Object { $_.Guid -eq $activeGuid } | Select-Object -First 1
        return ($null -ne $active -and $active.Name -in @('Ultimate Performance','WindowsAcolyte Ultimate Performance','WindowsAcolyte Gaming Ultimate Performance'))
    }

    function Global:GO-EnableUltimatePlan {
        if (GO-TestUltimatePlan) { return }
        $plan = GO-GetPowerSchemes | Where-Object {
            $_.Guid -eq '7e195a58-faf5-4a60-9f6b-72328419de91' -or
            $_.Name -in @('Ultimate Performance','WindowsAcolyte Ultimate Performance','WindowsAcolyte Gaming Ultimate Performance')
        } | Select-Object -First 1
        if ($plan) { $guid = $plan.Guid }
        else {
            $guid = '7e195a58-faf5-4a60-9f6b-72328419de91'
            GO-InvokeNative 'powercfg.exe' @('/duplicatescheme','e9a42b02-d5df-448d-aa00-03f14749eb61',$guid) | Out-Null
            GO-InvokeNative 'powercfg.exe' @('/changename',$guid,'WindowsAcolyte Gaming Ultimate Performance') | Out-Null
        }
        GO-InvokeNative 'powercfg.exe' @('/setactive',$guid) | Out-Null
    }

    function Global:GO-GetTweakState {
        param($Tweak)
        try {
            if ($Tweak.Optional) { GO-ReadUsbBackup $Tweak.Id | Out-Null }
            if ($Tweak.Available -and -not (& $Tweak.Available)) {
                return @{Applied=$false; Status='UNAVAILABLE'; Message=$Tweak.UnavailableReason}
            }
            if ($Tweak.Id -eq 34 -and $Tweak.Optional) {
                $plan=GO-GetUsbPlanState
                $applied=$plan.AC -eq 0 -and $plan.DC -eq 0
                return @{Applied=$applied;Status=$(if ($applied) {'APPLIED'} else {'MISSING'});
                    Message="Active plan $($plan.Guid): AC=$($plan.AC), DC=$($plan.DC) (0=Disabled, 1=Enabled). $($Tweak.Note)"}
            }
            $result = @(& $Tweak.Check)
            if ($result.Count -ne 1 -or $result[0] -isnot [bool]) { throw 'Status check must return exactly one Boolean.' }
            return @{Applied=$result[0]; Status=$(if ($result[0]) {'APPLIED'} else {'MISSING'}); Message='Configuration check; reboot may still be required.'}
        } catch {
            return @{Applied=$false; Status='CHECK ERROR'; Message=$_.Exception.Message}
        }
    }

    function Global:GO-TestDWord {
        param($p, $n, [uint32]$Expected)
        $value = GO-GetReg $p $n
        if ($null -eq $value) { return $false }
        # Registry providers may expose DWORDs as signed or unsigned integers.
        return (([long]$value -band 0xFFFFFFFFL) -eq [long]$Expected)
    }

    function Global:GO-ApplyVerifiedTweak {
        param($Tweak)
        $ErrorActionPreference = 'Stop'
        if ($Tweak.Available -and -not (& $Tweak.Available)) { throw $Tweak.UnavailableReason }
        & $Tweak.Apply | Out-Null
        $state = GO-GetTweakState $Tweak
        if (-not $state.Applied) {
            throw "Setting verification failed after applying: $($Tweak.Label). $($state.Message)"
        }
    }

    function Global:GO-GetStateSnapshot {
        $states = @{}
        foreach ($tweak in $script:GO_tweaks) { $states[$tweak.Id] = GO-GetTweakState $tweak }
        return $states
    }

    function Global:GO-LogStateChanges {
        param($Before, $After, [string]$Action)
        foreach ($tweak in $script:GO_tweaks) {
            if ($Before[$tweak.Id].Applied -and -not $After[$tweak.Id].Applied) {
                GO-AddLog "$Action changed previously applied setting: $($tweak.Label) -> $($After[$tweak.Id].Status)" 'WARN'
            }
        }
    }

    function Global:GO-ResetTweak {
        param($Tweak)
        $ErrorActionPreference = 'Stop'
        & $Tweak.Revert | Out-Null
    }

    function Global:GO-DetectHardware {
        $cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name
        $gpu = (Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch "Basic|Virtual" } | Select-Object -First 1).Name
        $ramGB = [math]::Round(((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB), 0)
        $build = [System.Environment]::OSVersion.Version.Build
        $isX3D = $cpu -match "X3D"

        $text = "CPU: $cpu`nGPU: $gpu`nRAM: $ramGB GB | Windows Build: $build"
        if ($isX3D)           { $text += "`n[!] AMD X3D detected - Xbox Game Bar and Game Mode must stay ACTIVE" }
        if ($build -ge 26100) { $text += "`n[i] Windows 11 24H2+ - Native NVMe Stack available" }

        $script:GO_hwText.Text = $text
        return @{
            CPU=$cpu; GPU=$gpu; RAMGB=$ramGB; Build=$build; IsX3D=$isX3D
            IsIntel12Plus=($cpu -match "1[2-9]\d{3}|2\d{4}")
            IsAMDRyzen5000Plus=($cpu -match "Ryzen.*[5-9]\d{3}|Ryzen.*X3D")
        }
    }

    $script:GO_hw = GO-DetectHardware

    function Global:GO-IsRecommended {
        param($TweakId)
        $tweak = $script:GO_tweaks | Where-Object { $_.Id -eq $TweakId } | Select-Object -First 1
        if ($tweak.Optional) { return $false }
        if ($tweak.Mutex) {
            foreach ($other in $script:GO_tweaks) {
                if ($other.Id -ne $TweakId -and $other.Mutex -eq $tweak.Mutex -and (& $other.Check)) {
                    return $false
                }
            }
        }
        $alwaysRecommended = @(1,2,3,4,8,9,11,12,13,14,15,16,17,18,19,20,21,22,25,26,27,28)
        if ($TweakId -eq 24) { return $false }
        if ($tweak.Available -and -not (& $tweak.Available)) { return $false }
        if ($alwaysRecommended -contains $TweakId) { return $true }
        if ($script:GO_hw.IsX3D -and $TweakId -eq 5) { return $false }
        return $false
    }

    $script:GO_tweaks = @(
        @{ Id=1; Group="Security & Recording"; Risk=1; NeedsReboot=$true;
           Label="Memory Integrity / HVCI (OFF)";
           SimpleShort='Turns off a Windows security check for low-level drivers.';
           SimpleLong='Think of this as removing a security guard who checks important software near the heart of Windows. It may reduce some work for the PC, but also removes protection. This option also turns off VBS. A restart may be needed; a green APPLIED label is not proof that the running protection has already changed.';
           Impact='Security protection reduced; performance varies';
           ShortDesc='Sets HVCI Enabled=0 and EnableVirtualizationBasedSecurity=0.';
           LongDesc='Requests HVCI and VBS off through their registry flags. These are security controls, not a guaranteed FPS fix. Runtime state can depend on restart, policy and platform configuration. Reset writes both flags to 1 and can invalidate the separate VBS-off option.';
           FPSGain='Security protection reduced; performance varies';
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled") -eq 0 -and
                   (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity") -eq 0 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 0
                   GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 0 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 1
                    GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 1 } }
        @{ Id=2; Group="Security & Recording"; Risk=1; NeedsReboot=$true;
           Label="VBS Registry Configuration (OFF)";
           SimpleShort='Asks Windows to turn off its isolated security area.';
           SimpleLong='Windows can keep some security work in a separate protected area. This setting asks it to stop doing that. Protection can be reduced, and other Windows rules may keep it running anyway. It does not uninstall a Windows feature. Reset turns the VBS setting back on.';
           Impact='Security configuration; runtime effect may differ';
           ShortDesc='Sets the VBS registry configuration flag to 0.';
           LongDesc='Writes EnableVirtualizationBasedSecurity=0. Does not remove Virtual Machine Platform or bypass policy/UEFI locks. APPLIED reports the stored target, not hypervisor runtime state. Reset writes 1 and invalidates the combined HVCI-off configuration.';
           FPSGain='Security configuration; runtime effect may differ';
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity") -eq 0 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 0 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 1 } }
        @{ Id=3; Group="Security & Recording"; Risk=0; NeedsReboot=$true;
           Label="GameDVR / Xbox Recording (OFF)";
           SimpleShort='Turns off the Windows game-recording feature.';
           SimpleLong='If you do not use Windows to record game clips, you can turn that feature off. This can remove recording work when it was in use, but it is not a promise of more frames. You lose the affected recording feature until you turn it back on.';
           Impact='Recording availability; workload-dependent overhead';
           ShortDesc='Disables the per-user GameDVR flag and machine recording policy.';
           LongDesc='Writes GameDVR_Enabled=0 and AllowGameDVR=0. Whether recording overhead changes depends on the original recording activity. Reset enables the user flag and removes the machine policy.';
           FPSGain='Recording availability; workload-dependent overhead';
           Check={ (GO-GetReg "HKCU:\System\GameConfigStore" "GameDVR_Enabled") -eq 0 -and
                   (GO-GetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR") -eq 0 };
           Apply={ GO-SetDW "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
                   GO-SetDW "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0 };
           Revert={ GO-SetDW "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 1
                    GO-DelReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" } }
        @{ Id=4; Group="Security & Recording"; Risk=2; NeedsReboot=$true;
           Label="Spectre/Meltdown Mitigations (OFF) - HIGH RISK";
           SimpleShort='Weakens protection against certain processor attacks.';
           SimpleLong='These protections help stop software from stealing information through processor weaknesses. Turning them off trades protection for an uncertain possible speed difference. This is a high-risk choice, not a normal fix for a slow game.';
           Impact='Security-sensitive; no guaranteed speed improvement';
           ShortDesc='Writes FeatureSettingsOverride=3 and FeatureSettingsOverrideMask=3.';
           LongDesc='Changes CPU-mitigation override configuration in Memory Management. Security impact and runtime behavior depend on CPU, Windows and restart state. No measured performance benefit is established here. Reset deletes these managed override values.';
           FPSGain='Security-sensitive; no guaranteed speed improvement';
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverride") -eq 3 -and
                   (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverrideMask") -eq 3 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverride" 3
                   GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverrideMask" 3 };
           Revert={ GO-DelReg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverride"
                    GO-DelReg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverrideMask" } }
        @{ Id=5; Group="Power / CPU"; Risk=0; NeedsReboot=$false;
           Label="Ultimate Performance Power Plan";
           SimpleShort='Switches Windows to an Ultimate Performance power plan.';
           SimpleLong='A power plan tells Windows how to balance energy saving and responsiveness. This selects a performance-focused plan instead of your current one. It can use more electricity and produce more heat. Reset selects Balanced; it does not remember your old plan.';
           Impact='Power use, heat and responsiveness trade-off';
           ShortDesc='Finds or creates and activates an Ultimate Performance plan.';
           LongDesc='Uses powercfg plan identity for readback. This option selects a plan; the separate Ultimate Performance module manages additional explicit AC/DC settings. Reset selects SCHEME_BALANCED, including after that module was used.';
           FPSGain='Power use, heat and responsiveness trade-off';
           Check={ GO-TestUltimatePlan };
           Apply={ GO-EnableUltimatePlan };
           Revert={ GO-InvokeNative 'powercfg.exe' @('/setactive','SCHEME_BALANCED') | Out-Null } }
        @{ Id=6; Group="Power / CPU"; Risk=1; NeedsReboot=$true;
           Label="Disable Power Throttling";
           SimpleShort='Stops Windows from using one background power-saving policy.';
           SimpleLong='Windows can give background apps less energy to save power. This disables that power-saving policy. Background apps may then use more resources too, so your game is not automatically faster. Expect a possible battery or heat trade-off.';
           Impact='Background power use; results depend on workload';
           ShortDesc='Sets PowerThrottlingOff=1 for the Windows power-throttling policy.';
           LongDesc='Writes the machine PowerThrottlingOff flag. This is not a per-game CPU reservation and does not prevent all other power limits. Reset removes the managed value.';
           FPSGain='Background power use; results depend on workload';
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff") -eq 1 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" 1 };
           Revert={ GO-DelReg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" } }
        @{ Id=7; Group="Power / CPU"; Risk=0; NeedsReboot=$false;
           Label="System Responsiveness = 10";
           SimpleShort='Changes how a Windows media scheduler shares processor time.';
           SimpleLong='Imagine several jobs taking turns at one desk. This changes one rule Windows uses to share that desk between special media work and lower-priority work. It does not give every game a fixed extra share or guarantee more frames.';
           Impact='Multimedia scheduling; application-dependent';
           ShortDesc='Sets MMCSS SystemResponsiveness to 10.';
           LongDesc='Changes the configured CPU-resource percentage guaranteed to low-priority tasks under MMCSS. Only work participating in this scheduling system is affected; this is not a universal foreground CPU allocation. Reset uses 20.';
           FPSGain='Multimedia scheduling; application-dependent';
           Check={ (GO-GetReg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness") -eq 10 };
           Apply={ GO-SetDW "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 10 };
           Revert={ GO-SetDW "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 20 } }
        @{ Id=8; Group="Power / CPU"; Risk=0; NeedsReboot=$false;
           Label="Network Throttling Disabled";
           SimpleShort='Changes a Windows limit on some network-processing work.';
           SimpleLong='This removes one Windows network-throttling setting. Your router, internet connection and game server still affect lag. A MISSING label does not mean your internet is broken, and applying this cannot promise lower ping.';
           Impact='Network configuration; no promised ping reduction';
           ShortDesc='Sets NetworkThrottlingIndex to DWORD 0xFFFFFFFF.';
           LongDesc='Readback accepts signed or unsigned representations of this DWORD. It verifies the multimedia network-throttling configuration, not measured throughput, packet latency or server round-trip time. Reset writes 10.';
           FPSGain='Network configuration; no promised ping reduction';
           Check={ GO-TestDWord "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" ([uint32]::MaxValue) };
           Apply={ GO-SetDW "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" ([uint32]::MaxValue) };
           Revert={ GO-SetDW "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 10 } }
        @{ Id=9; Group="Power / CPU"; Risk=0; NeedsReboot=$false; Mutex="PrioritySep";
           Label="Win32PrioritySeparation = 36 (Competitive)";
           SimpleShort='Selects one processor time-sharing preset; replaces the AAA preset.';
           SimpleLong='Windows lets programs take turns using the processor. This selects one time-sharing rule, called Competitive here. The name is a preset label, not proof it is best for your game. Only one of the two presets can be active. Reset uses the module default.';
           Impact='Processor scheduling preset; compare on your PC';
           ShortDesc='Sets Win32PrioritySeparation=36 (0x24).';
           LongDesc='Alternative to the value 24 preset. Both write the same machine registry value and therefore cannot be active together. Actual scheduling/performance depends on Windows and workload; compare repeatable measurements. Reset writes 38 (0x26).';
           FPSGain='Processor scheduling preset; compare on your PC';
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation") -eq 0x24 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 0x24 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 0x26 } }
        @{ Id=10; Group="Power / CPU"; Risk=0; NeedsReboot=$false; Mutex="PrioritySep";
           Label="Win32PrioritySeparation = 24 (AAA Games)";
           SimpleShort='Selects another processor time-sharing preset; replaces Competitive.';
           SimpleLong='This is a different rule for how programs take turns using the processor. The AAA name does not mean all large games will run better. Selecting it replaces the Competitive preset. ALTERNATIVE means the other preset is already active, not that you need both.';
           Impact='Alternative scheduling preset; compare on your PC';
           ShortDesc='Sets Win32PrioritySeparation=24 (0x18).';
           LongDesc='Mutually exclusive with value 36 because both manage Win32PrioritySeparation. No game-specific improvement is verified by the label or registry readback. Reset writes 38 (0x26).';
           FPSGain='Alternative scheduling preset; compare on your PC';
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation") -eq 0x18 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 0x18 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 0x26 } }
        @{ Id=11; Group="Power / CPU"; Risk=0; NeedsReboot=$false;
           Label="Startup Delay Disabled";
           SimpleShort='Removes one wait before startup apps open after sign-in.';
           SimpleLong='Some apps open automatically when you sign in. This asks Windows not to add its configured startup delay. More apps may start together, which can also make sign-in busier. It does not increase game FPS once everything is running.';
           Impact='Sign-in/startup behavior; no game-FPS claim';
           ShortDesc='Sets the current-user StartupDelayInMSec value to 0.';
           LongDesc='Writes Explorer/Serialize startup-delay configuration. It does not remove startup apps or measure boot time. Reset removes this user value.';
           FPSGain='Sign-in/startup behavior; no game-FPS claim';
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" 0 };
           Revert={ GO-DelReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" } }
        @{ Id=12; Group="Graphics / Gaming"; Risk=0; NeedsReboot=$true;
           Label="Hardware-Accelerated GPU Scheduling (ON)";
           SimpleShort='Asks the graphics system to use hardware-assisted scheduling.';
           SimpleLong='Your graphics card and Windows must organize lots of small drawing jobs. This requests a different way to organize that work. It needs suitable hardware and drivers, and games can react differently. The setting alone does not prove the feature is running.';
           Impact='Graphics scheduling; hardware/driver-dependent';
           ShortDesc='Sets Hardware-Accelerated GPU Scheduling configuration HwSchMode=2.';
           LongDesc='Requests HAGS through the GraphicsDrivers registry value. Support and effective runtime state depend on the GPU, driver, Windows version and restart. This check only verifies the stored value. Reset writes 1.';
           FPSGain='Graphics scheduling; hardware/driver-dependent';
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode") -eq 2 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 1 } }
        @{ Id=13; Group="Graphics / Gaming"; Risk=0; NeedsReboot=$false;
           Label="Windows Game Mode (ON)";
           SimpleShort='Turns Windows Game Mode on.';
           SimpleLong='Game Mode tells Windows to focus on gaming while you play. It is not a magic speed switch. Some processor setups use it as part of their normal game handling. Reset turns it off, which is important to notice before clicking Reset.';
           Impact='Windows gaming preference; effect varies';
           ShortDesc='Sets the current-user AutoGameModeEnabled flag to 1.';
           LongDesc='Verifies the Game Mode preference rather than per-game scheduling behavior. Keep platform/vendor guidance in mind, especially for AMD X3D setups. Reset writes 0 and disables this preference.';
           FPSGain='Windows gaming preference; effect varies';
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled") -eq 1 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 1 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 0 } }
        @{ Id=14; Group="Graphics / Gaming"; Risk=0; NeedsReboot=$false;
           Label="Legacy Fullscreen Compatibility Flags";
           SimpleShort='Changes older fullscreen compatibility flags, not the modern windowed-games switch.';
           SimpleLong='Windows has several different settings for how games fill the screen. This changes older compatibility flags. It is not the Windows 11 windowed-games setting. Leave a working setup alone unless you are testing a specific display problem.';
           Impact='Fullscreen compatibility; targeted testing only';
           ShortDesc='Sets GameDVR_FSEBehaviorMode=2 and GameDVR_HonorUserFSEBehaviorMode=1.';
           LongDesc='These legacy GameDVR flags are distinct from Optimizations for windowed games and do not prove a game is using a particular presentation mode. Test the same game/scene before and after; no universal latency benefit is claimed.';
           FPSGain='Fullscreen compatibility; targeted testing only';
           Check={ (GO-GetReg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode") -eq 2 -and
                   (GO-GetReg "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode") -eq 1 };
           Apply={ GO-SetDW "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2
                   GO-SetDW "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 1 };
           Revert={ GO-DelReg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode"
                    GO-DelReg "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" } }
        @{ Id=15; Group="Graphics / Gaming"; Risk=0; NeedsReboot=$false;
           Label="Games Task Scheduling = High";
           SimpleShort='Changes the priority category for programs using the Games media task.';
           SimpleLong='This is like changing the priority of one special queue. Only programs that actually join that queue can use the rule. It does not force every game to use it or guarantee that more important work becomes faster.';
           Impact='Registered multimedia-task priority only';
           ShortDesc='Sets the MMCSS Games Scheduling Category to High.';
           LongDesc='The task configuration only applies to threads that register for the relevant MMCSS task. A stored High category does not prove the game participates or improves. Reset uses the module-defined category.';
           FPSGain='Registered multimedia-task priority only';
           Check={ (GO-GetReg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category") -eq "High" };
           Apply={ GO-SetStr "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "High" };
           Revert={ GO-SetStr "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "Medium" } }
        @{ Id=16; Group="Network"; Risk=1; NeedsReboot=$false;
           Label="Disable Nagle Algorithm";
           SimpleShort='Changes small-packet waiting rules for some TCP connections.';
           SimpleLong='Some network connections wait briefly to group small pieces of data. This changes settings related to that behavior on active physical network adapters. It does not change every kind of game traffic; many games use another protocol, UDP.';
           Impact='TCP behavior; not a universal game-lag fix';
           ShortDesc='Sets TCPNoDelay=1, TcpAckFrequency=1 and TcpDelAckTicks=0 per active physical adapter.';
           LongDesc='Targets the current physical Ethernet/Wi-Fi interface registry keys; VPN interfaces are excluded. TCP settings do not directly tune UDP game packets. Adapter changes can change which values are checked. Reset removes these three per-adapter values.';
           Available={ @(GO-GetGamingAdapters).Count -gt 0 };
           UnavailableReason="No active physical Ethernet/Wi-Fi adapter. Connect an adapter and recheck.";
           FPSGain='TCP behavior; not a universal game-lag fix';
           Check={
               $nics = @(GO-GetGamingAdapters)
               if ($nics.Count -eq 0) { return $false }
               foreach ($n in $nics) {
                   $p = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($n.InterfaceGuid)"
                   if ((GO-GetReg $p "TcpAckFrequency") -ne 1 -or (GO-GetReg $p "TCPNoDelay") -ne 1 -or
                       (GO-GetReg $p "TcpDelAckTicks") -ne 0) { return $false }
               }
               return $true
           };
           Apply={
               $nics = @(GO-GetGamingAdapters)
               if ($nics.Count -eq 0) { throw 'No active physical Ethernet/Wi-Fi adapter.' }
               foreach ($n in $nics) {
                   $p = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($n.InterfaceGuid)"
                   GO-SetDW $p "TcpAckFrequency" 1; GO-SetDW $p "TCPNoDelay" 1; GO-SetDW $p "TcpDelAckTicks" 0
               }
           };
           Revert={
               $nics = GO-GetGamingAdapters
               foreach ($n in $nics) {
                   $p = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($n.InterfaceGuid)"
                   GO-DelReg $p "TcpAckFrequency"; GO-DelReg $p "TCPNoDelay"; GO-DelReg $p "TcpDelAckTicks"
               }
           } }
        @{ Id=17; Group="Network"; Risk=0; NeedsReboot=$false;
           Label="Advanced TCP Optimizations";
           SimpleShort='Changes several Windows-wide network settings together.';
           SimpleLong='This adjusts how Windows handles some internet traffic. Because the settings are shared by the PC, they can affect more than your game. A different driver, VPN or connection may react differently. Test only when investigating a specific problem.';
           Impact='Global network/offload configuration';
           ShortDesc='Sets TCP autotuning=normal, RSS=enabled, RSC/ECN/timestamps=disabled.';
           LongDesc='Uses netsh global TCP configuration and checks all five managed values. These settings interact with network adapters and other tuning software. Reset uses the module reset values, not a saved snapshot of the previous global configuration.';
           FPSGain='Global network/offload configuration';
           Check={ GO-TestTCPSettings };
           Apply={ foreach ($setting in @('autotuninglevel=normal','rss=enabled','rsc=disabled','ecncapability=disabled','timestamps=disabled')) {
                       GO-InvokeNative 'netsh.exe' @('int','tcp','set','global',$setting) | Out-Null
                   } };
           Revert={ foreach ($setting in @('autotuninglevel=normal','rss=default','rsc=default','ecncapability=default','timestamps=default')) {
                        GO-InvokeNative 'netsh.exe' @('int','tcp','set','global',$setting) | Out-Null
                    } } }
        @{ Id=18; Group="UI / Visual"; Risk=0; NeedsReboot=$false;
           Label="Transparency Effects (OFF)";
           SimpleShort='Makes Windows panels solid instead of see-through.';
           SimpleLong='Menus and panels lose their see-through appearance. Choose this if you prefer a simpler-looking desktop. It is a visual preference; do not expect a noticeable improvement in game performance.';
           Impact='Desktop appearance';
           ShortDesc='Sets the current-user EnableTransparency flag to 0.';
           LongDesc='Changes Windows desktop transparency preference. It does not adjust game graphics settings or verify a frame-rate improvement. Reset enables transparency.';
           FPSGain='Desktop appearance';
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 1 } }
        @{ Id=19; Group="UI / Visual"; Risk=0; NeedsReboot=$false;
           Label="Window Animations (OFF)";
           SimpleShort='Stops the animations when windows open, minimize or restore.';
           SimpleLong='Windows move into place without the usual animation. That can make the desktop feel more immediate, even though it does not make a game draw more frames. You can turn the animations back on with Reset.';
           Impact='Desktop motion/comfort';
           ShortDesc='Sets the current-user MinAnimate preference to 0.';
           LongDesc='Controls window animation preference in WindowMetrics. The effect concerns desktop transitions rather than game rendering. Reset uses the enabled value.';
           FPSGain='Desktop motion/comfort';
           Check={ (GO-GetReg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate") -eq "0" };
           Apply={ GO-SetStr "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" };
           Revert={ GO-SetStr "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "1" } }
        @{ Id=20; Group="UI / Visual"; Risk=0; NeedsReboot=$false;
           Label="Menu Show Delay = 0";
           SimpleShort='Removes the configured wait before menus appear.';
           SimpleLong='Windows menus can appear with less waiting. This changes menu behavior, not internet lag or the time between a mouse click and a game reacting. Faster menus can also feel too eager if you prefer a delay.';
           Impact='Desktop menu timing';
           ShortDesc='Sets MenuShowDelay to the string 0.';
           LongDesc='Changes the current-user Desktop menu delay. Readback verifies the configured value, not measured game input latency. Reset uses the module menu-delay preset.';
           FPSGain='Desktop menu timing';
           Check={ (GO-GetReg "HKCU:\Control Panel\Desktop" "MenuShowDelay") -eq "0" };
           Apply={ GO-SetStr "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" };
           Revert={ GO-SetStr "HKCU:\Control Panel\Desktop" "MenuShowDelay" "400" } }
        @{ Id=21; Group="UI / Visual"; Risk=0; NeedsReboot=$false;
           Label="Taskbar Animations (OFF)";
           SimpleShort='Turns off taskbar animations.';
           SimpleLong='Taskbar items change without some of their usual motion effects. This is mainly a preference for how Windows looks and feels. It is not a proven game-FPS improvement.';
           Impact='Taskbar appearance/comfort';
           ShortDesc='Sets TaskbarAnimations to 0 for the current user.';
           LongDesc='Changes Explorer taskbar animation configuration. It does not modify game simulation or rendering. Reset enables the preference.';
           FPSGain='Taskbar appearance/comfort';
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 0 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 1 } }
        @{ Id=22; Group="Filesystem / Storage"; Risk=0; NeedsReboot=$true;
           Label="NTFS Disable Last Access Time";
           SimpleShort='Stops one kind of automatic file-access timestamp update.';
           SimpleLong='Windows can record when a file was last opened. This changes that record-keeping rule. Some backup or archive tools may depend on those timestamps, so check your tools before changing it. The files themselves are not deleted.';
           Impact='File metadata / backup-tool compatibility';
           ShortDesc='Configures NTFS last-access timestamp updates as disabled.';
           LongDesc='Uses fsutil behavior and numeric NTFS state readback, including system-managed states. This is timestamp policy, not file deletion or a measured disk-speed gain. Check compatibility with timestamp-based workflows.';
           FPSGain='File metadata / backup-tool compatibility';
           Check={ $v = GO-GetReg 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'NtfsDisableLastAccessUpdate'
                   $null -ne $v -and ([long]$v -band 3) -in @(1,3) };
           Apply={ GO-InvokeNative 'fsutil.exe' @('behavior','set','disablelastaccess','1') | Out-Null };
           Revert={ GO-InvokeNative 'fsutil.exe' @('behavior','set','disablelastaccess','0') | Out-Null } }
        @{ Id=23; Group="Filesystem / Storage"; Risk=0; NeedsReboot=$false;
           Label="NTFS Disable 8.3 Filenames";
           SimpleShort='Stops Windows from creating new old-style short filenames.';
           SimpleLong='Older programs sometimes use short names such as PROGRA~1 instead of long folder names. This stops new short-name creation according to the global policy. Modern apps may be fine, but old software or installers can depend on it.';
           Impact='Legacy software / filename compatibility';
           ShortDesc='Sets the global NTFS 8.3 name-creation policy to 1.';
           LongDesc='Writes the global fsutil 8dot3name policy and verifies its numeric state. Existing names are not stripped by this option. Reset uses per-volume policy 2 rather than a saved original policy.';
           FPSGain='Legacy software / filename compatibility';
           Check={ GO-TestDWord 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'NtfsDisable8dot3NameCreation' 1 };
           Apply={ GO-InvokeNative 'fsutil.exe' @('behavior','set','disable8dot3','1') | Out-Null };
           Revert={ GO-InvokeNative 'fsutil.exe' @('behavior','set','disable8dot3','2') | Out-Null } }
        @{ Id=24; Group="Filesystem / Storage"; Risk=1; NeedsReboot=$true;
           Label="Experimental NVMe Feature Override (26100+)";
           SimpleShort='Writes an experimental storage setting; a working driver change is not confirmed.';
           SimpleLong='This is an advanced experiment for certain newer Windows builds. It writes a setting related to storage features, but the app cannot confirm that the intended driver feature actually starts. APPLIED must not be read as a proven faster SSD.';
           Impact='Experimental storage configuration; effect unverified';
           ShortDesc='Writes the experimental feature override on build 26100 or newer.';
           LongDesc='Availability is build-gated and readback verifies the managed override only. Native NVMe-driver activation, compatibility and performance are not verified. The option is not automatically recommended.';
           Available={ $script:GO_hw.Build -ge 26100 };
           UnavailableReason="Experimental override requires Windows build 26100 or later.";
           FPSGain='Experimental storage configuration; effect unverified';
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" "1176759950") -eq 1 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" "1176759950" 1 };
           Revert={ GO-DelReg "HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" "1176759950" } }
        @{ Id=25; Group="Filesystem / Storage"; Risk=0; NeedsReboot=$true;
           Label="Disable Paging Executive";
           SimpleShort='Asks Windows to keep certain system code in memory.';
           SimpleLong='Windows normally chooses what to keep in fast memory and what can wait on storage. This changes a rule for some system code. It does not add RAM or guarantee that a game loads faster, and it can change memory usage.';
           Impact='System memory policy; benefit not measured';
           ShortDesc='Sets DisablePagingExecutive to 1.';
           LongDesc='Changes the Memory Management paging-executive configuration. Stored readback is not proof of a specific memory residency pattern, RAM amount saved/used, or game-performance gain. Reset uses the module reset value.';
           FPSGain='System memory policy; benefit not measured';
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive") -eq 1 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" 1 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" 0 } }
        @{ Id=26; Group="Privacy / Telemetry"; Risk=1; NeedsReboot=$false;
           Label="Disable Telemetry";
           SimpleShort='Requests less Windows diagnostic collection and stops one related service.';
           SimpleLong='This changes a diagnostic-data preference and stops one Windows service. It is not a switch that blocks all tracking everywhere. What Windows honors can depend on the Windows edition and other rules, and some features may behave differently.';
           Impact='Privacy / diagnostic-service behavior';
           ShortDesc='Requests AllowTelemetry=0 and stops/disables DiagTrack.';
           LongDesc='Checks the policy request plus DiagTrack startup type and running status. Effective diagnostic limits depend on Windows edition and policy. This does not disable all telemetry, application tracking or internet communication.';
           FPSGain='Privacy / diagnostic-service behavior';
           Check={ $service = Get-Service -Name 'DiagTrack' -EA Stop
                   (GO-GetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry") -eq 0 -and
                   $service.StartType -eq 'Disabled' -and $service.Status -eq 'Stopped' };
           Apply={ GO-SetDW "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
                   Set-Service -Name "DiagTrack" -StartupType Disabled -EA Stop
                   Stop-Service -Name "DiagTrack" -Force -EA Stop };
           Revert={ GO-DelReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry"
                    Set-Service -Name "DiagTrack" -StartupType Automatic -EA Stop } }
        @{ Id=27; Group="Privacy / Telemetry"; Risk=0; NeedsReboot=$false;
           Label="Search History (OFF)";
           SimpleShort='Stops Windows from keeping this device search history.';
           SimpleLong='This turns off one Windows search-history preference on this account. It does not erase every search record from every app or website. Use it for privacy preference, not as a way to improve gaming speed.';
           Impact='Windows search privacy preference';
           ShortDesc='Sets IsDeviceSearchHistoryEnabled to 0.';
           LongDesc='Changes the current-user Windows search-history preference. It is not a complete history cleanup and does not control third-party applications or online account history. Reset enables the preference.';
           FPSGain='Windows search privacy preference';
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDeviceSearchHistoryEnabled") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDeviceSearchHistoryEnabled" 0 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDeviceSearchHistoryEnabled" 1 } }
        @{ Id=28; Group="Privacy / Telemetry"; Risk=0; NeedsReboot=$false;
           Label="Share Across Devices (OFF)";
           SimpleShort='Turns off the managed share-across-devices preference.';
           SimpleLong='If you do not want Windows to share supported app experiences between devices, this switches off that preference. Features that rely on it may stop working. It is not a full network firewall or a guaranteed speed boost.';
           Impact='Cross-device feature availability';
           ShortDesc='Sets CdpSessionUserAuthzPolicy to 0.';
           LongDesc='Changes the current-user cross-device sharing policy value. It does not remove all device communication or verify that every cross-device service is inactive. Reset enables this managed preference.';
           FPSGain='Cross-device feature availability';
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP" "CdpSessionUserAuthzPolicy") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP" "CdpSessionUserAuthzPolicy" 0 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP" "CdpSessionUserAuthzPolicy" 1 } }
        @{ Id=29; Group="Dynamic Lighting"; Risk=0; NeedsReboot=$false;
           Label="Dynamic Lighting (OFF)";
           SimpleShort='Turns off Windows control of supported RGB lighting.';
           SimpleLong='This changes who can manage compatible colored lights on devices. It can be useful if you prefer your device maker software instead. It does not make the lights or hardware faster, and vendor software still needs its own configuration.';
           Impact='RGB lighting control / software compatibility';
           ShortDesc='Disables both managed Windows Dynamic Lighting flags.';
           LongDesc='Checks the two current-user lighting configuration values. This does not configure vendor RGB software or establish that a particular device supports Dynamic Lighting. Reset uses the module enabled values.';
           FPSGain='RGB lighting control / software compatibility';
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Lighting" "AmbientLightingEnabled") -eq 0 -and
                   (GO-GetReg "HKCU:\Software\Microsoft\Lighting" "ControlledByForegroundApp") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Lighting" "AmbientLightingEnabled" 0
                   GO-SetDW "HKCU:\Software\Microsoft\Lighting" "ControlledByForegroundApp" 0 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\Lighting" "AmbientLightingEnabled" 1
                    GO-SetDW "HKCU:\Software\Microsoft\Lighting" "ControlledByForegroundApp" 1 } }
        @{ Id=30; Group="Input & USB Stability"; Risk=1; NeedsReboot=$true; Optional=$true;
           Label="USBHUB3 Selective-Suspend Override (Experimental / Optional)";
           SimpleShort='Tests an advanced USB sleep-related driver setting.';
           SimpleLong='Try this only when investigating a specific USB sleep/wake problem. The app can confirm that it saved the setting, but not that your USB driver uses it. It is optional and does not guarantee a cure for disconnects or faster mouse input.';
           Impact='Experimental USB troubleshooting';
           ShortDesc='Sets USBHUB3 DisableSelectiveSuspend as DWORD 1.';
           LongDesc='Experimental driver override. Readback verifies value presence/type, not driver effect. Apply saves the typed original value; Reset restores that baseline. Excluded from bulk selection and requires explicit opt-in.';
           FPSGain='Experimental USB troubleshooting';
           Available={ Test-Path -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\USBHUB3' };
           UnavailableReason="USBHUB3 service key is absent; no unsupported driver key will be created.";
           Check={ $state = GO-ReadUsbRegistry; $state.Exists -and $state.Kind -eq 'DWord' -and [long]$state.Data -eq 1 };
           Apply={ GO-EnableUsbRegistryOverride };
           Revert={ GO-ResetUsbRegistryOverride } }
        @{ Id=31; Group="Input & USB Stability"; Risk=1; NeedsReboot=$true; Optional=$true;
           Label="USB Root Hubs: Prevent Power-Off (Allow... unchecked)";
           SimpleShort='Stops supported USB hubs from being powered off by this setting.';
           SimpleLong='A USB hub is a junction connecting several USB devices. This removes permission for Windows to power off each currently supported hub to save energy. It can use more power. It does not unplug or restart your mouse, and cannot fix every USB fault.';
           Impact='USB hub power policy / possible battery trade-off';
           ShortDesc='Sets supported present root-hub MSPower_DeviceEnable.Enable=False.';
           LongDesc='Equivalent to leaving Allow the computer to turn off this device to save power unchecked. Baselines are saved by exact provider/device identity. Unsupported hubs block Apply; disconnected originals remain available for a later Reset.';
           FPSGain='USB hub power policy / possible battery trade-off';
           Available={ GO-UsbHubControlAvailable };
           UnavailableReason="One or more present USB root hubs lack unambiguous WMI power control, or no root hub is present.";
           Check={ GO-TestUsbHubPowerOff };
           Apply={ GO-DisableUsbHubPowerOff };
           Revert={ GO-ResetUsbHubPowerOff } }
        @{ Id=32; Group="Input & USB Stability"; Risk=1; NeedsReboot=$false; Optional=$true;
           Label="Filter Keys + activation shortcut (OFF / Optional)";
           SimpleShort='Turns off Filter Keys and the hold-Right-Shift shortcut.';
           SimpleLong='Filter Keys can ignore brief or repeated key presses to help people type. Turn it off only if you do not need that help. The shortcut is disabled too, so holding Right Shift does not enable it accidentally. Reset restores the saved preference.';
           Impact='Keyboard accessibility / accidental activation';
           ShortDesc='Clears Filter Keys ON/shortcut flags via SystemParametersInfo.';
           LongDesc='Preserves acceptance/repeat/bounce timings and unrelated persistent flags. Uses a per-user original-state backup. This is an accessibility choice, not a proven raw-input latency optimization. Optional and excluded from bulk selection.';
           FPSGain='Keyboard accessibility / accidental activation';
           Check={ ((GO-ReadInputState 32).Flags -band 5) -eq 0 };
           Apply={ GO-ApplyInputOption 32 }; Revert={ GO-ResetInputOption 32 } }
        @{ Id=33; Group="Input & USB Stability"; Risk=1; NeedsReboot=$false; Optional=$true;
           Label="Sticky Keys + activation shortcut (OFF / Optional)";
           SimpleShort='Turns off Sticky Keys and the five-Shift-press shortcut.';
           SimpleLong='Sticky Keys lets you press combinations such as Ctrl and another key one at a time. Turn it off only if you do not need that help. Pressing Shift five times will not activate it accidentally. Reset can turn the saved accessibility preference back on.';
           Impact='Keyboard accessibility / accidental activation';
           ShortDesc='Clears Sticky Keys ON/shortcut flags via SystemParametersInfo.';
           LongDesc='Preserves other persistent flags and restores the saved per-user configuration on Reset, not transient latched modifier keys. This is optional accessibility behavior, not a USB-latency fix.';
           FPSGain='Keyboard accessibility / accidental activation';
           Check={ ((GO-ReadInputState 33).Flags -band 5) -eq 0 };
           Apply={ GO-ApplyInputOption 33 }; Revert={ GO-ResetInputOption 33 } }
        @{ Id=34; Group="Input & USB Stability"; Risk=1; NeedsReboot=$false; Optional=$true;
           Label="USB Selective Suspend: active power plan AC + DC (OFF / Optional)";
           SimpleShort='Stops USB selective sleep in the currently selected power plan.';
           SimpleLong='This asks the active power plan to keep USB devices from using this selective sleep feature, both plugged in and on battery. Use it for a specific sleep/wake problem rather than as a normal speed tweak. Switching power plans can change the status again.';
           Impact='USB power-plan troubleshooting / energy use';
           ShortDesc='Sets active-plan USB selective-suspend AC and DC indexes to 0.';
           LongDesc='Saves each edited plan GUID and its separate original AC/DC indexes. Reset restores saved plans and retains missing/failed baselines; it does not deliberately activate an inactive plan. Other power tools can overwrite the policy. Microsoft recommends keeping selective suspend enabled unless troubleshooting.';
           FPSGain='USB power-plan troubleshooting / energy use';
           Check={ $plan=GO-GetUsbPlanState; $plan.AC -eq 0 -and $plan.DC -eq 0 };
           Apply={ GO-DisableUsbPlanSuspend }; Revert={ GO-ResetUsbPlanSuspend } }
        @{ Id=35; Group="Input & USB Stability"; Risk=0; NeedsReboot=$false; Optional=$true;
           Label="Enhance Pointer Precision (OFF / Desktop comfort / Optional)";
           SimpleShort='Makes desktop pointer movement independent of movement speed.';
           SimpleLong='With pointer acceleration off, moving the mouse faster no longer adds this Windows acceleration to desktop pointer movement. This changes how the pointer feels outside games that use genuine Raw Input. It does not change the sensor DPI or make the mouse connection faster.';
           Impact='Desktop pointer feel; no Raw Input/FPS claim';
           ShortDesc='Disables Windows mouse acceleration via SystemParametersInfo.';
           LongDesc='Preserves thresholds and pointer speed while saving the original per-user state. Genuine Raw Mouse Input bypasses Windows pointer ballistics. Reset restores saved settings. Use the separate speed control for an explicit desktop-speed change.';
           FPSGain='Desktop pointer feel; no Raw Input/FPS claim';
           Check={ (GO-ReadInputState 35).Values[2] -eq 0 };
           Apply={ GO-ApplyInputOption 35 }; Revert={ GO-ResetInputOption 35 } }
    )

    # Notes stay visible next to controls, including consequences of Reset.
    $notes = @{
        1 = 'Also sets VBS OFF (#2). Reset enables HVCI + VBS and undoes #2.'
        2 = 'Shared with HVCI (#1). Reset enables VBS and invalidates the combined HVCI-OFF setting.'
        5 = 'Replaces the active power plan. Reset selects Balanced, including after the separate Ultimate Performance module.'
        9 = 'Replaces AAA mode (#10). Only one priority preset can be active. Reset selects 38 (0x26).'
        10 = 'Replaces Competitive mode (#9). Only one priority preset can be active. Reset selects 38 (0x26).'
        13 = 'Reset disables Game Mode. Keep Game Mode enabled on AMD X3D systems.'
        14 = 'Legacy flags only; not the Windows 11 windowed-games optimization switch.'
        16 = 'Active physical Ethernet/Wi-Fi only. Changing adapters can change this status; VPNs are excluded.'
        17 = 'Changes global TCP/offload settings. VPN, NIC and tuning software may also manage these values.'
        22 = 'May affect timestamp-based backup/archive tools.'
        23 = 'Global policy for all volumes. Legacy installers may need 8.3 names. Reset uses per-volume policy (2).'
        24 = 'Experimental registry override only; native-driver activation is not verified.'
        26 = 'Policy request + DiagTrack service configuration; effective telemetry limits depend on Windows edition.'
        30 = 'Manual opt-in; excluded from bulk selection. DWORD presence does not prove USBHUB3 driver effect. Reset restores your saved value.'
        31 = 'Manual opt-in; excluded from bulk selection. Allow the computer to turn off this device to save power = UNCHECKED on all present root hubs. Reset restores each saved hub. New hubs need Recheck/Apply.'
        32 = 'Optional accessibility change, never bulk-selected. Do not disable a feature you need. Current Windows user only; Reset restores original preferences.'
        33 = 'Optional accessibility change, never bulk-selected. Prevents accidental activation; no latency claim. Current Windows user only.'
        34 = 'Current plan AC/DC only. Switching plans changes status. Ultimate Performance can overwrite this policy. Reset restores saved plans, not an assumed default.'
        35 = 'Desktop/non-Raw input only. Does NOT improve genuine Raw Mouse Input. Manual opt-in; Reset restores original values.'
    }
    foreach ($tweak in $script:GO_tweaks) {
        if ($notes.ContainsKey($tweak.Id)) { $tweak.Note = $notes[$tweak.Id] }
        if ($tweak.NeedsReboot) { $tweak.Note = ("$($tweak.Note) Restart required; APPLIED verifies stored configuration.").Trim() }
    }

    function Global:GO-GetRiskColor {
        param($Risk)
        switch ($Risk) { 0{return Get-PowerToolsBrush "Success"} 1{return Get-PowerToolsBrush "Warning"} 2{return Get-PowerToolsBrush "Danger"} }
    }
    function Global:GO-GetRiskLabel { param($Risk) switch ($Risk) { 0{"LOW"} 1{"MODERATE"} 2{"HIGH"} } }

    function Global:GO-UpdateApplyState {
        $selected=@($script:GO_tweaks | Where-Object { $cb=$script:GO_checkboxes[$_.Id];$cb -and $cb.IsEnabled -and $cb.IsChecked })
        $script:GO_applyBtn.IsEnabled=$selected.Count -gt 0
        $scope=if(@($selected | Where-Object { -not $_.Optional }).Count -eq 0){'input/USB stability or comfort '}else{''}
        $script:GO_estimate.Text=if($selected.Count){"$($selected.Count) ${scope}change(s) selected. No FPS or latency improvement is guaranteed."}else{'No changes selected. Read the descriptions and choose only what you need.'}
        if($script:GO_impactText){
            $notes=@($selected | Where-Object Note | ForEach-Object {"#$($_.Id): $($_.Note)"})
            $script:GO_impactText.Text=if($notes.Count){$notes -join "`n"}else{'APPLIED means the requested configuration is present, including OFF targets. Restart may still be required.'}
        }
    }
    function Global:GO-SelectTweaks {
        param([ValidateSet('All','Missing','Safe','None','Recommended')][string]$Mode)
        # Deterministic order; bulk selections preserve already active mutex presets.
        foreach ($cb in $script:GO_checkboxes.Values) { if ($cb.IsEnabled) { $cb.IsChecked = $false } }
        $chosenGroups = @{}
        foreach ($t in $script:GO_tweaks) {
            $cb = $script:GO_checkboxes[$t.Id]
            if (-not $cb -or -not $cb.IsEnabled -or $Mode -eq 'None') { continue }
            if ($t.Optional) { continue }
            if ($Mode -eq 'Safe' -and $t.Risk -ne 0) { continue }
            if ($Mode -eq 'Recommended' -and -not (GO-IsRecommended $t.Id)) { continue }
            if ($t.Mutex) {
                $activeSibling = $script:GO_tweaks | Where-Object {
                    $_.Id -ne $t.Id -and $_.Mutex -eq $t.Mutex -and $script:GO_states[$_.Id].Applied
                }
                if ($activeSibling -or $chosenGroups.ContainsKey($t.Mutex)) { continue }
                $chosenGroups[$t.Mutex] = $t.Id
            }
            $cb.IsChecked = $true
        }
        GO-UpdateApplyState
    }

    function Global:GO-HandleMutex {
        param($ChangedId, $IsChecked)
        if (-not $IsChecked) { return }
        $tweak = $script:GO_tweaks | Where-Object { $_.Id -eq $ChangedId } | Select-Object -First 1
        if (-not $tweak -or -not $tweak.Mutex) { return }
        foreach ($t in $script:GO_tweaks) {
            if ($t.Id -ne $ChangedId -and $t.Mutex -eq $tweak.Mutex -and $script:GO_checkboxes.ContainsKey($t.Id)) {
                $script:GO_checkboxes[$t.Id].IsChecked = $false
            }
        }
        GO-UpdateApplyState
    }

    function Global:GO-NewText {
        param([string]$Text, [int]$Size=12, [string]$Brush='TextDark', [switch]$Bold)
        $label = [System.Windows.Controls.TextBlock]::new()
        $label.Text=$Text; $label.FontSize=$Size; $label.TextWrapping='Wrap'
        $label.Foreground=Get-PowerToolsBrush $Brush
        if ($Bold) { $label.FontWeight='SemiBold' }
        return $label
    }

    function Global:GO-AddDescriptionSection {
        param($Panel, [string]$Heading, [string]$Text)
        $headingText=GO-NewText $Heading 10 'Primary' -Bold
        $headingText.Margin='0,10,0,3'
        [void]$Panel.Children.Add($headingText)
        [void]$Panel.Children.Add((GO-NewText $Text 12))
    }

    function Global:GO-GetPresentationState {
        param($Tweak, $States)
        $state=if ($States -and $States.ContainsKey($Tweak.Id)) { $States[$Tweak.Id] } else { GO-GetTweakState $Tweak }
        $status=$state.Status
        if (-not $state.Applied -and $status -eq 'MISSING' -and $Tweak.Mutex -and $States) {
            foreach ($other in $script:GO_tweaks) {
                if ($other.Id -ne $Tweak.Id -and $other.Mutex -eq $Tweak.Mutex -and $States[$other.Id].Applied) { $status='ALTERNATIVE'; break }
            }
        }
        $explanation=switch ($status) {
            'APPLIED' {'The requested configuration is present. For an OFF option, this means the feature is configured OFF. A restart may still be needed.'}
            'MISSING' {'This requested configuration is not present. Your current setting may be a valid default; you do not have to apply every option.'}
            'ALTERNATIVE' {'The other preset is already active. Choosing this one replaces it; both cannot be active together.'}
            'UNAVAILABLE' {'This option cannot be used on the currently detected setup.'}
            default {'The current setting could not be checked. It is unknown, rather than confirmed missing. Apply is blocked.'}
        }
        $brush=if ($state.Applied) {'Success'} elseif ($status -eq 'CHECK ERROR') {'Danger'} else {'Warning'}
        return @{Status=$status;Applied=$state.Applied;Message=$explanation;CheckMessage=$state.Message;Brush=$brush}
    }

    function Global:GO-CreateDetailWindow {
        param($Tweak)
        $presentation=GO-GetPresentationState $Tweak $script:GO_states
        $dw=[System.Windows.Window]::new()
        $dw.Title='Tweak details - ' + $Tweak.Label
        $dw.Width=720; $dw.Height=720; $dw.MinWidth=500; $dw.MinHeight=420
        $dw.FontFamily='Segoe UI'; $dw.WindowStartupLocation='CenterOwner'
        $dw.Background=Get-PowerToolsBrush 'Background'
        foreach($key in $Global:PTS_Brush.Keys){$dw.Resources["Dyn$key"]=$Global:PTS_Brush[$key]}
        $layout=[System.Windows.Controls.Grid]::new(); $layout.Margin=20
        $layout.Background=Get-PowerToolsBrush 'Background'
        foreach ($height in @('*','Auto')) {
            $row=[System.Windows.Controls.RowDefinition]::new();$row.Height=$height;[void]$layout.RowDefinitions.Add($row)
        }
        $scroll=[System.Windows.Controls.ScrollViewer]::new()
        $scroll.VerticalScrollBarVisibility='Auto'; $scroll.HorizontalScrollBarVisibility='Disabled'
        $panel=[System.Windows.Controls.StackPanel]::new();$panel.Margin='0,0,14,0'
        [void]$panel.Children.Add((GO-NewText $Tweak.Group.ToUpper() 11 'Primary' -Bold))
        $title=GO-NewText $Tweak.Label 22 'TextDark' -Bold;$title.Margin='0,8,0,12';[void]$panel.Children.Add($title)
        $status=GO-NewText ('STATUS: ' + $presentation.Status) 14 'TextDark' -Bold
        $status.Name='DetailStatus';[void]$panel.Children.Add($status)
        [void]$panel.Children.Add((GO-NewText $presentation.Message 12 'TextMid'))
        GO-AddDescriptionSection $panel 'IN PLAIN ENGLISH' $(if ($Tweak.SimpleLong) {$Tweak.SimpleLong} else {$Tweak.ShortDesc})
        GO-AddDescriptionSection $panel 'TECHNICAL DETAILS' $Tweak.LongDesc
        GO-AddDescriptionSection $panel 'RISK LEVEL' ((GO-GetRiskLabel $Tweak.Risk) + '. Lower risk does not mean risk-free.')
        GO-AddDescriptionSection $panel 'IMPACT / EXPECTED EFFECT' $(if ($Tweak.Impact) {$Tweak.Impact} else {'Effect depends on your system; no measured improvement is established here.'})
        GO-AddDescriptionSection $panel 'RESTART REQUIRED' $(if ($Tweak.NeedsReboot) {'Yes. APPLIED verifies stored configuration, not that a restart-dependent change is already running.'} else {'No restart is requested by this option. Applications may still need to reload a preference.'})
        if ($Tweak.Note) { GO-AddDescriptionSection $panel 'IMPORTANT BEFORE APPLY / RESET' $Tweak.Note }
        if ($presentation.Status -in @('UNAVAILABLE','CHECK ERROR') -or $Tweak.Id -eq 34) { GO-AddDescriptionSection $panel 'CHECK INFORMATION' $presentation.CheckMessage }
        $scroll.Content=$panel;[void]$layout.Children.Add($scroll)
        $close=[System.Windows.Controls.Button]::new();$close.Content='Close';$close.Padding='20,8';$close.Margin='0,16,0,0';$close.HorizontalAlignment='Right'
        $close.Style=(Get-PowerToolsWindow).FindResource('SecondaryButton')
        $captured=$dw;$close.Add_Click({$captured.Close()}.GetNewClosure())
        [System.Windows.Controls.Grid]::SetRow($close,1);[void]$layout.Children.Add($close)
        $dw.Content=$layout
        return $dw
    }

    function Global:GO-ShowDetailWindow {
        param($Tweak)
        if ($script:GO_detailWindows.ContainsKey($Tweak.Id) -and $script:GO_detailWindows[$Tweak.Id].IsVisible) {
            $script:GO_detailWindows[$Tweak.Id].Close()
        }
        $dw=GO-CreateDetailWindow $Tweak
        $dw.Owner=Get-PowerToolsWindow
        $script:GO_detailWindows[$Tweak.Id]=$dw
        $dw.Show()
    }


    function Global:GO-RenderInputExtras {
        $panel = [System.Windows.Controls.StackPanel]::new()
        $panel.Margin = '8,8,8,8'
        $title = [System.Windows.Controls.TextBlock]::new()
        $title.Text = 'POINTER SPEED - OPTIONAL DESKTOP COMFORT'
        $title.FontWeight = 'Bold'; $title.FontSize = 10; $title.Foreground = Get-PowerToolsBrush 'Primary'
        $panel.Children.Add($title) | Out-Null
        $description = [System.Windows.Controls.TextBlock]::new()
        $description.Text = 'IN PLAIN ENGLISH: Choose how far the desktop pointer moves for the same mouse movement. Moving the slider changes only your target; click Apply Speed to change Windows. This is not mouse-sensor DPI or a game-FPS boost.'
        $description.TextWrapping = 'Wrap'; $description.FontSize = 11; $description.Margin = '0,4,0,4'
        $description.Foreground = Get-PowerToolsBrush 'TextMuted'; $panel.Children.Add($description) | Out-Null
        $null=GO-AddDescriptionSection $panel 'TECHNICAL SUMMARY' 'Current-user desktop/non-Raw pointer speed, range 1-20. Reset restores the saved original. Genuine Raw Input is unaffected. This separate target is not included in saved gaming profiles.'
        $controls = [System.Windows.Controls.WrapPanel]::new()
        $script:GO_speedSlider = [System.Windows.Controls.Slider]::new()
        $script:GO_speedSlider.Minimum=1; $script:GO_speedSlider.Maximum=20; $script:GO_speedSlider.TickFrequency=1
        $script:GO_speedSlider.IsSnapToTickEnabled=$true; $script:GO_speedSlider.Width=220; $script:GO_speedSlider.Margin='0,4,12,4'
        $script:GO_speedLabel = [System.Windows.Controls.TextBlock]::new()
        $script:GO_speedLabel.VerticalAlignment='Center'; $script:GO_speedLabel.Margin='0,0,12,0'
        $script:GO_speedLabel.Foreground=Get-PowerToolsBrush 'TextDark'
        $script:GO_speedApply=[System.Windows.Controls.Button]::new(); $script:GO_speedApply.Content='Apply Speed'
        $script:GO_speedReset=[System.Windows.Controls.Button]::new(); $script:GO_speedReset.Content='Reset Speed'
        foreach ($button in @($script:GO_speedApply,$script:GO_speedReset)) {
            $button.Style=(Get-PowerToolsWindow).FindResource('SecondaryButton'); $button.Padding='12,5'; $button.Margin='0,0,6,4'
        }
        try {
            $current=GO-ReadInputState 36
            $script:GO_speedSlider.Value=$current.Speed
            $script:GO_speedLabel.Text="Current: $($current.Speed)/20 | Target: $($current.Speed)/20"
            $script:GO_speedApply.IsEnabled=$false
            $script:GO_speedReset.IsEnabled=$null -ne (GO-ReadUsbBackup 36)
            $script:GO_speedSlider.Tag=[int]$current.Speed
        } catch {
            $script:GO_speedSlider.IsEnabled=$false; $script:GO_speedApply.IsEnabled=$false; $script:GO_speedReset.IsEnabled=$false
            $script:GO_speedLabel.Text="CHECK ERROR: $_"
        }
        $script:GO_speedSlider.Add_ValueChanged({
            $target=[int]$script:GO_speedSlider.Value
            $script:GO_speedLabel.Text="Current: $($script:GO_speedSlider.Tag)/20 | Target: $target/20"
            $script:GO_speedApply.IsEnabled=$target -ne [int]$script:GO_speedSlider.Tag
        })
        $script:GO_speedApply.Add_Click({
            try {
                if (($script:GO_cbRestore -and $script:GO_cbRestore.IsChecked) -or ($script:GO_cbRegBkp -and $script:GO_cbRegBkp.IsChecked)) {
                    if (-not (GO-CreateBackup -BackupDir (Join-Path ([Environment]::GetFolderPath('Desktop')) 'WindowsAcolyte_Backup'))) { throw 'A selected backup failed; pointer speed was not changed.' }
                }
                GO-ApplyInputOption 36 ([int]$script:GO_speedSlider.Value)
                GO-AddLog 'Desktop pointer speed applied and verified. Raw Mouse Input is unaffected.' 'OK'
            } catch { GO-AddLog "Pointer speed Apply failed: $_" 'FAIL' }
            GO-RenderList
        })
        $script:GO_speedReset.Add_Click({
            $confirmed=[System.Windows.MessageBox]::Show('Restore the original pointer speed saved for this Windows user?','Restore Pointer Speed',[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
            if ($confirmed -ne [System.Windows.MessageBoxResult]::Yes) { return }
            try { GO-ResetInputOption 36; GO-AddLog 'Original desktop pointer speed restored and verified.' 'OK' }
            catch { GO-AddLog "Pointer speed Reset failed: $_" 'FAIL' }
            GO-RenderList
        })
        foreach ($control in @($script:GO_speedSlider,$script:GO_speedLabel,$script:GO_speedApply,$script:GO_speedReset)) { $controls.Children.Add($control) | Out-Null }
        $panel.Children.Add($controls) | Out-Null
        $updateTitle=[System.Windows.Controls.TextBlock]::new()
        $updateTitle.Text='WINDOWS UPDATE - READ-ONLY'; $updateTitle.FontSize=10; $updateTitle.FontWeight='Bold'
        $updateTitle.Foreground=Get-PowerToolsBrush 'Primary'; $updateTitle.Margin='0,12,0,0'
        $panel.Children.Add($updateTitle) | Out-Null
        $null=GO-AddDescriptionSection $panel 'IN PLAIN ENGLISH' 'Read the update records already stored on this PC. This does not search the internet or prove that all updates are installed. Open Windows Update to check with Windows itself.'
        $null=GO-AddDescriptionSection $panel 'TECHNICAL SUMMARY' 'Read-only local Windows Update history and pending-restart status. Availability remains UNKNOWN; this control does not request a scan, installation or restart.'
        $script:GO_updateText=[System.Windows.Controls.TextBlock]::new()
        $script:GO_updateText.Text=if ($script:GO_updateStatus) {$script:GO_updateStatus} else {'WINDOWS UPDATE - local status not read yet. Availability is UNKNOWN; use Read Local Status or open Windows Update.'}
        $script:GO_updateText.TextWrapping='Wrap'; $script:GO_updateText.FontSize=11; $script:GO_updateText.Margin='0,10,0,6'
        $script:GO_updateText.Foreground=Get-PowerToolsBrush 'TextDark'; $panel.Children.Add($script:GO_updateText) | Out-Null
        $buttons=[System.Windows.Controls.WrapPanel]::new()
        $script:GO_updateRefresh=[System.Windows.Controls.Button]::new(); $script:GO_updateRefresh.Content='Read Local Update Status'
        $script:GO_updateOpen=[System.Windows.Controls.Button]::new(); $script:GO_updateOpen.Content='Open Windows Update'
        foreach ($button in @($script:GO_updateRefresh,$script:GO_updateOpen)) {
            $button.Style=(Get-PowerToolsWindow).FindResource('SecondaryButton'); $button.Padding='12,5'; $button.Margin='0,0,6,4'
            $buttons.Children.Add($button) | Out-Null
        }
        $script:GO_updateRefresh.Add_Click({
            try { $script:GO_updateStatus=GO-GetLocalUpdateStatus }
            catch { $script:GO_updateStatus="Local update status unavailable: $_. Update availability remains UNKNOWN. No online scan was started." }
            $script:GO_updateText.Text=$script:GO_updateStatus
        })
        $script:GO_updateOpen.Add_Click({
            try { GO-OpenWindowsUpdate; GO-AddLog 'Opened Windows Update settings; no scan/install/restart requested by the tool.' 'INFO' }
            catch { GO-AddLog "Could not open Windows Update: $_" 'FAIL' }
        })
        $panel.Children.Add($buttons) | Out-Null
        $script:GO_tweakList.Items.Add($panel) | Out-Null
    }

    function Global:GO-RenderList {
        param($States)
        $script:GO_states=if ($States) {$States} else {GO-GetStateSnapshot}
        $script:GO_tweakList.Items.Clear();$script:GO_checkboxes.Clear();$script:GO_cardViews=@{};$lastGroup=''
        $guide=[System.Windows.Controls.Border]::new();$guide.Padding=14;$guide.Margin='8,4,8,10';$guide.CornerRadius=8
        $guide.Background=Get-PowerToolsBrush 'AccentSoft';$guide.BorderBrush=Get-PowerToolsBrush 'Accent';$guide.BorderThickness=1
        $guidePanel=[System.Windows.Controls.StackPanel]::new()
        [void]$guidePanel.Children.Add((GO-NewText 'HOW TO READ THIS PAGE' 12 'TextDark' -Bold))
        [void]$guidePanel.Children.Add((GO-NewText 'APPLIED = the requested setting is present (including OFF settings). MISSING = that target is not present, not necessarily a problem. ALTERNATIVE = another exclusive preset is active. UNAVAILABLE / CHECK ERROR = cannot apply or cannot verify.' 12))
        $guideNote=GO-NewText 'Checkboxes select pending changes; they are not on/off switches. Risk describes possible downsides, not FPS benefit. Low risk is not risk-free. Restart labels matter even when a setting says APPLIED.' 11 'TextMid';$guideNote.Margin='0,8,0,0';[void]$guidePanel.Children.Add($guideNote)
        $guide.Child=$guidePanel;[void]$script:GO_tweakList.Items.Add($guide)
        foreach ($t in $script:GO_tweaks) {
            if ($t.Group -ne $lastGroup) {
                $heading=GO-NewText $t.Group.ToUpper() 15 'Primary' -Bold;$heading.Margin='8,18,8,6'
                [void]$script:GO_tweakList.Items.Add($heading);$lastGroup=$t.Group
            }
            $state=$script:GO_states[$t.Id]
            $presentation=GO-GetPresentationState $t $script:GO_states
            $isOk=$state.Applied
            $card=[System.Windows.Controls.Border]::new();$card.Padding=14;$card.Margin='8,4,8,6';$card.CornerRadius=8;$card.BorderThickness=1
            $card.Background=Get-PowerToolsBrush 'Surface';$card.BorderBrush=Get-PowerToolsBrush 'Border';$card.Tag=$t.Id
            $content=[System.Windows.Controls.StackPanel]::new()
            $header=[System.Windows.Controls.Grid]::new()
            foreach ($width in @('112','26','*')) {$col=[System.Windows.Controls.ColumnDefinition]::new();$col.Width=$width;[void]$header.ColumnDefinitions.Add($col)}
            $badge=[System.Windows.Controls.Border]::new();$badge.Padding='7,5';$badge.Margin='0,0,10,0';$badge.CornerRadius=4;$badge.BorderThickness='4,1,1,1'
            $badge.VerticalAlignment='Top';$badge.BorderBrush=Get-PowerToolsBrush $presentation.Brush
            $badge.ToolTip=$presentation.Message
            $status=GO-NewText $presentation.Status 10 'TextDark' -Bold;$status.Name='TweakStatus';$badge.Child=$status
            [System.Windows.Controls.Grid]::SetColumn($badge,0);[void]$header.Children.Add($badge)
            $cb=[System.Windows.Controls.CheckBox]::new();$cb.Tag=$t.Id;$cb.Margin='0,5,6,0';$cb.VerticalAlignment='Top'
            $cb.ToolTip='Select this target for Apply Selected. This checkbox does not show the current Windows on/off state.'
            [System.Windows.Automation.AutomationProperties]::SetName($cb,('Select change: ' + $t.Label))
            if ($isOk -or $state.Status -in @('UNAVAILABLE','CHECK ERROR')) {$cb.IsEnabled=$false}
            else {
                $capturedId=$t.Id
                $cb.Add_Checked({param($s,$e) GO-HandleMutex -ChangedId $capturedId -IsChecked $true;GO-UpdateApplyState}.GetNewClosure())
                $cb.Add_Unchecked({GO-UpdateApplyState})
            }
            [System.Windows.Controls.Grid]::SetColumn($cb,1);[void]$header.Children.Add($cb)
            $title=GO-NewText $t.Label 14 'TextDark' -Bold;$title.Cursor=[System.Windows.Input.Cursors]::Hand;$title.ToolTip='Open simple and technical details'
            $capturedTweak=$t;$title.Add_MouseLeftButtonUp({param($s,$e) GO-ShowDetailWindow $capturedTweak;$e.Handled=$true}.GetNewClosure())
            [System.Windows.Controls.Grid]::SetColumn($title,2);[void]$header.Children.Add($title)
            [void]$content.Children.Add($header)
            $metadata=[System.Windows.Controls.WrapPanel]::new();$metadata.Margin='0,9,0,0'
            foreach ($value in @("RISK: $(GO-GetRiskLabel $t.Risk)", "RESTART: $(if($t.NeedsReboot){'Required'}else{'Not requested'})", "SELECTION: $(if($t.Optional){'Manual opt-in'}else{'Standard'})")) {
                $item=GO-NewText $value 10 'TextDark' -Bold;$item.Margin='0,0,18,4';[void]$metadata.Children.Add($item)
            }
            [void]$content.Children.Add($metadata)
            GO-AddDescriptionSection $content 'IN PLAIN ENGLISH' $(if($t.SimpleShort){$t.SimpleShort}else{$t.ShortDesc})
            GO-AddDescriptionSection $content 'TECHNICAL SUMMARY' $t.ShortDesc
            GO-AddDescriptionSection $content 'IMPACT / EXPECTED EFFECT' $(if($t.Impact){$t.Impact}else{'Effect depends on your system; no measured improvement is established here.'})
            $noteText=if($state.Status -in @('UNAVAILABLE','CHECK ERROR') -or ($t.Id -eq 34 -and $t.Optional)){$state.Message}else{$t.Note}
            if ($noteText) {GO-AddDescriptionSection $content 'IMPORTANT BEFORE APPLY / RESET' $noteText}
            $actions=[System.Windows.Controls.WrapPanel]::new();$actions.Margin='0,12,0,0'
            $details=[System.Windows.Controls.Button]::new();$details.Content='Details';$details.Padding='12,5';$details.Margin='0,0,8,0';$details.Style=(Get-PowerToolsWindow).FindResource('SecondaryButton')
            $capturedTweak2=$t;$details.Add_Click({GO-ShowDetailWindow $capturedTweak2}.GetNewClosure());[void]$actions.Children.Add($details)
            $usbBackup=$null
            if($t.Optional){try{$usbBackup=GO-ReadUsbBackup $t.Id}catch{}}
            if($isOk -or $null -ne $usbBackup){
                $reset=[System.Windows.Controls.Button]::new();$reset.Content='Reset';$reset.Padding='12,5';$reset.Style=(Get-PowerToolsWindow).FindResource('SecondaryButton')
                if($t.Optional -and -not $usbBackup){$reset.IsEnabled=$false;$reset.ToolTip='No original state saved by WindowsAcolyte; this pre-existing setting will not be reset.'}
                $capturedTweak3=$t
                $reset.Add_Click({
                    $resetInfo=if($capturedTweak3.Optional){'Restore the saved original input/USB configuration. Disconnected hubs or missing plans keep their baseline for a later retry. Accessibility Reset may re-enable previously active assistive features.'}else{'Reset may also affect settings sharing the same values. Original pre-app values are not restored.'}
                    $r=[System.Windows.MessageBox]::Show("Reset '$($capturedTweak3.Label)'?`n`n$($capturedTweak3.Note)`n`n$resetInfo",'Confirm Reset',[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
                    if($r -eq [System.Windows.MessageBoxResult]::Yes){
                        $before=GO-GetStateSnapshot
                        try{GO-ResetTweak $capturedTweak3;GO-AddLog "Reset: $($capturedTweak3.Label)" 'OK'}catch{GO-AddLog "Reset failed: $($capturedTweak3.Label) - $_" 'FAIL'}
                        $after=GO-GetStateSnapshot;GO-LogStateChanges $before $after "Reset '$($capturedTweak3.Label)'";GO-RenderList -States $after
                    }
                }.GetNewClosure())
                [void]$actions.Children.Add($reset)
            }
            [void]$content.Children.Add($actions);$card.Child=$content
            [void]$script:GO_tweakList.Items.Add($card);$script:GO_cardViews[$t.Id]=$card;$script:GO_checkboxes[$t.Id]=$cb
        }
        if($script:GO_tweaks.Id -contains 35){GO-RenderInputExtras}
        GO-UpdateApplyState
    }


    function Global:GO-ApplyRecommendedPreselection {
        GO-SelectTweaks -Mode Recommended
    }

    function Global:GO-CreateBackup {
        param([string]$BackupDir)
        $success = $true
        try {
            if (-not (Test-Path -LiteralPath $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force -EA Stop | Out-Null }
        } catch { GO-AddLog "Backup directory failed: $_" 'FAIL'; return $false }
        $ts = Get-Date -Format "yyyyMMdd_HHmmss"
        if ($script:GO_cbRestore.IsChecked) {
            try { GO-AddLog "Creating System Restore Point..." "INFO"
                  Enable-ComputerRestore -Drive "$env:SystemDrive\" -EA Stop
                  $description = "WindowsAcolyte_GameOptimizer_$ts"
                  Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS" -EA Stop
                  $created = Get-ComputerRestorePoint -EA Stop | Where-Object { $_.Description -eq $description }
                  if (-not $created) { throw 'Restore point was not created; Windows may enforce a creation-frequency limit.' }
                  GO-AddLog "Restore point created and verified." "OK" } catch { $success=$false; GO-AddLog "Restore point failed: $_" "FAIL" }
        }
        if ($script:GO_cbRegBkp.IsChecked) {
            try { GO-AddLog "Exporting Registry backup..." "INFO"
                  GO-InvokeNative 'reg.exe' @('export','HKLM',(Join-Path $BackupDir "HKLM_$ts.reg"),'/y') | Out-Null
                  GO-InvokeNative 'reg.exe' @('export','HKCU',(Join-Path $BackupDir "HKCU_$ts.reg"),'/y') | Out-Null
                  GO-AddLog "Registry exported to: $BackupDir" "OK" } catch { $success=$false; GO-AddLog "Registry backup failed: $_" "FAIL" }
        }
        return $success
    }

    function Global:GO-GetProfileSelection {
        $states = GO-GetStateSnapshot
        $pending = @($script:GO_tweaks | Where-Object {
            $cb = $script:GO_checkboxes[$_.Id]
            $cb -and $cb.IsEnabled -and $cb.IsChecked
        })
        foreach ($t in $script:GO_tweaks) {
            if ($pending.Id -contains $t.Id) { $t.Id; continue }
            if (-not $states[$t.Id].Applied) { continue }
            if ($t.Mutex -and ($pending | Where-Object { $_.Mutex -eq $t.Mutex })) { continue }
            $t.Id
        }
    }

    function Global:GO-ApplyProfileSelection {
        param($Data)
        if ($Data.PSObject.Properties.Name -notcontains 'SelectedTweakIds') { throw 'Profile has no SelectedTweakIds array.' }
        $ids = @()
        foreach ($rawId in $Data.SelectedTweakIds) {
            $id = 0
            if (-not [int]::TryParse([string]$rawId, [ref]$id) -or $id -notin $script:GO_tweaks.Id) {
                throw "Profile contains an unknown tweak ID: $rawId"
            }
            if ($id -notin $ids) { $ids += $id }
        }
        $conflicts = @($script:GO_tweaks | Where-Object { $_.Id -in $ids -and $_.Mutex } | Group-Object Mutex | Where-Object Count -gt 1)
        if ($conflicts.Count) { throw 'Profile contains mutually exclusive priority presets. Select only one mode.' }
        $settings = @{}
        foreach ($mapping in @(@('CreateRestorePoint','GO_cbRestore'),@('ExportRegistry','GO_cbRegBkp'),@('PromptReboot','GO_cbAutoReb'))) {
            if ($Data.Settings -and $Data.Settings.PSObject.Properties.Name -contains $mapping[0]) {
                if ($Data.Settings.($mapping[0]) -isnot [bool]) { throw "Profile setting must be Boolean: $($mapping[0])" }
                $settings[$mapping[1]] = $Data.Settings.($mapping[0])
            }
        }
        foreach ($cb in $script:GO_checkboxes.Values) { if ($cb.IsEnabled) { $cb.IsChecked = $false } }
        $loaded = 0; $skipped = 0
        foreach ($id in $ids) {
            if ($script:GO_checkboxes.ContainsKey($id) -and $script:GO_checkboxes[$id].IsEnabled) {
                $script:GO_checkboxes[$id].IsChecked = $true; $loaded++
            } else { $skipped++ }
        }
        foreach ($setting in $settings.Keys) { (Get-Variable -Scope Script -Name $setting -ValueOnly).IsChecked = $settings[$setting] }
        GO-UpdateApplyState
        return @{Loaded=$loaded; Skipped=$skipped}
    }

    function Global:GO-SaveProfile {
        $sfd = New-Object Microsoft.Win32.SaveFileDialog
        $sfd.Title = "Save Gaming Optimizer Profile"; $sfd.Filter = "JSON Profile (*.json)|*.json"
        $sfd.FileName = "GamingProfile_$(Get-Date -Format 'yyyyMMdd').json"; $sfd.InitialDirectory = $script:GO_profilePath
        if ($sfd.ShowDialog() -ne $true) { return }
        $selected = @(GO-GetProfileSelection)
        try {
            @{ Version="2.0"; Created=(Get-Date).ToString("o")
               Hardware=@{CPU=$script:GO_hw.CPU;GPU=$script:GO_hw.GPU;RAMGB=$script:GO_hw.RAMGB;Build=$script:GO_hw.Build}
               SelectedTweakIds=$selected
               Settings=@{CreateRestorePoint=$script:GO_cbRestore.IsChecked;ExportRegistry=$script:GO_cbRegBkp.IsChecked;PromptReboot=$script:GO_cbAutoReb.IsChecked}
            } | ConvertTo-Json -Depth 5 | Out-File -FilePath $sfd.FileName -Encoding UTF8
            GO-AddLog "Profile saved: $($sfd.FileName)" "OK"
        } catch { GO-AddLog "Save failed: $_" "FAIL" }
    }

    function Global:GO-LoadProfile {
        $ofd = New-Object Microsoft.Win32.OpenFileDialog
        $ofd.Title = "Load Gaming Optimizer Profile"; $ofd.Filter = "JSON Profile (*.json)|*.json"; $ofd.InitialDirectory = $script:GO_profilePath
        if ($ofd.ShowDialog() -ne $true) { return }
        try {
            $pd = Get-Content -Path $ofd.FileName -Raw | ConvertFrom-Json
            $result = GO-ApplyProfileSelection $pd
            GO-AddLog "Profile loaded. Selected: $($result.Loaded)  Already applied/unavailable: $($result.Skipped)" "OK"
            if ($pd.Hardware) { GO-AddLog "Profile from: $($pd.Hardware.CPU) / $($pd.Hardware.GPU)" "INFO" }
        } catch { GO-AddLog "Load failed: $_" "FAIL" }
    }

    function Global:GO-RevertAll {
        $res = [System.Windows.MessageBox]::Show("Reset all managed settings to the module's reset presets?`n`nThis enables HVCI/VBS, switches to Balanced, resets priority to 38 (0x26) and removes custom network settings. Shared settings and the separate Ultimate Performance module's active plan are affected. Optional input/USB controls instead restore saved original states only; no backup means unchanged. This includes pointer speed and may re-enable previously active accessibility features. Missing hubs/plans retain their baseline.`n`nContinue?","Confirm Reset",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
        if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }
        $before = GO-GetStateSnapshot
        GO-AddLog "Resetting all managed settings..." "INFO"
        $ok=0; $fail=0; $reboot=$false
        $resetTargets = @($script:GO_tweaks) + @(@{Id=36;Label='Desktop pointer speed';Optional=$true;Revert={GO-ResetInputOption 36}})
        foreach ($t in $resetTargets) {
            try {
                if ($t.Optional -and -not (GO-ReadUsbBackup $t.Id)) {
                    GO-AddLog "Reset skipped: $($t.Label) - no saved original state." 'INFO'
                    continue
                }
                GO-ResetTweak $t; GO-AddLog "Reset: $($t.Label)" "OK"; $ok++; if ($t.NeedsReboot) { $reboot=$true }
            }
            catch { GO-AddLog "Revert failed: $($t.Label) - $_" "FAIL"; $fail++ }
        }
        GO-AddLog "Reset complete. Success: $ok  Failed: $fail" "INFO"
        $after = GO-GetStateSnapshot
        GO-LogStateChanges $before $after 'Reset all'
        if ($reboot -and $script:GO_cbAutoReb.IsChecked) {
            $r=[System.Windows.MessageBox]::Show("Some reverted settings require a reboot. Restart now?","Reboot Required",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
            if ($r -eq [System.Windows.MessageBoxResult]::Yes) { Start-Sleep -Seconds 3; Restart-Computer -Force }
        }
        GO-RenderList -States $after
    }

    GO-RenderList
    GO-ApplyRecommendedPreselection
    GO-AddLog "Status check complete. Pre-selection applied based on detected hardware - please verify before applying." "INFO"

    $script:GO_selAll.Add_Click({ GO-SelectTweaks All })
    $script:GO_selMissing.Add_Click({ GO-SelectTweaks Missing })
    $script:GO_selSafe.Add_Click({ GO-SelectTweaks Safe })
    $script:GO_selNone.Add_Click({ GO-SelectTweaks None })
    $script:GO_recheckBtn.Add_Click({ GO-RenderList; GO-AddLog "Rechecked all tweaks." "INFO" })
    $script:GO_loadProfBtn.Add_Click({ GO-LoadProfile })
    $script:GO_saveProfBtn.Add_Click({ GO-SaveProfile })
    $script:GO_revertBtn.Add_Click({ GO-RevertAll })

    $script:GO_applyBtn.Add_Click({
        $selected = $script:GO_tweaks | Where-Object { $cb=$script:GO_checkboxes[$_.Id]; $cb -and $cb.IsChecked -eq $true -and $cb.IsEnabled }
        if (-not $selected) { GO-AddLog "Nothing selected." "WARN"; return }
        $conflicts = @($selected | Where-Object { $_.Mutex } | Group-Object Mutex | Where-Object { $_.Count -gt 1 })
        if ($conflicts.Count -gt 0) {
            GO-AddLog "Select only one Win32PrioritySeparation preset before applying." "FAIL"
            return
        }
        $accessibility = @($selected | Where-Object { $_.Id -in @(32,33) })
        if ($accessibility.Count) {
            $names = ($accessibility.Label) -join "`n- "
            $answer=[System.Windows.MessageBox]::Show("Optional accessibility changes for the current Windows user:`n`n- $names`n`nThese features and their activation shortcuts will be turned OFF. Do not continue if you need them. This is not a proven Raw Input latency boost. Original preferences will be saved for Reset.`n`nContinue?",'Accessibility Warning',[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Warning)
            if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { GO-AddLog 'Accessibility changes cancelled; nothing applied.' 'INFO'; return }
        }
        $highRisk = $selected | Where-Object { $_.Risk -eq 2 }
        if ($highRisk) {
            $names = ($highRisk | ForEach-Object { $_.Label }) -join "`n- "
            $r=[System.Windows.MessageBox]::Show("You selected HIGH RISK tweaks:`n`n- $names`n`nThese can compromise system security. Continue?","High Risk Warning",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Warning)
            if ($r -ne [System.Windows.MessageBoxResult]::Yes) { GO-AddLog "Cancelled by user." "WARN"; return }
        }
        if ($script:GO_cbRestore.IsChecked -or $script:GO_cbRegBkp.IsChecked) {
            if (-not (GO-CreateBackup -BackupDir (Join-Path ([Environment]::GetFolderPath('Desktop')) 'WindowsAcolyte_Backup'))) {
                GO-AddLog 'Apply cancelled because a selected backup failed. Review backup options before retrying.' 'FAIL'
                return
            }
        }
        $before = GO-GetStateSnapshot
        GO-AddLog "Applying $($selected.Count) tweak(s)..." "INFO"
        $ok=0; $fail=0; $needsReboot=$false
        foreach ($t in $selected) {
            try { GO-ApplyVerifiedTweak -Tweak $t; GO-AddLog "[$($t.Id.ToString().PadLeft(2))] $($t.Label) - verified" "OK"; $ok++; if ($t.NeedsReboot) { $needsReboot=$true } }
            catch { GO-AddLog "[$($t.Id.ToString().PadLeft(2))] $($t.Label) - $_" "FAIL"; $fail++ }
        }
        GO-AddLog "Applied: $ok  Failed: $fail" "INFO"
        $after = GO-GetStateSnapshot
        GO-LogStateChanges $before $after 'Apply selection'
        if ($needsReboot -and $script:GO_cbAutoReb.IsChecked) {
            GO-AddLog "Reboot required for some tweaks." "WARN"
            $res=[System.Windows.MessageBox]::Show("Some settings require a reboot.`n`nRestart now?","Reboot Required",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
            if ($res -eq [System.Windows.MessageBoxResult]::Yes) { GO-AddLog "Restarting in 5 seconds..." "WARN"; Start-Sleep -Seconds 5; Restart-Computer -Force }
        }
        GO-RenderList -States $after
    })

    $script:GO_clearLog.Add_Click({ $script:GO_logBox.Text=""; GO-AddLog "Log cleared." "INFO" })
    return $view
}
