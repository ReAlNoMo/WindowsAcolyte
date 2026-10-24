# Module: Windows 11 Gaming Optimizer v2.0
# Comprehensive gaming tweaks with profile support, backup, and detailed info.

Register-PowerToolsModule `
    -Id            "gaming-optimizer" `
    -Name          "Windows 11 Gaming Optimizer" `
    -Description   "Apply curated gaming and performance tweaks. Profile save/load, backup, and detailed info included." `
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
            <Button Grid.Column="1" x:Name="SoftwareInfoBtn" Content="Recommended Tools"
                    Style="{DynamicResource SecondaryButton}" Padding="12,6"
                    FontSize="11" VerticalAlignment="Center" Margin="10,0,0,0"/>
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

    <!-- ROW 2: Selection toolbar -->
    <Grid Grid.Row="2" Margin="0,0,0,6">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock Grid.Column="0" Text="SELECT:" Foreground="{DynamicResource DynSectionLabel}"
                   FontSize="10" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,8,0"/>
        <Button Grid.Column="1" x:Name="SelectAllBtn" Content="All"
                Style="{DynamicResource SecondaryButton}" Padding="10,5" FontSize="11" Margin="0,0,4,0"/>
        <Button Grid.Column="2" x:Name="SelectMissingBtn" Content="Missing Only"
                Style="{DynamicResource SecondaryButton}" Padding="10,5" FontSize="11" Margin="0,0,4,0"/>
        <Button Grid.Column="3" x:Name="SelectSafeBtn" Content="Safe Only"
                Style="{DynamicResource SecondaryButton}" Padding="10,5" FontSize="11" Margin="0,0,4,0"/>
        <Button Grid.Column="4" x:Name="SelectNoneBtn" Content="None"
                Style="{DynamicResource SecondaryButton}" Padding="10,5" FontSize="11"/>
        <TextBlock Grid.Column="5"/>
        <Button Grid.Column="6" x:Name="LoadProfileBtn" Content="Load Profile"
                Style="{DynamicResource SecondaryButton}" Padding="10,5" FontSize="11" Margin="0,0,4,0"/>
        <Button Grid.Column="7" x:Name="SaveProfileBtn" Content="Save Profile"
                Style="{DynamicResource SecondaryButton}" Padding="10,5" FontSize="11"/>
    </Grid>

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
                           Text="No tweaks selected. All estimates without warranty."/>
                <TextBlock x:Name="ImpactText" FontSize="11" TextWrapping="Wrap" Margin="0,4,0,0"
                           Foreground="{DynamicResource DynTextDark}"
                           Text="APPLIED = configuration verified. Reboot-marked settings may not be effective until restart."/>
            </StackPanel>
            <TextBlock Grid.Column="1" Text="Hover = short info  |  Click name = full details"
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
    $script:GO_softInfoBtn     = $view.FindName("SoftwareInfoBtn")
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
        @{ Id=1; Group="Security - High Impact"; Risk=1; NeedsReboot=$true;
           Label="Memory Integrity / HVCI (OFF)";
           ShortDesc="Disables Hypervisor-Protected Code Integrity. Biggest FPS gainer.";
           LongDesc="Hypervisor-Protected Code Integrity (HVCI) validates every kernel driver access via hypervisor. Disabling yields 3-25% FPS gain, more stable 1% lows, significantly less microstutter in CPU-limited games. Risk: Kernel exploits through manipulated drivers become possible. Acceptable for dedicated gaming PC without sensitive data.";
           FPSGain="3-25% FPS";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled") -eq 0 -and
                   (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity") -eq 0 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 0
                   GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 0 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 1
                    GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 1 } }
        @{ Id=2; Group="Security - High Impact"; Risk=1; NeedsReboot=$true;
           Label="VBS Registry Configuration (OFF)";
           ShortDesc="Sets the VBS registry configuration to OFF; runtime state can differ until reboot or due to policy.";
           LongDesc="Sets EnableVirtualizationBasedSecurity to 0. This does not remove the Virtual Machine Platform Windows feature or override policy/UEFI locks. APPLIED verifies the stored value, not the hypervisor runtime state. Reset enables VBS and invalidates the combined HVCI-off configuration.";
           FPSGain="2-8% FPS";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity") -eq 0 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 0 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 1 } }
        @{ Id=3; Group="Security - High Impact"; Risk=0; NeedsReboot=$true;
           Label="GameDVR / Xbox Recording (OFF)";
           ShortDesc="Disables Xbox Game Bar DVR recording. Frees GPU/CPU resources during gameplay.";
           LongDesc="Xbox Game Bar DVR captures gameplay in background consuming GPU and CPU resources. Disabling yields 2-5% FPS in GPU-limited scenarios. No risk - only removes screen recording. Manual screenshots still work.";
           FPSGain="2-5% FPS";
           Check={ (GO-GetReg "HKCU:\System\GameConfigStore" "GameDVR_Enabled") -eq 0 -and
                   (GO-GetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR") -eq 0 };
           Apply={ GO-SetDW "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
                   GO-SetDW "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0 };
           Revert={ GO-SetDW "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 1
                    GO-DelReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" } }
        @{ Id=4; Group="Security - High Impact"; Risk=2; NeedsReboot=$true;
           Label="Spectre/Meltdown Mitigations (OFF) - HIGH RISK";
           ShortDesc="Disables CPU vulnerability mitigations. +5-15% FPS on older CPUs. SECURITY RISK.";
           LongDesc="Spectre and Meltdown mitigations protect against CPU-level attacks. Disabling yields 5-15% FPS on older CPUs (Intel 6-9th gen). HIGH RISK: Only on isolated gaming PCs without browser or sensitive data access. Not recommended.";
           FPSGain="5-15% FPS";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverride") -eq 3 -and
                   (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverrideMask") -eq 3 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverride" 3
                   GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverrideMask" 3 };
           Revert={ GO-DelReg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverride"
                    GO-DelReg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "FeatureSettingsOverrideMask" } }
        @{ Id=5; Group="Power / CPU"; Risk=0; NeedsReboot=$false;
           Label="Ultimate Performance Power Plan";
           ShortDesc="Activates an Ultimate Performance power plan. Replaces the current active power plan.";
           LongDesc="Activates or creates an Ultimate Performance plan. For explicitly managed CPU/core-parking/display settings, use the separate Ultimate Performance Power Plan module. Reset switches to Balanced, including when the dedicated WindowsAcolyte plan is currently active.";
           FPSGain="5-15% FPS";
           Check={ GO-TestUltimatePlan };
           Apply={ GO-EnableUltimatePlan };
           Revert={ GO-InvokeNative 'powercfg.exe' @('/setactive','SCHEME_BALANCED') | Out-Null } }
        @{ Id=6; Group="Power / CPU"; Risk=1; NeedsReboot=$true;
           Label="Disable Power Throttling";
           ShortDesc="Prevents Windows from throttling CPU for background processes.";
           LongDesc="Windows automatically throttles CPU resources for background processes. Disabling gives all processes full resources - less frame variance. Risk: Background processes can consume more CPU.";
           FPSGain="1-3% FPS";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff") -eq 1 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" 1 };
           Revert={ GO-DelReg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" } }
        @{ Id=7; Group="Power / CPU"; Risk=0; NeedsReboot=$false;
           Label="System Responsiveness = 10";
           ShortDesc="Controls CPU share for multimedia/foreground apps. More CPU cycles for active applications.";
           LongDesc="Controls CPU share for multimedia and foreground applications. Default is 20. Value 10 is moderate and recommended for stability.";
           FPSGain="1-2% FPS";
           Check={ (GO-GetReg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness") -eq 10 };
           Apply={ GO-SetDW "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 10 };
           Revert={ GO-SetDW "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 20 } }
        @{ Id=8; Group="Power / CPU"; Risk=0; NeedsReboot=$false;
           Label="Network Throttling Disabled";
           ShortDesc="Removes network throughput limit. Better network latency and throughput.";
           LongDesc="Windows limits network throughput to save CPU. Disabling improves network latency and throughput.";
           FPSGain="Latency";
           Check={ GO-TestDWord "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" ([uint32]::MaxValue) };
           Apply={ GO-SetDW "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" ([uint32]::MaxValue) };
           Revert={ GO-SetDW "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 10 } }
        @{ Id=9; Group="Power / CPU"; Risk=0; NeedsReboot=$false; Mutex="PrioritySep";
           Label="Win32PrioritySeparation = 36 (Competitive)";
           ShortDesc="Short variable quanta without focus boost. Minimal scheduling latency.";
           LongDesc="Controls CPU time quanta per process before context switch. Value 36 (0x24) uses short variable quanta without focus boost - minimal scheduling latency. Best for competitive shooters.";
           FPSGain="1-3% FPS";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation") -eq 0x24 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 0x24 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 0x26 } }
        @{ Id=10; Group="Power / CPU"; Risk=0; NeedsReboot=$false; Mutex="PrioritySep";
           Label="Win32PrioritySeparation = 24 (AAA Games)";
           ShortDesc="Long fixed quanta (server mode). Maximum consistency for games with many background threads.";
           LongDesc="Value 24 (0x18) uses long fixed quanta in server mode - maximum consistency for AAA games with many background threads.";
           FPSGain="1-3% FPS";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation") -eq 0x18 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 0x18 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 0x26 } }
        @{ Id=11; Group="Power / CPU"; Risk=0; NeedsReboot=$false;
           Label="Startup Delay Disabled";
           ShortDesc="Removes artificial startup delay for autostart apps. Faster desktop after login.";
           LongDesc="Windows artificially delays autostart apps after login. Disabling gives a faster desktop after login.";
           FPSGain="Boot speed";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" 0 };
           Revert={ GO-DelReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" } }
        @{ Id=12; Group="Graphics / Gaming"; Risk=0; NeedsReboot=$true;
           Label="Hardware-Accelerated GPU Scheduling (ON)";
           ShortDesc="GPU manages its own memory and tasks instead of CPU. Required for DLSS 3 Frame Generation.";
           LongDesc="GPU takes over own memory and task management instead of CPU. Reduces system latency by ~2ms, more stable frametimes. Mandatory for DLSS 3 Frame Generation.";
           FPSGain="1-5% FPS";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode") -eq 2 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 1 } }
        @{ Id=13; Group="Graphics / Gaming"; Risk=0; NeedsReboot=$false;
           Label="Windows Game Mode (ON)";
           ShortDesc="Prioritizes game threads. Pauses Windows updates during gaming. REQUIRED for AMD X3D CPUs.";
           LongDesc="Prioritizes game threads and pauses Windows Update downloads during gaming. CRITICAL: Must stay ON for AMD X3D chips.";
           FPSGain="1-5% FPS";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled") -eq 1 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 1 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 0 } }
        @{ Id=14; Group="Graphics / Gaming"; Risk=0; NeedsReboot=$false;
           Label="Legacy Fullscreen Compatibility Flags";
           ShortDesc="Configures legacy GameDVR fullscreen compatibility flags.";
           LongDesc="Sets GameDVR_FSEBehaviorMode=2 and GameDVR_HonorUserFSEBehaviorMode=1. These legacy flags are not the Windows 11 Optimizations for windowed games switch and do not verify flip-model, VRR, or Auto-HDR support.";
           FPSGain="Latency";
           Check={ (GO-GetReg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode") -eq 2 -and
                   (GO-GetReg "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode") -eq 1 };
           Apply={ GO-SetDW "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2
                   GO-SetDW "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 1 };
           Revert={ GO-DelReg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode"
                    GO-DelReg "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" } }
        @{ Id=15; Group="Graphics / Gaming"; Risk=0; NeedsReboot=$false;
           Label="Games Task Scheduling = High";
           ShortDesc="Sets Multimedia scheduler priority for games to High.";
           LongDesc="Sets Multimedia scheduler priority for games to High. More CPU cycles for gaming threads.";
           FPSGain="1% FPS";
           Check={ (GO-GetReg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category") -eq "High" };
           Apply={ GO-SetStr "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "High" };
           Revert={ GO-SetStr "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "Medium" } }
        @{ Id=16; Group="Network"; Risk=1; NeedsReboot=$false;
           Label="Disable Nagle Algorithm";
           ShortDesc="Configures TCP ACK/Nagle values on active physical Ethernet and Wi-Fi adapters.";
           LongDesc="Writes TcpAckFrequency=1, TCPNoDelay=1 and TcpDelAckTicks=0 for active physical Ethernet/Wi-Fi adapters. Does not configure disconnected adapters or VPN tunnels. Games using UDP may not benefit; latency gains are not guaranteed.";
           Available={ @(GO-GetGamingAdapters).Count -gt 0 };
           UnavailableReason="No active physical Ethernet/Wi-Fi adapter. Connect an adapter and recheck.";
           FPSGain="-10-30ms ping";
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
           ShortDesc="Enables RSS, disables RSC/ECN/timestamps. Better network throughput and latency.";
           LongDesc="Multiple netsh optimizations: autotuning=normal, RSS=enabled, RSC=disabled, ECN=disabled, timestamps=disabled.";
           FPSGain="Latency";
           Check={ GO-TestTCPSettings };
           Apply={ foreach ($setting in @('autotuninglevel=normal','rss=enabled','rsc=disabled','ecncapability=disabled','timestamps=disabled')) {
                       GO-InvokeNative 'netsh.exe' @('int','tcp','set','global',$setting) | Out-Null
                   } };
           Revert={ foreach ($setting in @('autotuninglevel=normal','rss=default','rsc=default','ecncapability=default','timestamps=default')) {
                        GO-InvokeNative 'netsh.exe' @('int','tcp','set','global',$setting) | Out-Null
                    } } }
        @{ Id=18; Group="UI / Visual"; Risk=0; NeedsReboot=$false;
           Label="Transparency Effects (OFF)";
           ShortDesc="Disables Windows transparency effects. Less GPU overhead for UI.";
           LongDesc="Windows transparency effects consume GPU resources. Disabling yields minimal FPS gain but reduces UI overhead.";
           FPSGain="0-1% FPS";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 1 } }
        @{ Id=19; Group="UI / Visual"; Risk=0; NeedsReboot=$false;
           Label="Window Animations (OFF)";
           ShortDesc="Disables window minimize/maximize animations. Snappier UI response.";
           LongDesc="Disables window animations for minimize/maximize. Snappier UI response.";
           FPSGain="UI speed";
           Check={ (GO-GetReg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate") -eq "0" };
           Apply={ GO-SetStr "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" };
           Revert={ GO-SetStr "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "1" } }
        @{ Id=20; Group="UI / Visual"; Risk=0; NeedsReboot=$false;
           Label="Menu Show Delay = 0";
           ShortDesc="Removes menu open delay. Instant menu response.";
           LongDesc="Windows has a default 400ms menu show delay. Setting to 0 gives instant menu response.";
           FPSGain="UI speed";
           Check={ (GO-GetReg "HKCU:\Control Panel\Desktop" "MenuShowDelay") -eq "0" };
           Apply={ GO-SetStr "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" };
           Revert={ GO-SetStr "HKCU:\Control Panel\Desktop" "MenuShowDelay" "400" } }
        @{ Id=21; Group="UI / Visual"; Risk=0; NeedsReboot=$false;
           Label="Taskbar Animations (OFF)";
           ShortDesc="Disables taskbar animations. Snappier taskbar response.";
           LongDesc="Disables taskbar animations. Snappier response when hovering or clicking taskbar.";
           FPSGain="UI speed";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 0 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 1 } }
        @{ Id=22; Group="Filesystem / Storage"; Risk=0; NeedsReboot=$true;
           Label="NTFS Disable Last Access Time";
           ShortDesc="Configures NTFS last-access timestamp updates as disabled.";
           LongDesc="Disables last-access timestamp updates. Backup/archiving tools using these timestamps may be affected. Check reads the numeric NTFS configuration, including system-managed disabled state.";
           FPSGain="SSD life";
           Check={ $v = GO-GetReg 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'NtfsDisableLastAccessUpdate'
                   $null -ne $v -and ([long]$v -band 3) -in @(1,3) };
           Apply={ GO-InvokeNative 'fsutil.exe' @('behavior','set','disablelastaccess','1') | Out-Null };
           Revert={ GO-InvokeNative 'fsutil.exe' @('behavior','set','disablelastaccess','0') | Out-Null } }
        @{ Id=23; Group="Filesystem / Storage"; Risk=0; NeedsReboot=$false;
           Label="NTFS Disable 8.3 Filenames";
           ShortDesc="Disables creation of new DOS-compatible 8.3 names on all volumes.";
           LongDesc="Sets global NTFS 8.3-name creation policy to 1 (disabled on all volumes). Existing names are not removed. Legacy programs/installers needing short paths may be affected. Reset selects per-volume policy (2); individual volume flags remain unchanged.";
           FPSGain="Dir listing";
           Check={ GO-TestDWord 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'NtfsDisable8dot3NameCreation' 1 };
           Apply={ GO-InvokeNative 'fsutil.exe' @('behavior','set','disable8dot3','1') | Out-Null };
           Revert={ GO-InvokeNative 'fsutil.exe' @('behavior','set','disable8dot3','2') | Out-Null } }
        @{ Id=24; Group="Filesystem / Storage"; Risk=1; NeedsReboot=$true;
           Label="Experimental NVMe Feature Override (26100+)";
           ShortDesc="Writes an experimental feature override; does not verify native NVMe driver activation.";
           LongDesc="Writes feature override 1176759950=1 on build 26100+. APPLIED only verifies the registry override. Actual driver support and performance effects depend on Windows build, storage hardware and driver. Experimental; never automatically preselected.";
           Available={ $script:GO_hw.Build -ge 26100 };
           UnavailableReason="Experimental override requires Windows build 26100 or later.";
           FPSGain="SSD speed";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" "1176759950") -eq 1 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" "1176759950" 1 };
           Revert={ GO-DelReg "HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" "1176759950" } }
        @{ Id=25; Group="Filesystem / Storage"; Risk=0; NeedsReboot=$true;
           Label="Disable Paging Executive";
           ShortDesc="Prevents kernel/driver code paging to disk. Uses ~32MB more RAM but faster kernel.";
           LongDesc="Prevents paging of kernel and driver code to disk. Minimal risk (~32MB more RAM usage). Faster kernel operations.";
           FPSGain="Kernel speed";
           Check={ (GO-GetReg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive") -eq 1 };
           Apply={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" 1 };
           Revert={ GO-SetDW "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" 0 } }
        @{ Id=26; Group="Privacy / Telemetry"; Risk=1; NeedsReboot=$false;
           Label="Disable Telemetry";
           ShortDesc="Requests telemetry policy level 0 and disables/stops DiagTrack.";
           LongDesc="Sets AllowTelemetry=0 and disables/stops DiagTrack. Supported policy levels depend on the Windows edition; this is not proof that all Windows data collection has stopped. Reset removes the policy and restores automatic service startup.";
           FPSGain="Privacy";
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
           ShortDesc="Disables device search history tracking. Privacy improvement.";
           LongDesc="Disables device search history tracking by Windows Search.";
           FPSGain="Privacy";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDeviceSearchHistoryEnabled") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDeviceSearchHistoryEnabled" 0 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDeviceSearchHistoryEnabled" 1 } }
        @{ Id=28; Group="Privacy / Telemetry"; Risk=0; NeedsReboot=$false;
           Label="Share Across Devices (OFF)";
           ShortDesc="Disables cross-device sharing. Reduces background network activity.";
           LongDesc="Disables Windows cross-device sharing feature (CDP). Reduces background network activity and telemetry.";
           FPSGain="Privacy";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP" "CdpSessionUserAuthzPolicy") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP" "CdpSessionUserAuthzPolicy" 0 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP" "CdpSessionUserAuthzPolicy" 1 } }
        @{ Id=29; Group="Dynamic Lighting"; Risk=0; NeedsReboot=$false;
           Label="Dynamic Lighting (OFF)";
           ShortDesc="Disables Windows 11 Dynamic Lighting for RGB peripherals. Use vendor software instead.";
           LongDesc="Disables Windows 11 Dynamic Lighting for RGB peripherals. Allows vendor software to control RGB without conflicts.";
           FPSGain="Compatibility";
           Check={ (GO-GetReg "HKCU:\Software\Microsoft\Lighting" "AmbientLightingEnabled") -eq 0 -and
                   (GO-GetReg "HKCU:\Software\Microsoft\Lighting" "ControlledByForegroundApp") -eq 0 };
           Apply={ GO-SetDW "HKCU:\Software\Microsoft\Lighting" "AmbientLightingEnabled" 0
                   GO-SetDW "HKCU:\Software\Microsoft\Lighting" "ControlledByForegroundApp" 0 };
           Revert={ GO-SetDW "HKCU:\Software\Microsoft\Lighting" "AmbientLightingEnabled" 1
                    GO-SetDW "HKCU:\Software\Microsoft\Lighting" "ControlledByForegroundApp" 1 } }
        @{ Id=30; Group="Input & USB Stability"; Risk=1; NeedsReboot=$true; Optional=$true;
           Label="USBHUB3 Selective-Suspend Override (Experimental / Optional)";
           ShortDesc="Optional stability experiment: sets USBHUB3 DisableSelectiveSuspend as DWORD 1.";
           LongDesc="Sets HKLM\SYSTEM\CurrentControlSet\Services\USBHUB3\DisableSelectiveSuspend to REG_DWORD 1. Saves the original value/type or absence before writing. This exact service-level override is not reliably documented for all Windows USBHUB3 versions: APPLIED proves the stored DWORD only, not driver behavior. No FPS benefit is claimed. Reset restores the saved original value, never an assumed default.";
           FPSGain="Stability only";
           Available={ Test-Path -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\USBHUB3' };
           UnavailableReason="USBHUB3 service key is absent; no unsupported driver key will be created.";
           Check={ $state = GO-ReadUsbRegistry; $state.Exists -and $state.Kind -eq 'DWord' -and [long]$state.Data -eq 1 };
           Apply={ GO-EnableUsbRegistryOverride };
           Revert={ GO-ResetUsbRegistryOverride } }
        @{ Id=31; Group="Input & USB Stability"; Risk=1; NeedsReboot=$true; Optional=$true;
           Label="USB Root Hubs: Prevent Power-Off (Allow... unchecked)";
           ShortDesc="Optional stability setting: removes permission to power off present USB root hubs.";
           LongDesc="Sets the supported per-device WMI energy-management Enable flag to False for every currently present USB root hub. This corresponds to leaving Allow the computer to turn off this device to save power unchecked. Saves each hub's original Boolean by exact device/provider identity; Reset restores those states. No USB device is disabled, restarted or re-enumerated. Unsupported hubs block Apply; disconnected backup entries are retained until they can be restored. This is distinct from the active power plan's selective-suspend policy. No FPS improvement or guaranteed cure for disconnects is claimed.";
           FPSGain="Stability only";
           Available={ GO-UsbHubControlAvailable };
           UnavailableReason="One or more present USB root hubs lack unambiguous WMI power control, or no root hub is present.";
           Check={ GO-TestUsbHubPowerOff };
           Apply={ GO-DisableUsbHubPowerOff };
           Revert={ GO-ResetUsbHubPowerOff } }
        @{ Id=32; Group="Input & USB Stability"; Risk=1; NeedsReboot=$false; Optional=$true;
           Label="Filter Keys + activation shortcut (OFF / Optional)";
           ShortDesc="Disables Filter Keys and its Right Shift activation shortcut for the current Windows user.";
           LongDesc="Turns off Filter Keys and its activation shortcut using the documented Windows API, not guessed registry flags. Existing acceptance/repeat/bounce timings and unrelated flags are preserved. This is an accessibility preference, not a proven raw-input latency boost. Do not apply if you need this assistive feature. Original settings are saved per Windows user and restored by Reset.";
           FPSGain="No FPS gain claimed";
           Check={ ((GO-ReadInputState 32).Flags -band 5) -eq 0 };
           Apply={ GO-ApplyInputOption 32 }; Revert={ GO-ResetInputOption 32 } }
        @{ Id=33; Group="Input & USB Stability"; Risk=1; NeedsReboot=$false; Optional=$true;
           Label="Sticky Keys + activation shortcut (OFF / Optional)";
           ShortDesc="Disables Sticky Keys and its five-times-Shift activation shortcut for the current Windows user.";
           LongDesc="Turns off Sticky Keys and its activation shortcut, preserving other persistent preferences. Helps prevent accidental activation, not USB latency. Only apply if you do not need this accessibility feature. Reset restores the saved per-user configuration, not transient held/latched modifier keys.";
           FPSGain="No FPS gain claimed";
           Check={ ((GO-ReadInputState 33).Flags -band 5) -eq 0 };
           Apply={ GO-ApplyInputOption 33 }; Revert={ GO-ResetInputOption 33 } }
        @{ Id=34; Group="Input & USB Stability"; Risk=1; NeedsReboot=$false; Optional=$true;
           Label="USB Selective Suspend: active power plan AC + DC (OFF / Optional)";
           ShortDesc="Sets USB selective suspend to Disabled for AC and DC in the currently active power plan.";
           LongDesc="Targets idle/suspend-resume troubleshooting, not a guaranteed improvement during active gaming. Saves each edited power plan's original AC/DC indexes before writing. Repeated Apply after a plan switch captures that plan separately. Reset restores all saved plans and retains the baseline on failures or missing plans. An inactive saved plan is not deliberately activated. The Ultimate Performance module also writes this setting: applying it again can overwrite a restored value. Microsoft recommends leaving selective suspend enabled unless addressing a specific issue.";
           FPSGain="Stability troubleshooting only";
           Check={ $plan=GO-GetUsbPlanState; $plan.AC -eq 0 -and $plan.DC -eq 0 };
           Apply={ GO-DisableUsbPlanSuspend }; Revert={ GO-ResetUsbPlanSuspend } }
        @{ Id=35; Group="Input & USB Stability"; Risk=0; NeedsReboot=$false; Optional=$true;
           Label="Enhance Pointer Precision (OFF / Desktop comfort / Optional)";
           ShortDesc="Disables Windows pointer acceleration for desktop/non-Raw input; does not improve actual Raw Mouse Input.";
           LongDesc="Sets Windows mouse acceleration to off through SystemParametersInfo while preserving both threshold values and pointer speed. This changes desktop/non-Raw pointer behavior only. Genuine Raw Mouse Input bypasses Windows pointer ballistics; no latency, connection or FPS benefit is claimed. Reset restores the original per-user acceleration/threshold values. Use the separate speed control below for an explicit pointer-speed change.";
           FPSGain="Desktop comfort only";
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
    function Global:GO-GetRiskLabel { param($Risk) switch ($Risk) { 0{"SAFE"} 1{"MODERATE"} 2{"HIGH RISK"} } }

    function Global:GO-UpdateApplyState {
        $any = $false; $totalGain = 0.0; $latencyGain = $false; $stabilityOnly = $true
        $impact = @()
        foreach ($id in $script:GO_checkboxes.Keys) {
            if ($script:GO_checkboxes[$id].IsChecked -eq $true -and $script:GO_checkboxes[$id].IsEnabled) {
                $any = $true
                $tweak = $script:GO_tweaks | Where-Object { $_.Id -eq $id } | Select-Object -First 1
                if (-not $tweak.Optional) { $stabilityOnly = $false }
                if ($tweak -and $tweak.FPSGain -match "(\d+)(?:-(\d+))?% FPS") {
                    $low = [double]$Matches[1]; $high = if ($Matches[2]) { [double]$Matches[2] } else { $low }
                    $totalGain += ($low + $high) / 2.0
                }
                if ($tweak -and $tweak.FPSGain -match "Latency|ping") { $latencyGain = $true }
                if ($tweak.Note) { $impact += "#$($tweak.Id): $($tweak.Note)" }
            }
        }
        $script:GO_applyBtn.IsEnabled = $any
        if ($any) {
            $text = if ($stabilityOnly) { 'Input / USB stability or comfort options selected; no FPS gain claimed' } else { "Estimated FPS gain: ~$([math]::Round($totalGain,1))%" }
            if ($latencyGain) { $text += " | Plus latency/ping improvements" }
            $script:GO_estimate.Text = "$text | All estimates without warranty"
        } else { $script:GO_estimate.Text = "No tweaks selected. All estimates without warranty." }
        if ($script:GO_impactText) {
            $script:GO_impactText.Text = if ($impact.Count) { $impact -join "`n" } else {
                'APPLIED = configuration verified. Reboot-marked settings may not be effective until restart.'
            }
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

    function Global:GO-ShowDetailWindow {
        param($Tweak)
        if ($script:GO_detailWindows.ContainsKey($Tweak.Id) -and $script:GO_detailWindows[$Tweak.Id].IsVisible) {
            $script:GO_detailWindows[$Tweak.Id].Activate(); return
        }
        [xml]$dXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tweak Details" Width="560" Height="440"
        WindowStartupLocation="CenterOwner" FontFamily="Segoe UI"
        ResizeMode="CanResize" MinWidth="420" MinHeight="320">
    <Grid Margin="22">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <TextBlock Grid.Row="0" x:Name="DC" Foreground="{DynamicResource DynAccent}" FontSize="10" FontWeight="Bold" Margin="0,0,0,4"/>
        <TextBlock Grid.Row="1" x:Name="DT" FontSize="18" FontWeight="SemiBold" TextWrapping="Wrap" Margin="0,0,0,14"/>
        <Border Grid.Row="2" x:Name="DMB" BorderThickness="1.5" CornerRadius="8" Padding="14,10" Margin="0,0,0,12">
            <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <TextBlock Text="RISK LEVEL" Foreground="{DynamicResource DynSectionLabel}" FontSize="9" FontWeight="Bold" Margin="0,0,0,4"/>
                    <TextBlock x:Name="DR" FontSize="13" FontWeight="SemiBold"/>
                </StackPanel>
                <StackPanel Grid.Column="1">
                    <TextBlock Text="PERFORMANCE GAIN" Foreground="{DynamicResource DynSectionLabel}" FontSize="9" FontWeight="Bold" Margin="0,0,0,4"/>
                    <TextBlock x:Name="DG" Foreground="#2A9D5C" FontSize="13" FontWeight="SemiBold"/>
                </StackPanel>
                <StackPanel Grid.Column="2">
                    <TextBlock Text="REBOOT REQUIRED" Foreground="{DynamicResource DynSectionLabel}" FontSize="9" FontWeight="Bold" Margin="0,0,0,4"/>
                    <TextBlock x:Name="DRB" FontSize="13" FontWeight="SemiBold"/>
                </StackPanel>
            </Grid>
        </Border>
        <Border Grid.Row="3" x:Name="DDB" BorderThickness="1.5" CornerRadius="8" Padding="16,14">
            <ScrollViewer VerticalScrollBarVisibility="Auto">
                <TextBlock x:Name="DLD" FontSize="13" TextWrapping="Wrap" LineHeight="20"/>
            </ScrollViewer>
        </Border>
        <Button Grid.Row="4" x:Name="DCB" Content="Close" Height="38" Padding="20,6" HorizontalAlignment="Right" Margin="0,14,0,0"/>
    </Grid>
</Window>
"@
        $r = New-Object System.Xml.XmlNodeReader $dXaml
        $dw = [Windows.Markup.XamlReader]::Load($r)
        $dw.Resources.Add("SecondaryButton", (Get-PowerToolsWindow).FindResource("SecondaryButton"))
        $dw.Resources.Add("PrimaryButton",   (Get-PowerToolsWindow).FindResource("PrimaryButton"))
        $dw.Owner = Get-PowerToolsWindow
        $dw.Background = $Global:PTS_Brush["Background"]
        $dw.FindName("DT").Foreground  = $Global:PTS_Brush["TextDark"]
        $dw.FindName("DMB").Background = $Global:PTS_Brush["Surface"]; $dw.FindName("DMB").BorderBrush = $Global:PTS_Brush["Border"]
        $dw.FindName("DDB").Background = $Global:PTS_Brush["Surface"]; $dw.FindName("DDB").BorderBrush = $Global:PTS_Brush["Border"]
        $dw.FindName("DLD").Foreground = $Global:PTS_Brush["TextDark"]
        $dw.FindName("DRB").Foreground = $Global:PTS_Brush["TextDark"]
        $dw.FindName("DC").Text  = $Tweak.Group.ToUpper()
        $dw.FindName("DT").Text  = $Tweak.Label
        $dw.FindName("DR").Text  = GO-GetRiskLabel $Tweak.Risk
        $dw.FindName("DR").Foreground = GO-GetRiskColor $Tweak.Risk
        $dw.FindName("DG").Text  = $Tweak.FPSGain
        $dw.FindName("DRB").Text = if ($Tweak.NeedsReboot) { "Yes" } else { "No" }
        $dw.FindName("DLD").Text = ("$($Tweak.LongDesc)`n`n$($Tweak.Note)").Trim()
        $dcb = $dw.FindName("DCB")
        if ($dcb) { $dcb.Style = $dw.FindResource("SecondaryButton"); $capturedDw = $dw; $dcb.Add_Click({ $capturedDw.Close() }.GetNewClosure()) }
        $script:GO_detailWindows[$Tweak.Id] = $dw
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
        $description.Text = 'Current Windows user only. Desktop/non-Raw pointer speed, not mouse DPI or a Raw Input/FPS improvement. Moving the slider only selects a target; Apply Speed changes Windows. Reset restores your saved original. This custom speed target is not saved in gaming profiles.'
        $description.TextWrapping = 'Wrap'; $description.FontSize = 11; $description.Margin = '0,4,0,4'
        $description.Foreground = Get-PowerToolsBrush 'TextMuted'; $panel.Children.Add($description) | Out-Null
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
        $script:GO_states = if ($States) { $States } else { GO-GetStateSnapshot }
        $script:GO_tweakList.Items.Clear(); $script:GO_checkboxes.Clear(); $lastGroup = ""
        foreach ($t in $script:GO_tweaks) {
            if ($t.Group -ne $lastGroup) {
                if ($lastGroup -ne "") {
                    $sep = New-Object System.Windows.Controls.Separator
                    $sep.Margin = "8,4,8,0"; $sep.Background = Get-PowerToolsBrush "Divider"
                    $script:GO_tweakList.Items.Add($sep) | Out-Null
                }
                $hdr = New-Object System.Windows.Controls.TextBlock
                $hdr.Text = $t.Group.ToUpper(); $hdr.Foreground = Get-PowerToolsBrush "Primary"
                $hdr.FontSize = 9; $hdr.FontWeight = "Bold"; $hdr.Margin = "8,10,8,2"
                $script:GO_tweakList.Items.Add($hdr) | Out-Null
                $lastGroup = $t.Group
            }
            $state = $script:GO_states[$t.Id]
            $isOk = $state.Applied
            $isAlternative = $false
            if (-not $isOk -and $t.Mutex) {
                foreach ($other in $script:GO_tweaks) {
                    if ($other.Id -ne $t.Id -and $other.Mutex -eq $t.Mutex -and $script:GO_states[$other.Id].Applied) {
                        $isAlternative = $true
                        break
                    }
                }
            }
            $row = New-Object System.Windows.Controls.Grid
            $row.Margin = "8,2,8,2"
            $row.MinHeight = 28
            $row.HorizontalAlignment = "Stretch"
            foreach ($w in @("*","100","72","60","52")) {
                $col = New-Object System.Windows.Controls.ColumnDefinition; $col.Width = $w
                $row.ColumnDefinitions.Add($col) | Out-Null
            }
            $cb = New-Object System.Windows.Controls.CheckBox
            $cb.FontSize = 12; $cb.VerticalContentAlignment = "Center"; $cb.VerticalAlignment = "Center"
            $cb.Tag = $t.Id; $cb.ToolTip = $t.ShortDesc
            $cbText = New-Object System.Windows.Controls.TextBlock
            $cbText.Text = $t.Label; $cbText.TextWrapping = "NoWrap"; $cbText.TextTrimming = "CharacterEllipsis"
            $cbText.FontSize = 12; $cbText.Cursor = [System.Windows.Input.Cursors]::Hand
            $cbText.Foreground = if ($isOk) { Get-PowerToolsBrush "TextMuted" } else { Get-PowerToolsBrush "TextDark" }
            $cbText.TextDecorations = [System.Windows.TextDecorations]::Underline
            $capturedTweak = $t
            $cbText.Add_MouseLeftButtonUp({ param($s,$e) GO-ShowDetailWindow -Tweak $capturedTweak; $e.Handled=$true }.GetNewClosure())
            $cbContent = [System.Windows.Controls.StackPanel]::new()
            $cbContent.Children.Add($cbText) | Out-Null
            $noteText = if ($state.Status -in @('UNAVAILABLE','CHECK ERROR') -or ($t.Id -eq 34 -and $t.Optional)) { $state.Message } else { $t.Note }
            if ($noteText) {
                $note = [System.Windows.Controls.TextBlock]::new()
                $note.Text = $noteText; $note.FontSize = 10; $note.TextWrapping = 'Wrap'
                $note.Foreground = Get-PowerToolsBrush 'TextMuted'; $note.Margin = '0,3,8,3'
                $cbContent.Children.Add($note) | Out-Null
            }
            $cb.Content = $cbContent
            if ($isOk -or $state.Status -in @('UNAVAILABLE','CHECK ERROR')) { $cb.IsEnabled = $false }
            else {
                $capturedId = $t.Id
                $cb.Add_Checked({ param($s,$e) GO-HandleMutex -ChangedId $capturedId -IsChecked $true; GO-UpdateApplyState }.GetNewClosure())
                $cb.Add_Unchecked({ GO-UpdateApplyState })
            }
            [System.Windows.Controls.Grid]::SetColumn($cb, 0); $row.Children.Add($cb) | Out-Null
            $lbl = New-Object System.Windows.Controls.TextBlock
            $lbl.Text = if ($isAlternative){"ALTERNATIVE"}else{$state.Status}
            $lbl.ToolTip = if ($t.Mutex) { 'Only one priority preset can be active. Selecting the alternative replaces the current value.' } else { $state.Message }
            $lbl.Foreground = if ($isOk){Get-PowerToolsBrush "Success"}else{Get-PowerToolsBrush "Warning"}
            $lbl.FontSize = 9; $lbl.FontWeight = "Bold"; $lbl.VerticalAlignment = "Center"; $lbl.Margin = "8,0,4,0"
            [System.Windows.Controls.Grid]::SetColumn($lbl, 1); $row.Children.Add($lbl) | Out-Null
            $riskLbl = New-Object System.Windows.Controls.TextBlock
            $riskLbl.Text = GO-GetRiskLabel $t.Risk; $riskLbl.Foreground = GO-GetRiskColor $t.Risk
            $riskLbl.FontSize = 9; $riskLbl.FontWeight = "Bold"; $riskLbl.VerticalAlignment = "Center"; $riskLbl.Margin = "4,0,4,0"
            [System.Windows.Controls.Grid]::SetColumn($riskLbl, 2); $row.Children.Add($riskLbl) | Out-Null
            $detailBtn = New-Object System.Windows.Controls.Button
            $detailBtn.Content = "Details"; $detailBtn.Style = (Get-PowerToolsWindow).FindResource("SecondaryButton")
            $detailBtn.Padding = "10,3"; $detailBtn.FontSize = 10; $detailBtn.Margin = "4,0,4,0"; $detailBtn.VerticalAlignment = "Center"
            $detailBtn.Width = 52; $detailBtn.HorizontalAlignment = "Center"
            $capturedTweak2 = $t; $detailBtn.Add_Click({ GO-ShowDetailWindow -Tweak $capturedTweak2 }.GetNewClosure())
            [System.Windows.Controls.Grid]::SetColumn($detailBtn, 3); $row.Children.Add($detailBtn) | Out-Null
            $usbBackup = $null
            if ($t.Optional) { try { $usbBackup = GO-ReadUsbBackup $t.Id } catch { } }
            if ($isOk -or $null -ne $usbBackup) {
                $resetBtn = New-Object System.Windows.Controls.Button
                $resetBtn.Content = "Reset"; $resetBtn.Style = (Get-PowerToolsWindow).FindResource("SecondaryButton")
                $resetBtn.Padding = "4,2"; $resetBtn.FontSize = 9; $resetBtn.Width = 42; $resetBtn.Height = 20
                $resetBtn.Foreground = Get-PowerToolsBrush "Warning"; $resetBtn.Margin = "0,0,4,0"
                $resetBtn.VerticalAlignment = "Center"; $resetBtn.HorizontalAlignment = "Center"
                if ($t.Optional -and -not $usbBackup) {
                    $resetBtn.IsEnabled = $false
                    $resetBtn.ToolTip = 'No original state saved by WindowsAcolyte; this pre-existing setting will not be reset.'
                }
                $capturedTweak3 = $t
                $resetBtn.Add_Click({
                    $resetInfo = if ($capturedTweak3.Optional) { 'Restore the saved original input/USB configuration. Disconnected hubs or missing plans keep their baseline for a later retry. Accessibility Reset may re-enable previously active assistive features.' } else { 'Reset may also affect settings sharing the same values. Original pre-app values are not restored.' }
                    $r = [System.Windows.MessageBox]::Show("Reset '$($capturedTweak3.Label)'?`n`n$($capturedTweak3.Note)`n`n$resetInfo","Confirm Reset",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
                    if ($r -eq [System.Windows.MessageBoxResult]::Yes) {
                        $before = GO-GetStateSnapshot
                        try { GO-ResetTweak $capturedTweak3; GO-AddLog "Reset: $($capturedTweak3.Label)" "OK" }
                        catch { GO-AddLog "Reset failed: $($capturedTweak3.Label) - $_" "FAIL" }
                        $after = GO-GetStateSnapshot
                        GO-LogStateChanges $before $after "Reset '$($capturedTweak3.Label)'"
                        GO-RenderList -States $after
                    }
                }.GetNewClosure())
                [System.Windows.Controls.Grid]::SetColumn($resetBtn, 4); $row.Children.Add($resetBtn) | Out-Null
            }
            $script:GO_tweakList.Items.Add($row) | Out-Null
            $script:GO_checkboxes[$t.Id] = $cb
        }
        if ($script:GO_tweaks.Id -contains 35) { GO-RenderInputExtras }
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

    function Global:GO-ShowSoftwareInfo {
        [xml]$sXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Recommended Third-Party Tools" Width="720" Height="620"
        WindowStartupLocation="CenterOwner" FontFamily="Segoe UI" ResizeMode="CanResize" MinWidth="520" MinHeight="480">
    <Grid Margin="22">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Text="THIRD-PARTY TOOLS" Foreground="{DynamicResource DynAccent}" FontSize="10" FontWeight="Bold" Margin="0,0,0,4"/>
        <TextBlock Grid.Row="1" x:Name="ST" FontSize="18" FontWeight="SemiBold" Margin="0,0,0,14" Text="Recommended tools that complement Windows optimizations"/>
        <Border Grid.Row="2" x:Name="SLB" BorderThickness="1.5" CornerRadius="8">
            <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="18,14"><StackPanel x:Name="SS"/></ScrollViewer>
        </Border>
        <Button Grid.Row="3" x:Name="SCB" Content="Close" Height="38" Padding="20,6" HorizontalAlignment="Right" Margin="0,14,0,0"/>
    </Grid>
</Window>
"@
        $r = New-Object System.Xml.XmlNodeReader $sXaml
        $sw = [Windows.Markup.XamlReader]::Load($r)
        $sw.Resources.Add("SecondaryButton",(Get-PowerToolsWindow).FindResource("SecondaryButton"))
        $sw.Resources.Add("PrimaryButton",(Get-PowerToolsWindow).FindResource("PrimaryButton"))
        $sw.Owner = Get-PowerToolsWindow
        $sw.Background = $Global:PTS_Brush["Background"]
        $sw.FindName("ST").Foreground  = $Global:PTS_Brush["TextDark"]
        $sw.FindName("SLB").Background = $Global:PTS_Brush["Surface"]; $sw.FindName("SLB").BorderBrush = $Global:PTS_Brush["Border"]
        $scb = $sw.FindName("SCB"); if ($scb) { $scb.Style = $sw.FindResource("SecondaryButton"); $csw=$sw; $scb.Add_Click({$csw.Close()}.GetNewClosure()) }
        $stack = $sw.FindName("SS")
        @(
            @{Name="ISLC - Intelligent Standby List Cleaner";Rec="Very High";What="Clears Windows Standby Memory List. Prevents RAM stutter from cached data.";Why="One of the most effective tools overall. Stabilizes frametimes, reduces stutter spikes especially with 16-32GB RAM.";Cost="Free"}
            @{Name="Process Lasso";Rec="High (Intel 12+ / AMD X3D)";What="CPU prioritization and core affinity per process. Automatic and persistent.";Why="Moves background processes to E-cores (Intel) or second CCD (AMD), reserves P-cores for game.";Cost="Free / Pro available"}
            @{Name="NVCleanstall";Rec="High (NVIDIA users)";What="Installs NVIDIA drivers without bloatware (GeForce Experience, telemetry, NVIDIA Container).";Why="Fewer background processes, less RAM usage, cleaner driver stack.";Cost="Free"}
            @{Name="TimerResolution / TimerTool";Rec="High (Competitive)";What="Increases Windows timer resolution from default 15.6ms to 0.5ms.";Why="More precise process scheduling, more stable frametimes especially in competitive shooters.";Cost="Free"}
            @{Name="DDU - Display Driver Uninstaller";Rec="High";What="Complete driver removal without residue. Use before every driver update.";Why="Prevents driver conflicts, stuttering from old driver remnants, micro-crashes.";Cost="Free"}
            @{Name="MSI Afterburner + RTSS";Rec="High (Competitive)";What="GPU monitoring and FPS limiter.";Why="FPS limit to refresh rate -3 FPS reduces input lag significantly.";Cost="Free"}
            @{Name="O&O ShutUp10++";Rec="Medium";What="GUI tool for telemetry, privacy, and background processes.";Why="Quick disabling of 50+ tracking/telemetry functions.";Cost="Free"}
            @{Name="InSpectre (Gibson Research)";Rec="Medium";What="Shows status of all CPU security mitigations (Spectre, Meltdown, Downfall).";Why="Visual control whether mitigations are active. Enables one-click deactivation if needed.";Cost="Free"}
        ) | ForEach-Object {
            $tool = $_
            $card = New-Object System.Windows.Controls.Border
            $card.Background=$Global:PTS_Brush["LogBg"]; $card.BorderBrush=$Global:PTS_Brush["LogBorder"]
            $card.BorderThickness=1; $card.CornerRadius=[System.Windows.CornerRadius]::new(8); $card.Padding="14,10"; $card.Margin="0,0,0,10"
            $cs = New-Object System.Windows.Controls.StackPanel
            $t1=New-Object System.Windows.Controls.TextBlock; $t1.Text=$tool.Name; $t1.FontSize=14; $t1.FontWeight="SemiBold"; $t1.Foreground=$Global:PTS_Brush["TextDark"]; $t1.Margin="0,0,0,6"; $cs.Children.Add($t1)|Out-Null
            $t2=New-Object System.Windows.Controls.TextBlock; $t2.Text="Recommended: $($tool.Rec)  |  Cost: $($tool.Cost)"; $t2.FontSize=10; $t2.FontWeight="Bold"; $t2.Foreground=$Global:PTS_Brush["Primary"]; $t2.Margin="0,0,0,8"; $cs.Children.Add($t2)|Out-Null
            foreach ($pair in @(@{L="WHAT IT DOES";T=$tool.What},@{L="WHY USE IT";T=$tool.Why})) {
                $lbl=New-Object System.Windows.Controls.TextBlock; $lbl.Text=$pair.L; $lbl.FontSize=9; $lbl.FontWeight="Bold"; $lbl.Foreground=$Global:PTS_Brush["TextMuted"]; $lbl.Margin="0,0,0,2"; $cs.Children.Add($lbl)|Out-Null
                $txt=New-Object System.Windows.Controls.TextBlock; $txt.Text=$pair.T; $txt.FontSize=12; $txt.TextWrapping="Wrap"; $txt.Foreground=$Global:PTS_Brush["TextDark"]; $txt.Margin="0,0,0,8"; $cs.Children.Add($txt)|Out-Null
            }
            $card.Child=$cs; $stack.Children.Add($card)|Out-Null
        }
        $sw.Show()
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
    $script:GO_softInfoBtn.Add_Click({ GO-ShowSoftwareInfo })
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
