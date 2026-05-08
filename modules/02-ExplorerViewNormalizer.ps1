# Module: Explorer View Normalizer
# Sets all Explorer folders to Details view with no grouping.

Register-PowerToolsModule `
    -Id          "explorer-details" `
    -Name        "Explorer View Normalizer" `
    -Description "Disable grouping and force Details view across all File Explorer windows." `
    -Category    "Windows Tweaks" `
    -Show        {

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
            BorderThickness="1.5" CornerRadius="10" Padding="18,16" Margin="0,0,0,14">
        <StackPanel>
            <TextBlock Text="WHAT THIS DOES" Foreground="#8890B8" FontSize="10"
                       FontWeight="Bold" Margin="0,0,0,8"/>
            <TextBlock x:Name="InfoText" FontSize="13" TextWrapping="Wrap" LineHeight="20"
                Text="Clears Explorer Shell Bags and applies default folder settings: no grouping, Details view, columns (Name, Date modified, Type, Size), sort by Name, hidden files, file extensions, details pane, and disabled folder type discovery."/>
        </StackPanel>
    </Border>

    <Border Grid.Row="1" x:Name="StatusBorder"
            BorderThickness="1.5" CornerRadius="10" Padding="18,16" Margin="0,0,0,14">
        <StackPanel>
            <TextBlock Text="STATUS" Foreground="#8890B8" FontSize="10"
                       FontWeight="Bold" Margin="0,0,0,8"/>
            <TextBlock x:Name="StatusText" FontSize="13"
                       TextWrapping="Wrap" Text="Checking current configuration..."/>
        </StackPanel>
    </Border>

    <Grid Grid.Row="2" Margin="0,0,0,14">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="160"/>
        </Grid.ColumnDefinitions>
        <Button Grid.Column="0" x:Name="ApplyBtn" Content="Apply Settings"
                Style="{DynamicResource PrimaryButton}" Height="46" FontSize="14" Margin="0,0,8,0"/>
        <Button Grid.Column="1" x:Name="RecheckBtn" Content="Recheck"
                Style="{DynamicResource SecondaryButton}" Height="46" FontSize="13"/>
    </Grid>

    <Grid Grid.Row="3" Margin="0,6,0,8">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock Text="ACTIVITY LOG" Foreground="#8890B8" FontSize="10"
                   FontWeight="Bold" VerticalAlignment="Center"/>
        <Button x:Name="ClearLogBtn" Grid.Column="1" Content="Clear Log"
                Style="{DynamicResource SecondaryButton}" Padding="12,6" FontSize="11"/>
    </Grid>

    <Border Grid.Row="4" x:Name="LogBorder"
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
    $script:EVN_statusText   = $view.FindName("StatusText")
    $script:EVN_logBox       = $view.FindName("LogBox")
    $script:EVN_logScroller  = $view.FindName("LogScroller")
    $script:EVN_infoBorder   = $view.FindName("InfoBorder")
    $script:EVN_infoText     = $view.FindName("InfoText")
    $script:EVN_statusBorder = $view.FindName("StatusBorder")
    $script:EVN_logBorder    = $view.FindName("LogBorder")
    $script:EVN_initText     = "Ready."

    # Apply theme-aware colors
    $script:EVN_infoBorder.Background    = $Global:PTS_Brush["Surface"]
    $script:EVN_infoBorder.BorderBrush   = $Global:PTS_Brush["Border"]
    $script:EVN_infoText.Foreground      = $Global:PTS_Brush["TextMid"]
    $script:EVN_statusBorder.Background  = $Global:PTS_Brush["LogBg"]
    $script:EVN_statusBorder.BorderBrush = $Global:PTS_Brush["LogBorder"]
    $script:EVN_statusText.Foreground    = $Global:PTS_Brush["TextMid"]
    $script:EVN_logBorder.Background     = $Global:PTS_Brush["LogBg"]
    $script:EVN_logBorder.BorderBrush    = $Global:PTS_Brush["LogBorder"]
    $script:EVN_logBox.Foreground        = $Global:PTS_Brush["TextMuted"]

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
        Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Kind -Force -ErrorAction Stop | Out-Null
    }

    function Global:EVN-TestSortByName {
        param([object]$Sort)
        return (EVN-TestBinaryValue -Actual $Sort -Expected $script:EVN_sortByNameAscending)
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

    function Global:EVN-ApplyExplorerOptions {
        $advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        if (-not (Test-Path $advancedPath)) { New-Item -Path $advancedPath -Force | Out-Null }
        EVN-SetRegValue -Path $advancedPath -Name "Hidden"         -Value 1 -Kind DWord
        EVN-SetRegValue -Path $advancedPath -Name "HideFileExt"    -Value 0 -Kind DWord
        EVN-SetRegValue -Path $advancedPath -Name "ShowSuperHidden" -Value 0 -Kind DWord
        EVN-SetRegValue -Path $advancedPath -Name "UseCompactMode"   -Value 0 -Kind DWord
        EVN-SetRegValue -Path $advancedPath -Name "UseAutoGrouping"  -Value 0 -Kind DWord

        $policyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
        if (Test-Path $policyPath) {
            Remove-ItemProperty -Path $policyPath -Name "NoReadingPane" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $policyPath -Name "NoPreviewPane" -ErrorAction SilentlyContinue
        }

        $detailsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Modules\GlobalSettings\DetailsContainer"
        $sizerPath   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Modules\GlobalSettings\Sizer"
        if (-not (Test-Path $detailsPath)) { New-Item -Path $detailsPath -Force | Out-Null }
        if (-not (Test-Path $sizerPath)) { New-Item -Path $sizerPath -Force | Out-Null }
        EVN-SetRegValue -Path $detailsPath -Name "DetailsContainer"      -Value $script:EVN_detailsPaneState -Kind Binary
        EVN-SetRegValue -Path $sizerPath   -Name "DetailsContainerSizer" -Value $script:EVN_detailsPaneSizer -Kind Binary
    }

    function Global:EVN-TestExplorerOptions {
        $advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        $detailsPath  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Modules\GlobalSettings\DetailsContainer"
        $sizerPath    = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Modules\GlobalSettings\Sizer"

        $advanced = Get-ItemProperty -Path $advancedPath -ErrorAction SilentlyContinue
        if ($null -eq $advanced -or $advanced.Hidden -ne 1 -or $advanced.HideFileExt -ne 0 -or $advanced.ShowSuperHidden -ne 0 -or $advanced.UseCompactMode -ne 0 -or $advanced.UseAutoGrouping -ne 0) {
            return $false
        }

        $details = Get-ItemProperty -Path $detailsPath -ErrorAction SilentlyContinue
        $sizer   = Get-ItemProperty -Path $sizerPath -ErrorAction SilentlyContinue
        if ($null -eq $details -or -not (EVN-TestBinaryValue -Actual $details.DetailsContainer -Expected $script:EVN_detailsPaneState)) {
            return $false
        }
        if ($null -eq $sizer -or -not (EVN-TestBinaryValue -Actual $sizer.DetailsContainerSizer -Expected $script:EVN_detailsPaneSizer)) {
            return $false
        }

        return $true
    }

    function Global:EVN-CheckStatus {
        $allOk = $true
        foreach ($guid in $script:EVN_folderTypes.Values) {
            $path = Join-Path $script:EVN_basePath $guid
            if (-not (Test-Path $path)) { $allOk = $false; break }
            $p = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
            if ($null -eq $p -or $p.LogicalViewMode -ne 1 -or $p.Mode -ne 4 -or $p.GroupView -ne 0 -or $p."GroupByKey:PID" -ne 0 -or -not (EVN-TestSortByName -Sort $p.Sort) -or -not (EVN-TestBinaryValue -Actual $p.ColInfo -Expected $script:EVN_detailsColumns)) {
                $allOk = $false; break
            }
        }
        if ($allOk -and -not (EVN-TestExplorerOptions)) { $allOk = $false }
        if ($allOk) {
            $script:EVN_statusText.Text       = "Explorer is already configured (Details view, columns, sort by Name, hidden files, extensions, details pane). No action needed."
            $script:EVN_statusText.Foreground = $Global:PTS_Brush["Success"]
            $script:EVN_apply.IsEnabled       = $false
            $script:EVN_apply.Content         = "Already Applied"
        } else {
            $script:EVN_statusText.Text       = "Explorer is not fully configured. Click Apply to normalize settings."
            $script:EVN_statusText.Foreground = $Global:PTS_Brush["Warning"]
            $script:EVN_apply.IsEnabled       = $true
            $script:EVN_apply.Content         = "Apply Settings"
        }
    }

    EVN-CheckStatus

    $script:EVN_apply.Add_Click({
        try {
            EVN-AddLog "Stopping Explorer..." "INFO"
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2

            EVN-AddLog "Clearing Shell Bags..." "INFO"
            @(
                "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags",
                "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU",
                "HKCU:\Software\Microsoft\Windows\Shell\Bags",
                "HKCU:\Software\Microsoft\Windows\Shell\BagMRU"
            ) | ForEach-Object {
                if (Test-Path $_) {
                    Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue
                    EVN-AddLog "Cleared: $_" "INFO"
                }
            }

            EVN-AddLog "Writing AllFolders defaults..." "INFO"
            @($script:EVN_basePath, (Join-Path $script:EVN_basePath "{00000000-0000-0000-0000-000000000000}")) | ForEach-Object {
                if (-not (Test-Path $_)) { New-Item -Path $_ -Force | Out-Null }
                EVN-SetRegValue -Path $_ -Name "FolderType"        -Value "NotSpecified" -Kind String
                EVN-SetRegValue -Path $_ -Name "GroupByKey:FMTID"  -Value "{00000000-0000-0000-0000-000000000000}" -Kind String
                EVN-SetRegValue -Path $_ -Name "GroupByKey:PID"    -Value 0 -Kind DWord
                EVN-SetRegValue -Path $_ -Name "GroupByDirection"  -Value 1 -Kind DWord
                EVN-SetRegValue -Path $_ -Name "GroupView"         -Value 0 -Kind DWord
                EVN-SetRegValue -Path $_ -Name "LogicalViewMode"   -Value 1 -Kind DWord
                EVN-SetRegValue -Path $_ -Name "Mode"              -Value 4 -Kind DWord
                EVN-SetRegValue -Path $_ -Name "Sort"              -Value $script:EVN_sortByNameAscending -Kind Binary
                EVN-SetRegValue -Path $_ -Name "ColInfo"           -Value $script:EVN_detailsColumns -Kind Binary
            }

            foreach ($name in $script:EVN_folderTypes.Keys) {
                $guid = $script:EVN_folderTypes[$name]
                $path = Join-Path $script:EVN_basePath $guid
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                EVN-SetRegValue -Path $path -Name "FolderType"        -Value "NotSpecified" -Kind String
                EVN-SetRegValue -Path $path -Name "GroupByKey:FMTID"  -Value "{00000000-0000-0000-0000-000000000000}" -Kind String
                EVN-SetRegValue -Path $path -Name "GroupByKey:PID"    -Value 0 -Kind DWord
                EVN-SetRegValue -Path $path -Name "GroupByDirection"  -Value 1 -Kind DWord
                EVN-SetRegValue -Path $path -Name "GroupView"         -Value 0 -Kind DWord
                EVN-SetRegValue -Path $path -Name "LogicalViewMode"   -Value 1 -Kind DWord
                EVN-SetRegValue -Path $path -Name "Mode"              -Value 4 -Kind DWord
                EVN-SetRegValue -Path $path -Name "Sort"              -Value $script:EVN_sortByNameAscending -Kind Binary
                EVN-SetRegValue -Path $path -Name "ColInfo"           -Value $script:EVN_detailsColumns -Kind Binary
                EVN-AddLog "Fixed: $name" "OK"
            }

            EVN-AddLog "Applying Explorer options..." "INFO"
            EVN-ApplyExplorerOptions

            $streams = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Streams\Desktop"
            if (Test-Path $streams) {
                Remove-Item -Path $streams -Recurse -Force -ErrorAction SilentlyContinue
                EVN-AddLog "Desktop Streams cleared." "INFO"
            }

            EVN-AddLog "Restarting Explorer..." "INFO"
            Start-Process explorer
            Start-Sleep -Seconds 2
            EVN-AddLog "Done. Open each folder once to activate." "OK"
            EVN-CheckStatus
        }
        catch { EVN-AddLog "Error: $_" "FAIL" }
    })

    $script:EVN_recheck.Add_Click({
        EVN-CheckStatus
        EVN-AddLog "Status rechecked." "INFO"
    })

    $script:EVN_clearLog.Add_Click({
        $script:EVN_logBox.Text = ""
        EVN-AddLog "Log cleared." "INFO"
    })

    return $view
}
