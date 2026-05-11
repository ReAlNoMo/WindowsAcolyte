# Module: Explorer View Normalizer
# Lets users compose global Explorer defaults via checkbox options.
# Checks current state on load and applies selected settings across all folder templates.

Register-PowerToolsModule `
    -Id          "explorer-details" `
    -Name        "Explorer View Normalizer" `
    -Description "Compose and enforce global Explorer defaults across all folder templates." `
    -Category    "Windows Tweaks" `
    -Show        {

    [xml]$viewXaml = @"
<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="170"/>
    </Grid.RowDefinitions>

    <Border Grid.Row="0" x:Name="InfoBorder"
            BorderThickness="1.5" CornerRadius="10" Padding="18,16" Margin="0,0,0,12">
        <StackPanel>
            <TextBlock Text="GLOBAL EXPLORER NORMALIZER" Foreground="#8890B8" FontSize="10"
                       FontWeight="Bold" Margin="0,0,0,8"/>
            <TextBlock x:Name="InfoText" FontSize="13" TextWrapping="Wrap" LineHeight="20"
                Text="Select exactly which defaults should be enforced globally. On module load, each option is checked and marked as ALREADY SET or NOT SET. Selected options apply to all known Explorer folder templates (Generic, Downloads, Documents, Pictures, Music, Videos, UserFiles, Searches)."/>
        </StackPanel>
    </Border>

    <Border Grid.Row="1" x:Name="StatusBorder"
            BorderThickness="1.5" CornerRadius="10" Padding="18,12" Margin="0,0,0,12">
        <TextBlock x:Name="StatusText" FontSize="13" TextWrapping="Wrap"/>
    </Border>

    <Border Grid.Row="2" x:Name="OptionsBorder"
            BorderThickness="1.5" CornerRadius="10" Padding="10,10" Margin="0,0,0,12">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <TextBlock Grid.Row="0" Text="SETTINGS (SELECT TO ENFORCE)" Foreground="#8890B8" FontSize="10"
                       FontWeight="Bold" Margin="6,0,0,8"/>
            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                <StackPanel x:Name="OptionsPanel" Margin="6,0,6,6"/>
            </ScrollViewer>
        </Grid>
    </Border>

    <Grid Grid.Row="3" Margin="0,0,0,8">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>

        <Button Grid.Column="0" x:Name="ApplyBtn" Content="Apply Selected Settings"
                Style="{DynamicResource PrimaryButton}" Height="44" FontSize="14" Margin="0,0,8,0"/>
        <Button Grid.Column="1" x:Name="SelectAllBtn" Content="Select All"
                Style="{DynamicResource SecondaryButton}" Height="44" FontSize="12" Margin="0,0,8,0" Padding="12,8"/>
        <Button Grid.Column="2" x:Name="SelectNoneBtn" Content="Select None"
                Style="{DynamicResource SecondaryButton}" Height="44" FontSize="12" Margin="0,0,8,0" Padding="12,8"/>
        <Button Grid.Column="3" x:Name="RecheckBtn" Content="Recheck"
                Style="{DynamicResource SecondaryButton}" Height="44" FontSize="12" Padding="12,8"/>
    </Grid>

    <Grid Grid.Row="4" Margin="0,0,0,8">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock Text="ACTIVITY LOG" Foreground="#8890B8" FontSize="10"
                   FontWeight="Bold" VerticalAlignment="Center"/>
        <Button x:Name="ClearLogBtn" Grid.Column="1" Content="Clear Log"
                Style="{DynamicResource SecondaryButton}" Padding="12,6" FontSize="11"/>
    </Grid>

    <Border Grid.Row="5" x:Name="LogBorder"
            BorderThickness="1.5" CornerRadius="10">
        <ScrollViewer x:Name="LogScroller" VerticalScrollBarVisibility="Auto">
            <TextBlock x:Name="LogBox"
                       FontFamily="Cascadia Code, Consolas, Courier New"
                       FontSize="12" Padding="16,14" TextWrapping="Wrap"
                       LineHeight="20" Text="Ready."/>
        </ScrollViewer>
    </Border>
</Grid>
"@

    $win    = Get-PowerToolsWindow
    $reader = New-Object System.Xml.XmlNodeReader $viewXaml
    $view   = [Windows.Markup.XamlReader]::Load($reader)

    foreach ($k in @("PrimaryButton","SecondaryButton")) {
        $view.Resources.Add($k, $win.FindResource($k))
    }

    $script:EVN_apply        = $view.FindName("ApplyBtn")
    $script:EVN_recheck      = $view.FindName("RecheckBtn")
    $script:EVN_clearLog     = $view.FindName("ClearLogBtn")
    $script:EVN_selAll       = $view.FindName("SelectAllBtn")
    $script:EVN_selNone      = $view.FindName("SelectNoneBtn")
    $script:EVN_statusText   = $view.FindName("StatusText")
    $script:EVN_logBox       = $view.FindName("LogBox")
    $script:EVN_logScroller  = $view.FindName("LogScroller")
    $script:EVN_infoBorder   = $view.FindName("InfoBorder")
    $script:EVN_infoText     = $view.FindName("InfoText")
    $script:EVN_statusBorder = $view.FindName("StatusBorder")
    $script:EVN_optionsBorder= $view.FindName("OptionsBorder")
    $script:EVN_optionsPanel = $view.FindName("OptionsPanel")
    $script:EVN_logBorder    = $view.FindName("LogBorder")
    $script:EVN_initText     = "Ready."
    $script:EVN_optionControls = @{}
    $script:EVN_optionState = @{}
    $script:EVN_selectionInitialized = $false

    # Apply theme-aware colors
    $script:EVN_infoBorder.Background     = $Global:PTS_Brush["Surface"]
    $script:EVN_infoBorder.BorderBrush    = $Global:PTS_Brush["Border"]
    $script:EVN_infoText.Foreground       = $Global:PTS_Brush["TextMid"]
    $script:EVN_statusBorder.Background   = $Global:PTS_Brush["LogBg"]
    $script:EVN_statusBorder.BorderBrush  = $Global:PTS_Brush["LogBorder"]
    $script:EVN_statusText.Foreground     = $Global:PTS_Brush["TextMid"]
    $script:EVN_optionsBorder.Background  = $Global:PTS_Brush["Surface"]
    $script:EVN_optionsBorder.BorderBrush = $Global:PTS_Brush["Border"]
    $script:EVN_logBorder.Background      = $Global:PTS_Brush["LogBg"]
    $script:EVN_logBorder.BorderBrush     = $Global:PTS_Brush["LogBorder"]
    $script:EVN_logBox.Foreground         = $Global:PTS_Brush["TextMuted"]

    $script:EVN_folderTypes = [ordered]@{
        "Generic"   = "{00000000-0000-0000-0000-000000000000}"
        "Downloads" = "{885A186E-A440-4ADA-812B-DB871B942259}"
        "Documents" = "{14D5E4A5-8001-4B35-99D0-32E4FFC3B1BD}"
        "Pictures"  = "{B3690E58-E961-423B-B687-386C4AD7D8B2}"
        "Music"     = "{94D6DDCC-4A68-4175-A374-BD584A510B78}"
        "Videos"    = "{5FA96407-7E77-483C-AC93-691D05850DE8}"
        "UserFiles" = "{CD0FC69B-71E2-46E5-9690-5BCD9F57AAB3}"
        "Searches"  = "{7FDE1A1E-8B31-49A5-93B8-6BE14CFA4943}"
    }

    $script:EVN_basePath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell"

    $script:EVN_sortByNameAscending = [byte[]]@(
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x01,0x00,0x00,0x00,
        0x30,0xF1,0x25,0xB7,0xEF,0x47,0x1A,0x10,0xA5,0xF1,0x02,0x60,0x8C,0x9E,0xEB,0xAC,
        0x0A,0x00,0x00,0x00,
        0x01,0x00,0x00,0x00
    )

    $script:EVN_detailsColumns = [byte[]]@(
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0xFD,0xDF,0xDF,0xFD,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x04,0x00,0x00,0x00,0x18,0x00,0x00,0x00,
        0x30,0xF1,0x25,0xB7,0xEF,0x47,0x1A,0x10,0xA5,0xF1,0x02,0x60,0x8C,0x9E,0xEB,0xAC,0x0A,0x00,0x00,0x00,0xE9,0x00,0x00,0x00,
        0x30,0xF1,0x25,0xB7,0xEF,0x47,0x1A,0x10,0xA5,0xF1,0x02,0x60,0x8C,0x9E,0xEB,0xAC,0x0E,0x00,0x00,0x00,0x7E,0x00,0x00,0x00,
        0x30,0xF1,0x25,0xB7,0xEF,0x47,0x1A,0x10,0xA5,0xF1,0x02,0x60,0x8C,0x9E,0xEB,0xAC,0x04,0x00,0x00,0x00,0x50,0x00,0x00,0x00,
        0x30,0xF1,0x25,0xB7,0xEF,0x47,0x1A,0x10,0xA5,0xF1,0x02,0x60,0x8C,0x9E,0xEB,0xAC,0x0C,0x00,0x00,0x00,0x50,0x00,0x00,0x00
    )

    $script:EVN_detailsPaneState = [byte[]]@(0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00)
    $script:EVN_detailsPaneSizer = [byte[]]@(0x15,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x5B,0x04,0x00,0x00)

    $script:EVN_clearPaths = @(
        "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags",
        "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU",
        "HKCU:\Software\Microsoft\Windows\Shell\Bags",
        "HKCU:\Software\Microsoft\Windows\Shell\BagMRU",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Streams\Desktop",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Streams\Defaults",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\CIDSizeMRU",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\FirstFolder",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU"
    )

    function Global:EVN-AddLog {
        param([string]$Msg, [string]$Type = "INFO")
        $ts  = Get-Date -Format "HH:mm:ss"
        $tag = switch ($Type) { "OK"{"[OK]  "} "FAIL"{"[FAIL]"} "WARN"{"[WARN]"} default{"[INFO]"} }
        $entry = "[$ts]  $tag  $Msg`n"
        if ($script:EVN_logBox.Text -eq $script:EVN_initText) { $script:EVN_logBox.Text = $entry }
        else { $script:EVN_logBox.Text += $entry }
        $script:EVN_logScroller.Dispatcher.Invoke([action]{ $script:EVN_logScroller.ScrollToEnd() })
    }

    function Global:EVN-SetRegValue {
        param(
            [Parameter(Mandatory)][string]$Path,
            [Parameter(Mandatory)][string]$Name,
            [Parameter(Mandatory)]$Value,
            [Parameter(Mandatory)][Microsoft.Win32.RegistryValueKind]$Kind
        )
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Kind -Force -ErrorAction Stop | Out-Null
    }

    function Global:EVN-TestBinaryValue {
        param([object]$Actual, [byte[]]$Expected)
        if (-not ($Actual -is [byte[]])) { return $false }
        if ($Actual.Count -ne $Expected.Count) { return $false }
        for ($i = 0; $i -lt $Actual.Count; $i++) {
            if ($Actual[$i] -ne $Expected[$i]) { return $false }
        }
        return $true
    }

    function Global:EVN-GetTemplatePaths {
        $paths = [System.Collections.Generic.List[string]]::new()
        $paths.Add($script:EVN_basePath)
        foreach ($guid in $script:EVN_folderTypes.Values) {
            $paths.Add((Join-Path $script:EVN_basePath $guid))
        }
        return $paths
    }

    function Global:EVN-EnsureTemplatePaths {
        foreach ($p in (EVN-GetTemplatePaths)) {
            if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        }
    }

    function Global:EVN-TestAllTemplates {
        param([scriptblock]$Check)
        foreach ($path in (EVN-GetTemplatePaths)) {
            if (-not (Test-Path $path)) { return $false }
            $props = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
            if ($null -eq $props) { return $false }
            if (-not (& $Check $props)) { return $false }
        }
        return $true
    }

    function Global:EVN-ApplyClearSavedViews {
        foreach ($p in $script:EVN_clearPaths) {
            if (Test-Path $p) {
                Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
                EVN-AddLog "Cleared: $p" "INFO"
            }
        }
    }

    function Global:EVN-TestClearSavedViews {
        foreach ($p in $script:EVN_clearPaths) {
            if (Test-Path $p) { return $false }
        }
        return $true
    }

    function Global:EVN-ApplyDetailsView {
        EVN-EnsureTemplatePaths
        foreach ($path in (EVN-GetTemplatePaths)) {
            EVN-SetRegValue -Path $path -Name "LogicalViewMode" -Value 1 -Kind DWord
            EVN-SetRegValue -Path $path -Name "Mode" -Value 4 -Kind DWord
        }
    }

    function Global:EVN-TestDetailsView {
        return (EVN-TestAllTemplates {
            param($p)
            ($p.LogicalViewMode -eq 1 -and $p.Mode -eq 4)
        })
    }

    function Global:EVN-ApplyDisableGrouping {
        EVN-EnsureTemplatePaths
        foreach ($path in (EVN-GetTemplatePaths)) {
            EVN-SetRegValue -Path $path -Name "GroupBy" -Value "" -Kind String
            EVN-SetRegValue -Path $path -Name "GroupByKey:FMTID" -Value "{00000000-0000-0000-0000-000000000000}" -Kind String
            EVN-SetRegValue -Path $path -Name "GroupByKey:PID" -Value 0 -Kind DWord
            EVN-SetRegValue -Path $path -Name "GroupByDirection" -Value 1 -Kind DWord
            EVN-SetRegValue -Path $path -Name "GroupView" -Value 0 -Kind DWord
        }
    }

    function Global:EVN-TestDisableGrouping {
        return (EVN-TestAllTemplates {
            param($p)
            ($p.GroupView -eq 0 -and $p.GroupBy -eq "" -and $p."GroupByKey:PID" -eq 0)
        })
    }

    function Global:EVN-ApplySortNameAsc {
        EVN-EnsureTemplatePaths
        foreach ($path in (EVN-GetTemplatePaths)) {
            EVN-SetRegValue -Path $path -Name "Sort" -Value $script:EVN_sortByNameAscending -Kind Binary
        }
    }

    function Global:EVN-TestSortNameAsc {
        return (EVN-TestAllTemplates {
            param($p)
            EVN-TestBinaryValue -Actual $p.Sort -Expected $script:EVN_sortByNameAscending
        })
    }

    function Global:EVN-ApplyColumnsDefault {
        EVN-EnsureTemplatePaths
        foreach ($path in (EVN-GetTemplatePaths)) {
            EVN-SetRegValue -Path $path -Name "ColInfo" -Value $script:EVN_detailsColumns -Kind Binary
        }
    }

    function Global:EVN-TestColumnsDefault {
        return (EVN-TestAllTemplates {
            param($p)
            EVN-TestBinaryValue -Actual $p.ColInfo -Expected $script:EVN_detailsColumns
        })
    }

    function Global:EVN-ApplyFolderTypeNotSpecified {
        EVN-EnsureTemplatePaths
        foreach ($path in (EVN-GetTemplatePaths)) {
            EVN-SetRegValue -Path $path -Name "FolderType" -Value "NotSpecified" -Kind String
        }
    }

    function Global:EVN-TestFolderTypeNotSpecified {
        return (EVN-TestAllTemplates {
            param($p)
            ($p.FolderType -eq "NotSpecified")
        })
    }

    function Global:EVN-ApplyShowHidden {
        EVN-SetRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Kind DWord
    }

    function Global:EVN-TestShowHidden {
        $p = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue
        return ($null -ne $p -and $p.Hidden -eq 1)
    }

    function Global:EVN-ApplyShowExtensions {
        EVN-SetRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Kind DWord
    }

    function Global:EVN-TestShowExtensions {
        $p = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue
        return ($null -ne $p -and $p.HideFileExt -eq 0)
    }

    function Global:EVN-ApplyHideProtectedOS {
        EVN-SetRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSuperHidden" -Value 0 -Kind DWord
    }

    function Global:EVN-TestHideProtectedOS {
        $p = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue
        return ($null -ne $p -and $p.ShowSuperHidden -eq 0)
    }

    function Global:EVN-ApplyDisableCompactMode {
        EVN-SetRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "UseCompactMode" -Value 0 -Kind DWord
    }

    function Global:EVN-TestDisableCompactMode {
        $p = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue
        return ($null -ne $p -and $p.UseCompactMode -eq 0)
    }

    function Global:EVN-ApplyDisableAutoGrouping {
        EVN-SetRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "UseAutoGrouping" -Value 0 -Kind DWord
    }

    function Global:EVN-TestDisableAutoGrouping {
        $p = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue
        return ($null -ne $p -and $p.UseAutoGrouping -eq 0)
    }

    function Global:EVN-ApplyEnableDetailsPane {
        EVN-SetRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Modules\GlobalSettings\DetailsContainer" -Name "DetailsContainer" -Value $script:EVN_detailsPaneState -Kind Binary
        EVN-SetRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Modules\GlobalSettings\Sizer" -Name "DetailsContainerSizer" -Value $script:EVN_detailsPaneSizer -Kind Binary
    }

    function Global:EVN-TestEnableDetailsPane {
        $d = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Modules\GlobalSettings\DetailsContainer" -ErrorAction SilentlyContinue
        $s = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Modules\GlobalSettings\Sizer" -ErrorAction SilentlyContinue
        if ($null -eq $d -or $null -eq $s) { return $false }
        return ((EVN-TestBinaryValue -Actual $d.DetailsContainer -Expected $script:EVN_detailsPaneState) -and (EVN-TestBinaryValue -Actual $s.DetailsContainerSizer -Expected $script:EVN_detailsPaneSizer))
    }

    function Global:EVN-ApplyEnablePreviewPane {
        $policyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
        if (-not (Test-Path $policyPath)) { New-Item -Path $policyPath -Force | Out-Null }
        Remove-ItemProperty -Path $policyPath -Name "NoReadingPane" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $policyPath -Name "NoPreviewPane" -ErrorAction SilentlyContinue
    }

    function Global:EVN-TestEnablePreviewPane {
        $p = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ErrorAction SilentlyContinue
        if ($null -eq $p) { return $true }
        if ($p.PSObject.Properties.Name -contains "NoReadingPane" -and $p.NoReadingPane -eq 1) { return $false }
        if ($p.PSObject.Properties.Name -contains "NoPreviewPane" -and $p.NoPreviewPane -eq 1) { return $false }
        return $true
    }

    function Global:EVN-RestartExplorer {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Start-Process explorer
    }

    function Global:EVN-TestRestartExplorer {
        # Operational action only; not a persistent state.
        return $null
    }

    $script:EVN_options = [ordered]@{
        clear_saved_views = [ordered]@{
            Label = "Reset saved folder views/cache (Bags, BagMRU, Streams, Open/Save dialogs)"
            Test  = { EVN-TestClearSavedViews }
            Apply = { EVN-ApplyClearSavedViews }
            DefaultChecked = $true
        }
        details_view = [ordered]@{
            Label = "Force Details View (LogicalViewMode=1, Mode=4) for all folder templates"
            Test  = { EVN-TestDetailsView }
            Apply = { EVN-ApplyDetailsView }
            DefaultChecked = $true
        }
        disable_grouping = [ordered]@{
            Label = "Disable Grouping globally (GroupView=0, no GroupBy)"
            Test  = { EVN-TestDisableGrouping }
            Apply = { EVN-ApplyDisableGrouping }
            DefaultChecked = $true
        }
        sort_name_asc = [ordered]@{
            Label = "Sort by Name (Ascending) globally"
            Test  = { EVN-TestSortNameAsc }
            Apply = { EVN-ApplySortNameAsc }
            DefaultChecked = $true
        }
        columns_default = [ordered]@{
            Label = "Set default columns: Name, Date modified, Type, Size"
            Test  = { EVN-TestColumnsDefault }
            Apply = { EVN-ApplyColumnsDefault }
            DefaultChecked = $true
        }
        foldertype_notspecified = [ordered]@{
            Label = "Disable Folder Type Discovery (FolderType=NotSpecified)"
            Test  = { EVN-TestFolderTypeNotSpecified }
            Apply = { EVN-ApplyFolderTypeNotSpecified }
            DefaultChecked = $true
        }
        show_hidden = [ordered]@{
            Label = "Show hidden files"
            Test  = { EVN-TestShowHidden }
            Apply = { EVN-ApplyShowHidden }
            DefaultChecked = $true
        }
        show_extensions = [ordered]@{
            Label = "Show file extensions"
            Test  = { EVN-TestShowExtensions }
            Apply = { EVN-ApplyShowExtensions }
            DefaultChecked = $true
        }
        hide_protected_os = [ordered]@{
            Label = "Keep protected operating system files hidden"
            Test  = { EVN-TestHideProtectedOS }
            Apply = { EVN-ApplyHideProtectedOS }
            DefaultChecked = $true
        }
        disable_compact = [ordered]@{
            Label = "Disable Compact View"
            Test  = { EVN-TestDisableCompactMode }
            Apply = { EVN-ApplyDisableCompactMode }
            DefaultChecked = $true
        }
        disable_auto_grouping = [ordered]@{
            Label = "Disable Auto Grouping"
            Test  = { EVN-TestDisableAutoGrouping }
            Apply = { EVN-ApplyDisableAutoGrouping }
            DefaultChecked = $true
        }
        enable_details_pane = [ordered]@{
            Label = "Enable Details Pane"
            Test  = { EVN-TestEnableDetailsPane }
            Apply = { EVN-ApplyEnableDetailsPane }
            DefaultChecked = $true
        }
        enable_preview_pane = [ordered]@{
            Label = "Allow Preview Pane (remove restrictive Explorer policies)"
            Test  = { EVN-TestEnablePreviewPane }
            Apply = { EVN-ApplyEnablePreviewPane }
            DefaultChecked = $true
        }
        restart_explorer = [ordered]@{
            Label = "Restart Explorer automatically after apply"
            Test  = { EVN-TestRestartExplorer }
            Apply = { EVN-RestartExplorer }
            DefaultChecked = $true
        }
    }

    function Global:EVN-BuildOptionList {
        $script:EVN_optionsPanel.Children.Clear()
        $script:EVN_optionControls = @{}

        foreach ($id in $script:EVN_options.Keys) {
            $opt = $script:EVN_options[$id]
            $cb = New-Object System.Windows.Controls.CheckBox
            $cb.Margin = "0,0,0,8"
            $cb.FontSize = 12
            $cb.Content = $opt.Label
            $cb.Tag = $id
            # Default is unselected until initial state check assigns it.
            $cb.IsChecked = $false
            $cb.Foreground = $Global:PTS_Brush["TextDark"]
            $script:EVN_optionControls[$id] = $cb
        }
    }

    function Global:EVN-AddOptionSectionHeader {
        param([string]$Text)
        $hdr = New-Object System.Windows.Controls.TextBlock
        $hdr.Text = $Text
        $hdr.FontSize = 11
        $hdr.FontWeight = "Bold"
        $hdr.Foreground = $Global:PTS_Brush["Primary"]
        $hdr.Margin = "0,10,0,8"
        $script:EVN_optionsPanel.Children.Add($hdr) | Out-Null
    }

    function Global:EVN-RebuildOptionSections {
        $script:EVN_optionsPanel.Children.Clear()

        $alreadySetIds = New-Object System.Collections.Generic.List[string]
        $notSelectedIds = New-Object System.Collections.Generic.List[string]

        foreach ($id in $script:EVN_options.Keys) {
            if ($script:EVN_optionState[$id] -eq $true) { $alreadySetIds.Add($id) }
            else { $notSelectedIds.Add($id) }
        }

        EVN-AddOptionSectionHeader -Text "Already Set"
        if ($alreadySetIds.Count -eq 0) {
            $none = New-Object System.Windows.Controls.TextBlock
            $none.Text = "No settings currently detected as already set."
            $none.FontSize = 11
            $none.Foreground = $Global:PTS_Brush["TextMuted"]
            $none.Margin = "0,0,0,8"
            $script:EVN_optionsPanel.Children.Add($none) | Out-Null
        } else {
            foreach ($id in $alreadySetIds) {
                $script:EVN_optionsPanel.Children.Add($script:EVN_optionControls[$id]) | Out-Null
            }
        }

        $divider = New-Object System.Windows.Controls.Border
        $divider.Height = 1
        $divider.Margin = "0,6,0,8"
        $divider.Background = $Global:PTS_Brush["Divider"]
        $script:EVN_optionsPanel.Children.Add($divider) | Out-Null

        EVN-AddOptionSectionHeader -Text "Not Selected"
        if ($notSelectedIds.Count -eq 0) {
            $none2 = New-Object System.Windows.Controls.TextBlock
            $none2.Text = "All available settings are currently detected as set."
            $none2.FontSize = 11
            $none2.Foreground = $Global:PTS_Brush["TextMuted"]
            $none2.Margin = "0,0,0,8"
            $script:EVN_optionsPanel.Children.Add($none2) | Out-Null
        } else {
            foreach ($id in $notSelectedIds) {
                $script:EVN_optionsPanel.Children.Add($script:EVN_optionControls[$id]) | Out-Null
            }
        }
    }

    function Global:EVN-RecheckOptionStates {
        $setCount = 0
        $unsetCount = 0
        $isInitialSelectionPass = -not $script:EVN_selectionInitialized

        foreach ($id in $script:EVN_options.Keys) {
            $opt = $script:EVN_options[$id]
            $state = $null
            try { $state = & $opt.Test } catch { $state = $false }

            $script:EVN_optionState[$id] = $state
            $cb = $script:EVN_optionControls[$id]

            if ($state -eq $true) {
                $setCount++
                $cb.Content = "$($opt.Label)  [ALREADY SET]"
                $cb.Foreground = $Global:PTS_Brush["Success"]
            } elseif ($state -eq $false) {
                $unsetCount++
                $cb.Content = "$($opt.Label)  [NOT SET]"
                $cb.Foreground = $Global:PTS_Brush["Warning"]
            } else {
                $cb.Content = "$($opt.Label)  [ACTION]"
                $cb.Foreground = $Global:PTS_Brush["TextDark"]
            }

            if ($isInitialSelectionPass) {
                # Default behavior requested: items not in "Already Set" start unselected.
                $cb.IsChecked = ($state -eq $true)
            }
        }

        $script:EVN_selectionInitialized = $true
        EVN-RebuildOptionSections

        $script:EVN_statusText.Text = "Checked options: $setCount already set, $unsetCount not set. List is grouped into 'Already Set' and 'Not Selected'."
        $script:EVN_statusText.Foreground = if ($unsetCount -eq 0) { $Global:PTS_Brush["Success"] } else { $Global:PTS_Brush["Warning"] }
    }

    function Global:EVN-GetSelectedOptions {
        $selected = New-Object System.Collections.Generic.List[string]
        foreach ($id in $script:EVN_optionControls.Keys) {
            if ($script:EVN_optionControls[$id].IsChecked -eq $true) {
                $selected.Add($id)
            }
        }
        return $selected
    }

    EVN-BuildOptionList
    EVN-RecheckOptionStates

    $script:EVN_apply.Add_Click({
        try {
            $selected = EVN-GetSelectedOptions
            if ($selected.Count -eq 0) {
                EVN-AddLog "No settings selected." "WARN"
                return
            }

            EVN-AddLog "Applying selected settings globally..." "INFO"
            EVN-AddLog "Selected count: $($selected.Count)" "INFO"

            foreach ($id in $selected) {
                $opt = $script:EVN_options[$id]
                try {
                    & $opt.Apply
                    EVN-AddLog "Applied: $($opt.Label)" "OK"
                } catch {
                    EVN-AddLog "Failed: $($opt.Label) - $_" "FAIL"
                }
            }

            if ($selected -contains "restart_explorer") {
                EVN-AddLog "Explorer restarted. Global settings should now be active." "OK"
            } else {
                EVN-AddLog "Explorer was not restarted. Some changes may require reopening Explorer windows." "WARN"
            }

            EVN-RecheckOptionStates
        }
        catch {
            EVN-AddLog "Error: $_" "FAIL"
        }
    })

    $script:EVN_recheck.Add_Click({
        EVN-RecheckOptionStates
        EVN-AddLog "Status rechecked." "INFO"
    })

    $script:EVN_selAll.Add_Click({
        foreach ($id in $script:EVN_optionControls.Keys) {
            $script:EVN_optionControls[$id].IsChecked = $true
        }
        EVN-AddLog "All settings selected." "INFO"
    })

    $script:EVN_selNone.Add_Click({
        foreach ($id in $script:EVN_optionControls.Keys) {
            $script:EVN_optionControls[$id].IsChecked = $false
        }
        EVN-AddLog "All settings deselected." "INFO"
    })

    $script:EVN_clearLog.Add_Click({
        $script:EVN_logBox.Text = ""
        EVN-AddLog "Log cleared." "INFO"
    })

    return $view
}
