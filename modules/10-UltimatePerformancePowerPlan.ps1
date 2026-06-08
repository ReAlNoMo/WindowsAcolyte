# Module: Ultimate Performance Power Plan
# Creates and enforces a WindowsAcolyte-managed Ultimate Performance plan.

Register-PowerToolsModule `
    -Id            "ultimate-performance-power-plan" `
    -Name          "Ultimate Performance Power Plan" `
    -Description   "Create and apply a maximum-performance Windows power plan with monitors, sleep, disk idle, and power saving disabled." `
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
        <RowDefinition Height="*"/>
    </Grid.RowDefinitions>

    <Border Grid.Row="0" x:Name="InfoBorder"
            BorderThickness="1.5" CornerRadius="8" Padding="14,12" Margin="0,0,0,8">
        <StackPanel>
            <TextBlock Text="MAXIMUM PERFORMANCE POWER PROFILE"
                       Foreground="{DynamicResource DynSectionLabel}" FontSize="10"
                       FontWeight="Bold" Margin="0,0,0,6"/>
            <TextBlock x:Name="InfoText" FontSize="12" TextWrapping="Wrap" LineHeight="18"
                       Text="Creates a dedicated WindowsAcolyte Ultimate Performance power plan, activates it, disables display standby, sleep, hibernate, disk idle, PCIe link-state saving, USB selective suspend, wireless power saving, and pins processor performance to maximum."/>
        </StackPanel>
    </Border>

    <Grid Grid.Row="1" Margin="0,0,0,8">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <Border Grid.Column="0" x:Name="ActiveBorder"
                BorderThickness="1.5" CornerRadius="8" Padding="12,10" Margin="0,0,6,0">
            <StackPanel>
                <TextBlock Text="ACTIVE PLAN" Foreground="{DynamicResource DynSectionLabel}"
                           FontSize="9" FontWeight="Bold" Margin="0,0,0,5"/>
                <TextBlock x:Name="ActivePlanText" FontSize="12" TextWrapping="Wrap"/>
            </StackPanel>
        </Border>

        <Border Grid.Column="1" x:Name="ManagedBorder"
                BorderThickness="1.5" CornerRadius="8" Padding="12,10" Margin="3,0,3,0">
            <StackPanel>
                <TextBlock Text="MANAGED PLAN" Foreground="{DynamicResource DynSectionLabel}"
                           FontSize="9" FontWeight="Bold" Margin="0,0,0,5"/>
                <TextBlock x:Name="ManagedPlanText" FontSize="12" TextWrapping="Wrap"/>
            </StackPanel>
        </Border>

        <Border Grid.Column="2" x:Name="MonitorBorder"
                BorderThickness="1.5" CornerRadius="8" Padding="12,10" Margin="6,0,0,0">
            <StackPanel>
                <TextBlock Text="MONITOR STANDBY" Foreground="{DynamicResource DynSectionLabel}"
                           FontSize="9" FontWeight="Bold" Margin="0,0,0,5"/>
                <TextBlock x:Name="MonitorText" FontSize="12" TextWrapping="Wrap"/>
            </StackPanel>
        </Border>
    </Grid>

    <Border Grid.Row="2" x:Name="SettingsBorder"
            BorderThickness="1.5" CornerRadius="8" Padding="12,10" Margin="0,0,0,8">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <TextBlock Grid.Row="0" Text="SETTINGS APPLIED BY THIS MODULE"
                       Foreground="{DynamicResource DynSectionLabel}" FontSize="9"
                       FontWeight="Bold" Margin="0,0,0,6"/>
            <ScrollViewer Grid.Row="1" MaxHeight="220" VerticalScrollBarVisibility="Auto">
                <TextBlock x:Name="SettingsText"
                           FontFamily="Cascadia Code, Consolas, Courier New"
                           FontSize="10.5" TextWrapping="Wrap" LineHeight="16"/>
            </ScrollViewer>
        </Grid>
    </Border>

    <Grid Grid.Row="3" Margin="0,0,0,8">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="120"/>
            <ColumnDefinition Width="150"/>
            <ColumnDefinition Width="130"/>
        </Grid.ColumnDefinitions>
        <Button Grid.Column="0" x:Name="ApplyBtn" Content="Create / Apply Maximum Performance"
                Style="{DynamicResource PrimaryButton}" Height="40" FontSize="13" Margin="0,0,6,0"/>
        <Button Grid.Column="1" x:Name="RecheckBtn" Content="Recheck"
                Style="{DynamicResource SecondaryButton}" Height="40" FontSize="12" Margin="0,0,6,0"/>
        <Button Grid.Column="2" x:Name="BalancedBtn" Content="Set Balanced"
                Style="{DynamicResource SecondaryButton}" Height="40" FontSize="12" Margin="0,0,6,0"/>
        <Button Grid.Column="3" x:Name="ClearLogBtn" Content="Clear Log"
                Style="{DynamicResource SecondaryButton}" Height="40" FontSize="12"/>
    </Grid>

    <Grid Grid.Row="4">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <TextBlock Grid.Row="0" Text="ACTIVITY LOG" Foreground="{DynamicResource DynSectionLabel}"
                   FontSize="10" FontWeight="Bold" Margin="0,0,0,6"/>

        <Border Grid.Row="1" x:Name="LogBorder"
                BorderThickness="1.5" CornerRadius="8" MinHeight="180">
            <ScrollViewer x:Name="LogScroller" VerticalScrollBarVisibility="Auto">
                <TextBlock x:Name="LogBox"
                           FontFamily="Cascadia Code, Consolas, Courier New"
                           FontSize="11" Padding="14,12" TextWrapping="Wrap"
                           LineHeight="18" Text="Ready. Click Recheck to read current power-plan status."/>
            </ScrollViewer>
        </Border>
    </Grid>
</Grid>
"@

    $win    = Get-PowerToolsWindow
    $reader = New-Object System.Xml.XmlNodeReader $viewXaml
    $view   = [Windows.Markup.XamlReader]::Load($reader)

    foreach ($k in @("PrimaryButton","SecondaryButton")) {
        $view.Resources.Add($k, $win.FindResource($k))
    }

    $script:UPP_infoBorder   = $view.FindName("InfoBorder")
    $script:UPP_infoText     = $view.FindName("InfoText")
    $script:UPP_activeBorder = $view.FindName("ActiveBorder")
    $script:UPP_activeText   = $view.FindName("ActivePlanText")
    $script:UPP_managedBorder= $view.FindName("ManagedBorder")
    $script:UPP_managedText  = $view.FindName("ManagedPlanText")
    $script:UPP_monitorBorder= $view.FindName("MonitorBorder")
    $script:UPP_monitorText  = $view.FindName("MonitorText")
    $script:UPP_settingsBorder = $view.FindName("SettingsBorder")
    $script:UPP_settingsText = $view.FindName("SettingsText")
    $script:UPP_applyBtn     = $view.FindName("ApplyBtn")
    $script:UPP_recheckBtn   = $view.FindName("RecheckBtn")
    $script:UPP_balancedBtn  = $view.FindName("BalancedBtn")
    $script:UPP_clearLogBtn  = $view.FindName("ClearLogBtn")
    $script:UPP_logBorder    = $view.FindName("LogBorder")
    $script:UPP_logBox       = $view.FindName("LogBox")
    $script:UPP_logScroller  = $view.FindName("LogScroller")
    $script:UPP_initText     = "Ready. Click Recheck to read current power-plan status."

    $script:UPP_infoBorder.Background    = $Global:PTS_Brush["Surface"]
    $script:UPP_infoBorder.BorderBrush   = $Global:PTS_Brush["Border"]
    $script:UPP_infoText.Foreground      = $Global:PTS_Brush["TextMid"]
    $script:UPP_activeBorder.Background  = $Global:PTS_Brush["Surface"]
    $script:UPP_activeBorder.BorderBrush = $Global:PTS_Brush["Border"]
    $script:UPP_managedBorder.Background = $Global:PTS_Brush["Surface"]
    $script:UPP_managedBorder.BorderBrush= $Global:PTS_Brush["Border"]
    $script:UPP_monitorBorder.Background = $Global:PTS_Brush["Surface"]
    $script:UPP_monitorBorder.BorderBrush= $Global:PTS_Brush["Border"]
    $script:UPP_settingsBorder.Background= $Global:PTS_Brush["Surface"]
    $script:UPP_settingsBorder.BorderBrush = $Global:PTS_Brush["Border"]
    $script:UPP_activeText.Foreground    = $Global:PTS_Brush["TextDark"]
    $script:UPP_managedText.Foreground   = $Global:PTS_Brush["TextDark"]
    $script:UPP_monitorText.Foreground   = $Global:PTS_Brush["TextDark"]
    $script:UPP_settingsText.Foreground  = $Global:PTS_Brush["TextMid"]
    $script:UPP_logBorder.Background     = $Global:PTS_Brush["LogBg"]
    $script:UPP_logBorder.BorderBrush    = $Global:PTS_Brush["LogBorder"]
    $script:UPP_logBox.Foreground        = $Global:PTS_Brush["TextMuted"]

    $script:UPP_planName = "WindowsAcolyte Ultimate Performance"
    $script:UPP_planDescription = "WindowsAcolyte managed maximum-performance plan. Display, sleep, disk idle, and major power-saving features disabled."
    $script:UPP_ultimateTemplateGuid = "e9a42b02-d5df-448d-aa00-03f14749eb61"

    $script:UPP_settings = @(
        @{ Group="Display"; Name="Monitor standby disabled"; Subgroup="SUB_VIDEO"; Setting="VIDEOIDLE"; AC=0; DC=0; Detail="Monitors never turn off automatically." }
        @{ Group="Display"; Name="Display brightness"; Subgroup="SUB_VIDEO"; Setting="VIDEONORMALLEVEL"; AC=100; DC=100; Detail="Brightness at 100 percent where Windows exposes this setting." }
        @{ Group="Display"; Name="Dimmed display brightness"; Subgroup="SUB_VIDEO"; Setting="f1fbfde2-a960-4165-9f88-50667911ce96"; AC=100; DC=100; Detail="Dimmed level at 100 percent to avoid power-save dimming." }
        @{ Group="Display"; Name="Adaptive brightness disabled"; Subgroup="SUB_VIDEO"; Setting="ADAPTBRIGHT"; AC=0; DC=0; Detail="Prevents ambient-light based brightness reduction." }
        @{ Group="System idle"; Name="Sleep disabled"; Subgroup="SUB_SLEEP"; Setting="STANDBYIDLE"; AC=0; DC=0; Detail="System never enters sleep automatically." }
        @{ Group="System idle"; Name="Hibernate disabled"; Subgroup="SUB_SLEEP"; Setting="HIBERNATEIDLE"; AC=0; DC=0; Detail="System never hibernates automatically." }
        @{ Group="System idle"; Name="Hybrid sleep disabled"; Subgroup="SUB_SLEEP"; Setting="HYBRIDSLEEP"; AC=0; DC=0; Detail="Avoids hybrid sleep transitions." }
        @{ Group="Storage"; Name="Hard disk idle disabled"; Subgroup="SUB_DISK"; Setting="DISKIDLE"; AC=0; DC=0; Detail="Disks never spin down automatically." }
        @{ Group="CPU"; Name="Minimum processor state"; Subgroup="SUB_PROCESSOR"; Setting="PROCTHROTTLEMIN"; AC=100; DC=100; Detail="Keeps CPU performance floor at 100 percent." }
        @{ Group="CPU"; Name="Maximum processor state"; Subgroup="SUB_PROCESSOR"; Setting="PROCTHROTTLEMAX"; AC=100; DC=100; Detail="Keeps CPU performance ceiling at 100 percent." }
        @{ Group="CPU"; Name="Processor boost mode"; Subgroup="SUB_PROCESSOR"; Setting="be337238-0d82-4146-a960-4f3749d470c7"; AC=2; DC=2; Detail="Aggressive processor boost where supported." }
        @{ Group="CPU"; Name="Processor boost policy"; Subgroup="SUB_PROCESSOR"; Setting="45bcc044-d885-43e2-8605-ee0ec6e96b59"; AC=100; DC=100; Detail="Maximum boost policy where supported." }
        @{ Group="CPU"; Name="Processor energy preference"; Subgroup="SUB_PROCESSOR"; Setting="36687f9e-e3a5-4dbf-b1dc-15eb381c6863"; AC=0; DC=0; Detail="Lowest EPP value favors performance over efficiency." }
        @{ Group="CPU"; Name="Core parking minimum cores"; Subgroup="SUB_PROCESSOR"; Setting="0cc5b647-c1df-4637-891a-dec35c318583"; AC=100; DC=100; Detail="Keeps all available cores unparked where supported." }
        @{ Group="CPU"; Name="Core parking maximum cores"; Subgroup="SUB_PROCESSOR"; Setting="ea062031-0e34-4ff1-9b6d-eb1059334028"; AC=100; DC=100; Detail="Allows all cores to remain available." }
        @{ Group="PCI Express"; Name="Link State Power Management disabled"; Subgroup="SUB_PCIEXPRESS"; Setting="ASPM"; AC=0; DC=0; Detail="Disables PCIe link-state power saving." }
        @{ Group="USB"; Name="USB selective suspend disabled"; Subgroup="2a737441-1930-4402-8d77-b2bebba308a3"; Setting="48e6b7a6-50f5-4782-a5d4-53bb8f07e226"; AC=0; DC=0; Detail="Prevents Windows from suspending idle USB devices." }
        @{ Group="Wireless"; Name="Wireless maximum performance"; Subgroup="19cbb8fa-5279-450e-9fac-8a3d5fedd0c1"; Setting="12bbebe6-58d6-4636-95bb-3217ef867c1a"; AC=0; DC=0; Detail="Uses maximum performance mode for wireless adapters." }
        @{ Group="Multimedia"; Name="Video playback quality bias"; Subgroup="9596fb26-9850-41fd-ac3e-f7c3c00afd4b"; Setting="10778347-1370-4ee0-8bbd-33bdacaade49"; AC=1; DC=1; Detail="Favors video playback quality over power saving." }
        @{ Group="Multimedia"; Name="When playing video"; Subgroup="9596fb26-9850-41fd-ac3e-f7c3c00afd4b"; Setting="34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4"; AC=0; DC=0; Detail="Optimizes video playback quality." }
    )

    function Global:UPP-FormatSettingsSummary {
        $lines = New-Object System.Collections.Generic.List[string]
        $lines.Add("Target plan: $script:UPP_planName")
        $lines.Add("All values are written to both AC and DC power modes.")
        $lines.Add("")

        $lastGroup = $null
        foreach ($setting in ($script:UPP_settings | Sort-Object Group, Name)) {
            if ($lastGroup -ne $setting.Group) {
                if ($lastGroup) { $lines.Add("") }
                $lines.Add($setting.Group.ToUpper())
                $lastGroup = $setting.Group
            }
            $lines.Add("- $($setting.Name)")
            $lines.Add("  Subgroup: $($setting.Subgroup)")
            $lines.Add("  Setting : $($setting.Setting)")
            $lines.Add("  AC/DC   : $($setting.AC) / $($setting.DC)")
            $lines.Add("  Effect  : $($setting.Detail)")
        }

        return ($lines -join "`n")
    }

    $script:UPP_settingsText.Text = UPP-FormatSettingsSummary

    function Global:UPP-AddLog {
        param([string]$Msg, [string]$Type = "INFO")
        $ts  = Get-Date -Format "HH:mm:ss"
        $tag = switch ($Type) { "OK"{"[OK]  "} "FAIL"{"[FAIL]"} "WARN"{"[WARN]"} default{"[INFO]"} }
        $entry = "[$ts]  $tag  $Msg`n"
        if ($script:UPP_logBox.Text -eq $script:UPP_initText) { $script:UPP_logBox.Text = $entry }
        else { $script:UPP_logBox.Text += $entry }
        $script:UPP_logScroller.ScrollToEnd()
    }

    function Global:UPP-ParseSchemes {
        $schemes = @()
        foreach ($line in (powercfg /list)) {
            if ($line -match 'Power Scheme GUID:\s*([0-9a-fA-F-]{36})\s*\((.*?)\)\s*(\*)?') {
                $schemes += [pscustomobject]@{
                    Guid   = $matches[1]
                    Name   = $matches[2]
                    Active = [bool]$matches[3]
                }
            }
        }
        return $schemes
    }

    function Global:UPP-GetActiveScheme {
        $text = powercfg /getactivescheme
        if (($text -join "`n") -match 'Power Scheme GUID:\s*([0-9a-fA-F-]{36})\s*\((.*?)\)') {
            return [pscustomobject]@{ Guid=$matches[1]; Name=$matches[2] }
        }
        return $null
    }

    function Global:UPP-GetManagedPlan {
        $schemes = UPP-ParseSchemes
        return $schemes | Where-Object { $_.Name -eq $script:UPP_planName } | Select-Object -First 1
    }

    function Global:UPP-EnsurePlan {
        $plan = UPP-GetManagedPlan
        if ($plan -and $plan.Name -eq $script:UPP_planName) {
            UPP-AddLog "Managed plan exists: $($plan.Guid)" "OK"
            return $plan.Guid
        }

        UPP-AddLog "Creating dedicated plan from Ultimate Performance template..."
        $dup = powercfg -duplicatescheme $script:UPP_ultimateTemplateGuid 2>&1
        $newGuid = $null
        if (($dup -join "`n") -match '([0-9a-fA-F-]{36})') {
            $newGuid = $matches[1]
        }

        if (-not $newGuid) {
            throw "Could not create Ultimate Performance plan. Output: $($dup -join ' ')"
        }

        powercfg -changename $newGuid $script:UPP_planName $script:UPP_planDescription | Out-Null
        UPP-AddLog "Created plan: $newGuid" "OK"
        return $newGuid
    }

    function Global:UPP-SetPowerValue {
        param(
            [Parameter(Mandatory)][string]$SchemeGuid,
            [Parameter(Mandatory)][hashtable]$Setting
        )

        $label = "$($Setting.Group) - $($Setting.Name)"
        try {
            $acOutput = & powercfg -setacvalueindex $SchemeGuid $Setting.Subgroup $Setting.Setting $Setting.AC 2>&1
            $acExit = $LASTEXITCODE
            $dcOutput = & powercfg -setdcvalueindex $SchemeGuid $Setting.Subgroup $Setting.Setting $Setting.DC 2>&1
            $dcExit = $LASTEXITCODE

            if ($acExit -ne 0 -or $dcExit -ne 0) {
                $msg = ((@($acOutput) + @($dcOutput)) | Where-Object { $_ } | Out-String).Trim()
                if ([string]::IsNullOrWhiteSpace($msg)) { $msg = "powercfg exit code AC=$acExit DC=$dcExit" }
                throw $msg
            }

            UPP-AddLog "$label -> AC=$($Setting.AC), DC=$($Setting.DC)" "OK"
            return $true
        } catch {
            UPP-AddLog "$label skipped: $($_.Exception.Message)" "WARN"
            return $false
        }
    }

    function Global:UPP-QuerySettingIndex {
        param(
            [Parameter(Mandatory)][string]$SchemeGuid,
            [Parameter(Mandatory)][string]$SettingName
        )

        $q = powercfg /query $SchemeGuid
        $inSetting = $false
        $ac = $null
        $dc = $null
        foreach ($line in $q) {
            if ($line -match '^\s*Power Setting GUID:\s*[0-9a-fA-F-]{36}\s*\((.*?)\)') {
                $inSetting = ($matches[1] -eq $SettingName)
                continue
            }
            if ($inSetting -and $line -match '^\s*Current AC Power Setting Index:\s*(0x[0-9a-fA-F]+)') {
                $ac = [Convert]::ToInt64($matches[1], 16)
                continue
            }
            if ($inSetting -and $line -match '^\s*Current DC Power Setting Index:\s*(0x[0-9a-fA-F]+)') {
                $dc = [Convert]::ToInt64($matches[1], 16)
                break
            }
        }
        return [pscustomobject]@{ AC=$ac; DC=$dc }
    }

    function Global:UPP-Recheck {
        try {
            $active = UPP-GetActiveScheme
            $plan = UPP-GetManagedPlan

            if ($active) {
                $script:UPP_activeText.Text = "$($active.Name)`n$($active.Guid)"
            } else {
                $script:UPP_activeText.Text = "Unknown"
            }

            if ($plan) {
                $script:UPP_managedText.Text = "$($plan.Name)`n$($plan.Guid)"
                $display = UPP-QuerySettingIndex -SchemeGuid $plan.Guid -SettingName "Turn off display after"
                if ($display.AC -eq 0 -and $display.DC -eq 0) {
                    $script:UPP_monitorText.Text = "Disabled`nAC=Never, DC=Never"
                    $script:UPP_monitorText.Foreground = $Global:PTS_Brush["Success"]
                } else {
                    $script:UPP_monitorText.Text = "Not fully disabled`nAC=$($display.AC)s, DC=$($display.DC)s"
                    $script:UPP_monitorText.Foreground = $Global:PTS_Brush["Warning"]
                }
                if ($active -and $active.Guid -eq $plan.Guid) {
                    $script:UPP_activeText.Foreground = $Global:PTS_Brush["Success"]
                } else {
                    $script:UPP_activeText.Foreground = $Global:PTS_Brush["Warning"]
                }
            } else {
                $script:UPP_managedText.Text = "Not created yet"
                $script:UPP_monitorText.Text = "Unknown"
                $script:UPP_activeText.Foreground = $Global:PTS_Brush["TextDark"]
                $script:UPP_monitorText.Foreground = $Global:PTS_Brush["TextDark"]
            }

            UPP-AddLog "Status refreshed." "OK"
        } catch {
            UPP-AddLog $_.Exception.Message "FAIL"
        }
    }

    function Global:UPP-Apply {
        $script:UPP_applyBtn.IsEnabled = $false
        $script:UPP_recheckBtn.IsEnabled = $false
        try {
            UPP-AddLog "Applying maximum-performance power plan..."
            $guid = UPP-EnsurePlan

            $ok = 0
            $warn = 0
            foreach ($setting in $script:UPP_settings) {
                if (UPP-SetPowerValue -SchemeGuid $guid -Setting $setting) { $ok++ } else { $warn++ }
            }

            powercfg -setactive $guid | Out-Null
            UPP-AddLog "Activated plan: $guid" "OK"
            UPP-AddLog "Applied settings: $ok ok, $warn skipped." $(if ($warn -gt 0) { "WARN" } else { "OK" })
            UPP-Recheck
        } catch {
            UPP-AddLog $_.Exception.Message "FAIL"
        } finally {
            $script:UPP_applyBtn.IsEnabled = $true
            $script:UPP_recheckBtn.IsEnabled = $true
        }
    }

    function Global:UPP-SetBalanced {
        try {
            powercfg -setactive SCHEME_BALANCED | Out-Null
            UPP-AddLog "Balanced plan activated." "OK"
            UPP-Recheck
        } catch {
            UPP-AddLog $_.Exception.Message "FAIL"
        }
    }

    $script:UPP_applyBtn.Add_Click({ UPP-Apply })
    $script:UPP_recheckBtn.Add_Click({ UPP-Recheck })
    $script:UPP_balancedBtn.Add_Click({ UPP-SetBalanced })
    $script:UPP_clearLogBtn.Add_Click({
        $script:UPP_logBox.Text = $script:UPP_initText
    })

    UPP-Recheck
    return $view
}
