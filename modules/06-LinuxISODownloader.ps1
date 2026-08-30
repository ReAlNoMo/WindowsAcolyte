# Module: Linux ISO Downloader
# Downloads latest Linux distribution ISOs from official sources in parallel.
# Live progress: per-file MB/s speed + ETA + overall progress bar via ConcurrentQueue + DispatcherTimer.

Register-PowerToolsModule `
    -Id          "linux-iso-downloader" `
    -Name        "Linux ISO Downloader" `
    -Description "Download the latest Ubuntu, Debian, Fedora, Arch, CachyOS, and Pop!_OS ISOs with hash verification." `
    -Category    "Downloads" `
    -Show        {

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
        <RowDefinition Height="*"/>
    </Grid.RowDefinitions>

    <StackPanel Grid.Row="0" Margin="0,0,0,14">
        <TextBlock Text="DESTINATION FOLDER" Foreground="{DynamicResource DynSectionLabel}" FontSize="10"
                   FontWeight="Bold" Margin="0,0,0,6"/>
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="120"/>
            </Grid.ColumnDefinitions>
            <TextBox Grid.Column="0" x:Name="DestBox" Text="" Height="40"
                     FontSize="13" Padding="12,10"
                     BorderThickness="1.5"
                     FontFamily="Cascadia Code, Consolas"
                     VerticalContentAlignment="Center" Margin="0,0,8,0"/>
            <Button Grid.Column="1" x:Name="BrowseBtn" Content="Browse..."
                    Style="{DynamicResource SecondaryButton}" Height="40"/>
        </Grid>
    </StackPanel>

    <StackPanel Grid.Row="1" Margin="0,0,0,14">
        <TextBlock Text="DISTRIBUTIONS" Foreground="{DynamicResource DynSectionLabel}" FontSize="10"
                   FontWeight="Bold" Margin="0,0,0,8"/>
        <WrapPanel ItemWidth="210">
            <StackPanel Margin="0,0,16,10">
                <CheckBox x:Name="CbUbuntu" Content="Ubuntu" IsThreeState="True" IsChecked="True" FontSize="13" FontWeight="SemiBold"/>
                <CheckBox x:Name="CbUbuntuDesktop" Content="Desktop (Consumer)" IsChecked="True" Margin="18,6,0,0" FontSize="12"/>
                <CheckBox x:Name="CbUbuntuServer" Content="Server" IsChecked="True" Margin="18,4,0,0" FontSize="12"/>
            </StackPanel>
            <StackPanel Margin="0,0,16,10">
                <CheckBox x:Name="CbDebian" Content="Debian" IsThreeState="True" IsChecked="True" FontSize="13" FontWeight="SemiBold"/>
                <CheckBox x:Name="CbDebianNetinst" Content="Netinst (Server)" IsChecked="True" Margin="18,6,0,0" FontSize="12"/>
                <CheckBox x:Name="CbDebianLive" Content="Live Desktop" IsChecked="True" Margin="18,4,0,0" FontSize="12"/>
            </StackPanel>
            <StackPanel Margin="0,0,16,10">
                <CheckBox x:Name="CbFedora" Content="Fedora" IsThreeState="True" IsChecked="True" FontSize="13" FontWeight="SemiBold"/>
                <CheckBox x:Name="CbFedoraWorkstation" Content="Workstation (Consumer)" IsChecked="True" Margin="18,6,0,0" FontSize="12"/>
                <CheckBox x:Name="CbFedoraServer" Content="Server" IsChecked="True" Margin="18,4,0,0" FontSize="12"/>
            </StackPanel>
            <StackPanel Margin="0,0,16,10">
                <CheckBox x:Name="CbArch" Content="Arch Linux" IsThreeState="True" IsChecked="True" FontSize="13" FontWeight="SemiBold"/>
                <CheckBox x:Name="CbArchInstaller" Content="Installer ISO" IsChecked="True" Margin="18,6,0,0" FontSize="12"/>
            </StackPanel>
            <StackPanel Margin="0,0,16,10">
                <CheckBox x:Name="CbCachyOS" Content="CachyOS" IsThreeState="True" IsChecked="False" FontSize="13" FontWeight="SemiBold"/>
                <CheckBox x:Name="CbCachyOSDesktop" Content="Desktop" IsChecked="False" Margin="18,6,0,0" FontSize="12"/>
            </StackPanel>
            <StackPanel Margin="0,0,16,10">
                <CheckBox x:Name="CbPopOS" Content="Pop!_OS" IsThreeState="True" IsChecked="False" FontSize="13" FontWeight="SemiBold"/>
                <CheckBox x:Name="CbPopOSNvidia" Content="Desktop NVIDIA" IsChecked="False" Margin="18,6,0,0" FontSize="12"/>
                <CheckBox x:Name="CbPopOSIntel" Content="Desktop Intel/AMD" IsChecked="False" Margin="18,4,0,0" FontSize="12"/>
            </StackPanel>
        </WrapPanel>
    </StackPanel>

    <Grid Grid.Row="2" Margin="0,0,0,14">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="12"/>
            <ColumnDefinition Width="130"/>
            <ColumnDefinition Width="12"/>
            <ColumnDefinition Width="140"/>
        </Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0">
            <TextBlock Text="MAX PARALLEL DOWNLOADS" Foreground="{DynamicResource DynSectionLabel}" FontSize="10"
                       FontWeight="Bold" Margin="0,0,0,6"/>
            <ComboBox x:Name="ParallelCombo" Height="40" FontSize="13" Padding="10,8">
                <ComboBoxItem Content="1"/>
                <ComboBoxItem Content="2"/>
                <ComboBoxItem Content="3" IsSelected="True"/>
                <ComboBoxItem Content="4"/>
                <ComboBoxItem Content="5"/>
            </ComboBox>
        </StackPanel>
        <Button Grid.Column="2" x:Name="StartBtn" Content="Start Download"
                Style="{DynamicResource PrimaryButton}" Height="40" VerticalAlignment="Bottom"/>
        <Button Grid.Column="4" x:Name="CancelBtn" Content="Cancel"
                Style="{DynamicResource SecondaryButton}" Height="40"
                VerticalAlignment="Bottom" IsEnabled="False"/>
    </Grid>

    <!-- Overall progress -->
    <Grid Grid.Row="3" Margin="0,0,0,4">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock x:Name="StatusLabel" Grid.Column="0"
                   Text="Idle" Foreground="{DynamicResource DynTextMuted}" FontSize="11" VerticalAlignment="Center"/>
        <TextBlock x:Name="PctLabel" Grid.Column="1"
                   Text="" Foreground="{DynamicResource DynAccent}" FontSize="11" FontWeight="Bold" VerticalAlignment="Center"/>
    </Grid>
    <ProgressBar Grid.Row="4" x:Name="ProgressBar" Height="8"
                 Minimum="0" Maximum="100" Value="0" Margin="0,0,0,14"/>

    <Border Grid.Row="5" x:Name="ProgressListBorder"
            BorderThickness="1.5" CornerRadius="10"
            Padding="10" Margin="0,0,0,14"
            Visibility="Collapsed" MaxHeight="260">
        <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
            <StackPanel x:Name="DownloadProgressPanel"/>
        </ScrollViewer>
    </Border>

    <Grid Grid.Row="6" Margin="0,0,0,8">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock Text="ACTIVITY LOG" Foreground="{DynamicResource DynSectionLabel}" FontSize="10"
                   FontWeight="Bold" VerticalAlignment="Center"/>
        <Button x:Name="ClearLogBtn" Grid.Column="1" Content="Clear Log"
                Style="{DynamicResource SecondaryButton}" Padding="12,6" FontSize="11"/>
    </Grid>

    <Border Grid.Row="7" x:Name="LogBorder"
            BorderThickness="1.5" CornerRadius="10">
        <TextBox x:Name="LogBox"
                 IsReadOnly="True"
                 IsReadOnlyCaretVisible="True"
                 Focusable="True"
                 IsTabStop="True"
                 AcceptsReturn="True"
                 TextWrapping="Wrap"
                 VerticalScrollBarVisibility="Auto"
                 HorizontalScrollBarVisibility="Disabled"
                 BorderThickness="0"
                 Background="Transparent"
                 FontFamily="Cascadia Code, Consolas, Courier New"
                 FontSize="12"
                 Padding="16,12"
                 Text="Ready."/>
    </Border>
</Grid>
"@

    $win    = Get-PowerToolsWindow
    $reader = New-Object System.Xml.XmlNodeReader $viewXaml
    $view   = [Windows.Markup.XamlReader]::Load($reader)

    foreach ($k in @("PrimaryButton","SecondaryButton")) {
        $view.Resources.Add($k, $win.FindResource($k))
    }

    $Global:ISO_destBox     = $view.FindName("DestBox")
    $Global:ISO_browseBtn   = $view.FindName("BrowseBtn")
    $Global:ISO_cbUbuntu    = $view.FindName("CbUbuntu")
    $Global:ISO_cbUbuntuDesktop = $view.FindName("CbUbuntuDesktop")
    $Global:ISO_cbUbuntuServer  = $view.FindName("CbUbuntuServer")
    $Global:ISO_cbDebian    = $view.FindName("CbDebian")
    $Global:ISO_cbDebianNetinst = $view.FindName("CbDebianNetinst")
    $Global:ISO_cbDebianLive    = $view.FindName("CbDebianLive")
    $Global:ISO_cbFedora    = $view.FindName("CbFedora")
    $Global:ISO_cbFedoraWorkstation = $view.FindName("CbFedoraWorkstation")
    $Global:ISO_cbFedoraServer      = $view.FindName("CbFedoraServer")
    $Global:ISO_cbArch      = $view.FindName("CbArch")
    $Global:ISO_cbArchInstaller = $view.FindName("CbArchInstaller")
    $Global:ISO_cbCachyOS   = $view.FindName("CbCachyOS")
    $Global:ISO_cbCachyOSDesktop = $view.FindName("CbCachyOSDesktop")
    $Global:ISO_cbPopOS     = $view.FindName("CbPopOS")
    $Global:ISO_cbPopOSNvidia = $view.FindName("CbPopOSNvidia")
    $Global:ISO_cbPopOSIntel  = $view.FindName("CbPopOSIntel")
    $Global:ISO_parallel    = $view.FindName("ParallelCombo")
    $Global:ISO_startBtn    = $view.FindName("StartBtn")
    $Global:ISO_cancelBtn   = $view.FindName("CancelBtn")
    $Global:ISO_progress    = $view.FindName("ProgressBar")
    $Global:ISO_statusLabel = $view.FindName("StatusLabel")
    $Global:ISO_pctLabel    = $view.FindName("PctLabel")
    $Global:ISO_progressListBorder = $view.FindName("ProgressListBorder")
    $Global:ISO_progressPanel = $view.FindName("DownloadProgressPanel")
    $Global:ISO_clearLog    = $view.FindName("ClearLogBtn")
    $Global:ISO_logBox      = $view.FindName("LogBox")
    $Global:ISO_logBorder   = $view.FindName("LogBorder")
    $Global:ISO_initText    = "Ready."
    $Global:ISO_msgQueue    = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    $Global:ISO_timer       = $null
    $Global:ISO_cancelFlag  = [System.Threading.CancellationTokenSource]::new()
    $Global:ISO_bgPS        = $null
    $Global:ISO_bgHandle    = $null

    # Set default destination to user Downloads folder
    $defaultDest = Join-Path $env:USERPROFILE "Downloads\ISOs"
    if ([string]::IsNullOrWhiteSpace($Global:ISO_destBox.Text)) {
        $Global:ISO_destBox.Text = $defaultDest
    }

    # Apply theme-aware colors to TextBox and Log border
    $Global:ISO_destBox.Background  = $Global:PTS_Brush["InputBg"]
    $Global:ISO_destBox.Foreground  = $Global:PTS_Brush["InputFg"]
    $Global:ISO_destBox.BorderBrush = $Global:PTS_Brush["Border"]
    foreach ($cb in @(
        $Global:ISO_cbUbuntu, $Global:ISO_cbUbuntuDesktop, $Global:ISO_cbUbuntuServer,
        $Global:ISO_cbDebian, $Global:ISO_cbDebianNetinst, $Global:ISO_cbDebianLive,
        $Global:ISO_cbFedora, $Global:ISO_cbFedoraWorkstation, $Global:ISO_cbFedoraServer,
        $Global:ISO_cbArch, $Global:ISO_cbArchInstaller,
        $Global:ISO_cbCachyOS, $Global:ISO_cbCachyOSDesktop,
        $Global:ISO_cbPopOS, $Global:ISO_cbPopOSNvidia, $Global:ISO_cbPopOSIntel
    )) {
        if ($cb) { $cb.Foreground = $Global:PTS_Brush["TextMid"] }
    }
    $Global:ISO_parallel.Foreground = $Global:PTS_Brush["InputFg"]
    $Global:ISO_parallel.Background = $Global:PTS_Brush["InputBg"]
    $Global:ISO_parallel.BorderBrush= $Global:PTS_Brush["Border"]
    foreach ($cbItem in $Global:ISO_parallel.Items) {
        if ($cbItem -is [System.Windows.Controls.ComboBoxItem]) {
            $cbItem.Foreground = $Global:PTS_Brush["InputFg"]
            $cbItem.Background = $Global:PTS_Brush["InputBg"]
        }
    }
    $Global:ISO_logBox.Foreground   = $Global:PTS_Brush["TextMuted"]
    $Global:ISO_logBorder.Background   = $Global:PTS_Brush["LogBg"]
    $Global:ISO_logBorder.BorderBrush  = $Global:PTS_Brush["LogBorder"]
    $Global:ISO_progressListBorder.Background  = $Global:PTS_Brush["Surface"]
    $Global:ISO_progressListBorder.BorderBrush = $Global:PTS_Brush["Border"]
    $Global:ISO_progressRows = @{}

    # ===========================================================================
    # HELPERS
    # ===========================================================================
    function Global:ISO-AddLog {
        param([string]$Msg, [string]$Type = "INFO")
        $ts  = Get-Date -Format "HH:mm:ss"
        $tag = switch ($Type) { "OK"{"[OK]  "} "FAIL"{"[FAIL]"} "WARN"{"[WARN]"} default{"[INFO]"} }
        $entry = "[$ts]  $tag  $Msg`n"
        if ($Global:ISO_logBox.Text -eq $Global:ISO_initText) { $Global:ISO_logBox.Text = $entry }
        else { $Global:ISO_logBox.Text += $entry }
        $Global:ISO_logBox.ScrollToEnd()
    }

    function Global:ISO-GetInnerScrollViewer {
        param([System.Windows.DependencyObject]$Root)
        if ($null -eq $Root) { return $null }
        if ($Root -is [System.Windows.Controls.ScrollViewer]) { return $Root }
        $count = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($Root)
        for ($idx = 0; $idx -lt $count; $idx++) {
            $child = [System.Windows.Media.VisualTreeHelper]::GetChild($Root, $idx)
            $found = ISO-GetInnerScrollViewer -Root $child
            if ($null -ne $found) { return $found }
        }
        return $null
    }

    $wheelHandlerISO = [System.Windows.Input.MouseWheelEventHandler]{
        param($sender, $e)
        try {
            $sv = ISO-GetInnerScrollViewer -Root $sender
            if ($sv -is [System.Windows.Controls.ScrollViewer]) {
                $step = if ($e.Delta -gt 0) { -3 } else { 3 }
                $newOffset = $sv.VerticalOffset + $step
                if ($newOffset -lt 0) { $newOffset = 0 }
                if ($newOffset -gt $sv.ScrollableHeight) { $newOffset = $sv.ScrollableHeight }
                $sv.ScrollToVerticalOffset($newOffset)
                $e.Handled = $true
            }
        } catch {
            # keep default behavior
        }
    }
    $Global:ISO_logBox.AddHandler([System.Windows.UIElement]::PreviewMouseWheelEvent, $wheelHandlerISO, $true)
    $Global:ISO_logBox.AddHandler([System.Windows.UIElement]::MouseWheelEvent,        $wheelHandlerISO, $true)

    $Global:ISO_logBox.Add_PreviewKeyDown({
        param($sender, $e)
        if (($e.KeyboardDevice.Modifiers -band [System.Windows.Input.ModifierKeys]::Control) -and $e.Key -eq [System.Windows.Input.Key]::A) {
            $sender.SelectAll()
            $e.Handled = $true
        }
    })

    function Global:ISO-SetUI-Busy {
        param([bool]$Busy)
        $Global:ISO_startBtn.IsEnabled  = -not $Busy
        $Global:ISO_cancelBtn.IsEnabled = $Busy
        $Global:ISO_startBtn.Content    = if ($Busy) { "Downloading..." } else { "Start Download" }
    }
    
    function Global:ISO-PumpUi {
        try {
            [System.Windows.Forms.Application]::DoEvents()
        } catch {}
    }

    $Global:ISO_optionSync = $false

    function Global:ISO-IsChecked {
        param([System.Windows.Controls.CheckBox]$CheckBox)
        return ($null -ne $CheckBox -and $CheckBox.IsChecked -eq $true)
    }

    function Global:ISO-UpdateParentSelection {
        param(
            [System.Windows.Controls.CheckBox]$Parent,
            [System.Windows.Controls.CheckBox[]]$Children
        )

        if ($Global:ISO_optionSync) { return }
        try {
            $Global:ISO_optionSync = $true
            $checked = @($Children | Where-Object { $_.IsChecked -eq $true }).Count
            if ($checked -eq 0) {
                $Parent.IsChecked = $false
            } elseif ($checked -eq $Children.Count) {
                $Parent.IsChecked = $true
            } else {
                $Parent.IsChecked = $null
            }
        } finally {
            $Global:ISO_optionSync = $false
        }
    }

    function Global:ISO-WireDistroSelection {
        param(
            [System.Windows.Controls.CheckBox]$Parent,
            [System.Windows.Controls.CheckBox[]]$Children
        )

        $Parent.Add_Click({
            if ($Global:ISO_optionSync) { return }
            try {
                $Global:ISO_optionSync = $true
                $allChecked = (@($Children | Where-Object { $_.IsChecked -eq $true }).Count -eq $Children.Count)
                $value = -not $allChecked
                foreach ($child in $Children) { $child.IsChecked = $value }
                $Parent.IsChecked = $value
            } finally {
                $Global:ISO_optionSync = $false
            }
        }.GetNewClosure())

        foreach ($child in $Children) {
            $child.Add_Click({
                ISO-UpdateParentSelection -Parent $Parent -Children $Children
            }.GetNewClosure())
        }

        ISO-UpdateParentSelection -Parent $Parent -Children $Children
    }

    ISO-WireDistroSelection -Parent $Global:ISO_cbUbuntu  -Children @($Global:ISO_cbUbuntuDesktop, $Global:ISO_cbUbuntuServer)
    ISO-WireDistroSelection -Parent $Global:ISO_cbDebian  -Children @($Global:ISO_cbDebianNetinst, $Global:ISO_cbDebianLive)
    ISO-WireDistroSelection -Parent $Global:ISO_cbFedora  -Children @($Global:ISO_cbFedoraWorkstation, $Global:ISO_cbFedoraServer)
    ISO-WireDistroSelection -Parent $Global:ISO_cbArch    -Children @($Global:ISO_cbArchInstaller)
    ISO-WireDistroSelection -Parent $Global:ISO_cbCachyOS -Children @($Global:ISO_cbCachyOSDesktop)
    ISO-WireDistroSelection -Parent $Global:ISO_cbPopOS   -Children @($Global:ISO_cbPopOSNvidia, $Global:ISO_cbPopOSIntel)

    function Global:ISO-CleanupBackground {
        if ($null -ne $Global:ISO_bgPS) {
            try {
                if ($null -ne $Global:ISO_bgHandle -and $Global:ISO_bgHandle.IsCompleted) {
                    $null = $Global:ISO_bgPS.EndInvoke($Global:ISO_bgHandle)
                }
            } catch {
                # already handled
            } finally {
                try { $Global:ISO_bgPS.Dispose() } catch {}
                $Global:ISO_bgPS = $null
                $Global:ISO_bgHandle = $null
            }
        }
    }

    function Global:ISO-RequestCancel {
        if ($null -ne $Global:ISO_cancelFlag -and -not $Global:ISO_cancelFlag.IsCancellationRequested) {
            $Global:ISO_cancelFlag.Cancel()
            ISO-AddLog "Cancel requested..." "WARN"
            if ($null -ne $Global:ISO_cancelBtn) { $Global:ISO_cancelBtn.IsEnabled = $false }
        }
    }

    function Global:ISO-RegisterActiveDownload {
        if (Get-Command -Name Register-PTSActiveOperation -ErrorAction SilentlyContinue) {
            Register-PTSActiveOperation `
                -ModuleId "linux-iso-downloader" `
                -ModuleName "Linux ISO Downloader" `
                -Description "Downloading Linux ISO files" `
                -Cancel { ISO-RequestCancel }
        }
    }

    function Global:ISO-UnregisterActiveDownload {
        if (Get-Command -Name Unregister-PTSActiveOperation -ErrorAction SilentlyContinue) {
            Unregister-PTSActiveOperation -ModuleId "linux-iso-downloader"
        }
    }

    function Global:ISO-QueueMsg {
        param([hashtable]$Msg)
        $Global:ISO_msgQueue.Enqueue($Msg)
    }

    function Global:ISO-ClearProgressRows {
        $Global:ISO_progressRows = @{}
        $Global:ISO_progressPanel.Children.Clear()
        $Global:ISO_progressListBorder.Visibility = [System.Windows.Visibility]::Collapsed
    }

    function Global:ISO-CreateProgressRow {
        param(
            [string]$Key,
            [string]$Name,
            [string]$FileName
        )

        $outer = New-Object System.Windows.Controls.Border
        $outer.Background = $Global:PTS_Brush["LogBg"]
        $outer.BorderBrush = $Global:PTS_Brush["LogBorder"]
        $outer.BorderThickness = "1"
        $outer.CornerRadius = New-Object System.Windows.CornerRadius(8)
        $outer.Padding = "10,8"
        $outer.Margin = "0,0,0,8"

        $grid = New-Object System.Windows.Controls.Grid
        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))
        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))
        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))

        $top = New-Object System.Windows.Controls.Grid
        $top.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "*" }))
        $top.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "Auto" }))

        $title = New-Object System.Windows.Controls.TextBlock
        $title.Text = $Name
        $title.FontSize = 12
        $title.FontWeight = "SemiBold"
        $title.Foreground = $Global:PTS_Brush["TextDark"]
        [System.Windows.Controls.Grid]::SetColumn($title, 0)
        $top.Children.Add($title) | Out-Null

        $pct = New-Object System.Windows.Controls.TextBlock
        $pct.Text = "Queued"
        $pct.FontSize = 11
        $pct.FontWeight = "Bold"
        $pct.Foreground = $Global:PTS_Brush["TextMuted"]
        [System.Windows.Controls.Grid]::SetColumn($pct, 1)
        $top.Children.Add($pct) | Out-Null

        [System.Windows.Controls.Grid]::SetRow($top, 0)
        $grid.Children.Add($top) | Out-Null

        $bar = New-Object System.Windows.Controls.ProgressBar
        $bar.Minimum = 0
        $bar.Maximum = 100
        $bar.Value = 0
        $bar.Height = 8
        $bar.Margin = "0,7,0,5"
        [System.Windows.Controls.Grid]::SetRow($bar, 1)
        $grid.Children.Add($bar) | Out-Null

        $detail = New-Object System.Windows.Controls.TextBlock
        $detail.Text = "$FileName  |  waiting for available slot..."
        $detail.FontSize = 10
        $detail.Foreground = $Global:PTS_Brush["TextMuted"]
        $detail.TextTrimming = "CharacterEllipsis"
        [System.Windows.Controls.Grid]::SetRow($detail, 2)
        $grid.Children.Add($detail) | Out-Null

        $outer.Child = $grid
        $Global:ISO_progressPanel.Children.Add($outer) | Out-Null
        $Global:ISO_progressRows[$Key] = [PSCustomObject]@{
            Border = $outer
            Title = $title
            Percent = $pct
            Bar = $bar
            Detail = $detail
            State = "Queued"
        }
        $Global:ISO_progressListBorder.Visibility = [System.Windows.Visibility]::Visible
    }

    function Global:ISO-InitializeProgressRows {
        param([object[]]$Jobs)
        ISO-ClearProgressRows
        foreach ($job in $Jobs) {
            ISO-CreateProgressRow -Key $job.JobKey -Name $job.IsoName -FileName $job.FileName
        }
    }

    function Global:ISO-UpdateProgressRow {
        param(
            [string]$Key,
            [string]$State,
            [int]$Pct,
            [string]$Detail
        )

        if (-not $Global:ISO_progressRows.ContainsKey($Key)) { return }
        $row = $Global:ISO_progressRows[$Key]
        $row.State = $State
        if ($Pct -lt 0) { $Pct = 0 }
        if ($Pct -gt 100) { $Pct = 100 }
        $row.Bar.Value = $Pct
        $row.Detail.Text = $Detail

        switch ($State) {
            "Running" {
                $row.Percent.Text = "$Pct%"
                $row.Percent.Foreground = $Global:PTS_Brush["Accent"]
            }
            "Done" {
                $row.Bar.Value = 100
                $row.Percent.Text = "Done"
                $row.Percent.Foreground = $Global:PTS_Brush["Success"]
                $row.Detail.Text = $Detail
            }
            "Failed" {
                $row.Percent.Text = "Failed"
                $row.Percent.Foreground = $Global:PTS_Brush["Danger"]
                $row.Detail.Text = $Detail
            }
            "Cancelled" {
                $row.Percent.Text = "Cancelled"
                $row.Percent.Foreground = $Global:PTS_Brush["Warning"]
                $row.Detail.Text = $Detail
            }
            default {
                $row.Percent.Text = $State
                $row.Percent.Foreground = $Global:PTS_Brush["TextMuted"]
            }
        }
    }

    function Global:ISO-MarkUnfinishedProgressRows {
        param([string]$State, [string]$Detail)

        foreach ($key in @($Global:ISO_progressRows.Keys)) {
            $row = $Global:ISO_progressRows[$key]
            if ($row.State -ne "Done" -and $row.State -ne "Failed" -and $row.State -ne "Cancelled") {
                ISO-UpdateProgressRow -Key $key -State $State -Pct ([int]$row.Bar.Value) -Detail $Detail
            }
        }
    }

    function Global:ISO-StartTimer {
        $Global:ISO_timer = New-Object System.Windows.Threading.DispatcherTimer
        $Global:ISO_timer.Interval = [TimeSpan]::FromMilliseconds(200)
        $Global:ISO_timer.Add_Tick({
            $item = $null
            while ($Global:ISO_msgQueue.TryDequeue([ref]$item)) {
                switch ($item.Type) {
                    "LOG" {
                        ISO-AddLog -Msg $item.Msg -Type $item.Tag
                    }
                    "PROGRESS" {
                        $Global:ISO_progress.Value   = $item.Pct
                        $Global:ISO_statusLabel.Text = $item.Status
                        $Global:ISO_pctLabel.Text    = "$($item.Pct)%"
                    }
                    "FILE_PROGRESS" {
                        ISO-UpdateProgressRow -Key $item.JobKey -State "Running" -Pct $item.Pct -Detail $item.Detail
                    }
                    "FILE_STATE" {
                        ISO-UpdateProgressRow -Key $item.JobKey -State $item.State -Pct $item.Pct -Detail $item.Detail
                    }
                    "DONE" {
                        $Global:ISO_timer.Stop()
                        $Global:ISO_progress.Value        = 100
                        $Global:ISO_pctLabel.Text         = "100%"
                        $Global:ISO_statusLabel.Text      = "All downloads complete."
                        $Global:ISO_statusLabel.Foreground = $Global:PTS_Brush["Success"]
                        ISO-SetUI-Busy $false
                        ISO-UnregisterActiveDownload
                        ISO-CleanupBackground
                    }
                    "CANCELLED" {
                        $Global:ISO_timer.Stop()
                        ISO-MarkUnfinishedProgressRows -State "Cancelled" -Detail "Download operation cancelled."
                        $Global:ISO_statusLabel.Text      = "Cancelled."
                        $Global:ISO_statusLabel.Foreground = $Global:PTS_Brush["Warning"]
                        ISO-SetUI-Busy $false
                        ISO-UnregisterActiveDownload
                        ISO-CleanupBackground
                    }
                    "ERROR" {
                        $Global:ISO_timer.Stop()
                        ISO-MarkUnfinishedProgressRows -State "Cancelled" -Detail "Stopped because download operation ended with errors."
                        $Global:ISO_statusLabel.Text      = "Error."
                        $Global:ISO_statusLabel.Foreground = $Global:PTS_Brush["Danger"]
                        ISO-SetUI-Busy $false
                        ISO-UnregisterActiveDownload
                        ISO-CleanupBackground
                    }
                }
            }
        })
        $Global:ISO_timer.Start()
    }

    # ===========================================================================
    # RELEASE URL RESOLVERS
    # ===========================================================================
    function Global:ISO-EnableTls {
        try {
            $proto = [System.Net.SecurityProtocolType]::Tls12
            if ([enum]::GetNames([System.Net.SecurityProtocolType]) -contains "Tls13") {
                $proto = $proto -bor [System.Net.SecurityProtocolType]::Tls13
            }
            [System.Net.ServicePointManager]::SecurityProtocol = $proto
        } catch {}
    }

    function Global:ISO-GetNewestVersion {
        param([string[]]$Versions)
        $parsed = foreach ($v in ($Versions | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
            try {
                [PSCustomObject]@{ Raw = $v; Ver = [version]$v }
            } catch {}
        }
        if (-not $parsed) { return $null }
        return ($parsed | Sort-Object Ver -Descending | Select-Object -First 1).Raw
    }

    function Global:ISO-GetRedirectLocation {
        param([string]$Url)
        try {
            $hdr = & curl.exe -I --max-time 20 $Url 2>$null
            if ($LASTEXITCODE -ne 0 -or -not $hdr) { return $null }
            foreach ($line in $hdr) {
                if ($line -match "^[Ll]ocation:\s*(\S+)\s*$") {
                    return $Matches[1].Trim()
                }
            }
        } catch {}
        return $null
    }

    function Global:ISO-GetLatestUbuntuUrls {
        ISO-EnableTls
        try {
            $index = (Invoke-WebRequest -UseBasicParsing -Uri "https://releases.ubuntu.com/releases/" -TimeoutSec 8 -ErrorAction Stop).Content
            $versions = [regex]::Matches($index, "Ubuntu\s+(\d+\.\d+(?:\.\d+)?)") | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
            $latest = ISO-GetNewestVersion -Versions $versions
            if (-not $latest) { return @() }

            $dirContent = (Invoke-WebRequest -UseBasicParsing -Uri ("https://releases.ubuntu.com/{0}/" -f $latest) -TimeoutSec 8 -ErrorAction Stop).Content
            $isoFiles = [regex]::Matches($dirContent, "ubuntu-[0-9.]+-desktop-amd64\.iso") | ForEach-Object { $_.Value } | Select-Object -Unique
            if (-not $isoFiles -or $isoFiles.Count -eq 0) {
                $isoFiles = @("ubuntu-$latest-desktop-amd64.iso")
            }

            $urls = New-Object System.Collections.Generic.List[string]
            foreach ($iso in $isoFiles) {
                $urls.Add("https://mirrors.edge.kernel.org/ubuntu-releases/$latest/$iso")
                $urls.Add("https://releases.ubuntu.com/$latest/$iso")
            }
            return @($urls | Select-Object -Unique)
        } catch {
            return @()
        }
    }

    function Global:ISO-GetLatestUbuntuServerUrls {
        ISO-EnableTls
        try {
            $index = (Invoke-WebRequest -UseBasicParsing -Uri "https://releases.ubuntu.com/releases/" -TimeoutSec 8 -ErrorAction Stop).Content
            $versions = [regex]::Matches($index, "Ubuntu\s+(\d+\.\d+(?:\.\d+)?)") | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
            $latest = ISO-GetNewestVersion -Versions $versions
            if (-not $latest) { return @() }

            $dirContent = (Invoke-WebRequest -UseBasicParsing -Uri ("https://releases.ubuntu.com/{0}/" -f $latest) -TimeoutSec 8 -ErrorAction Stop).Content
            $isoFiles = [regex]::Matches($dirContent, "ubuntu-[0-9.]+-live-server-amd64\.iso") | ForEach-Object { $_.Value } | Select-Object -Unique
            if (-not $isoFiles -or $isoFiles.Count -eq 0) {
                $isoFiles = @("ubuntu-$latest-live-server-amd64.iso")
            }

            $urls = New-Object System.Collections.Generic.List[string]
            foreach ($iso in $isoFiles) {
                $urls.Add("https://mirrors.edge.kernel.org/ubuntu-releases/$latest/$iso")
                $urls.Add("https://releases.ubuntu.com/$latest/$iso")
            }
            return @($urls | Select-Object -Unique)
        } catch {
            return @()
        }
    }

    function Global:ISO-GetLatestDebianUrls {
        ISO-EnableTls
        try {
            $downloadPage = (Invoke-WebRequest -UseBasicParsing -Uri "https://www.debian.org/download.en.html" -TimeoutSec 8 -ErrorAction Stop).Content
            $isoName = [regex]::Match($downloadPage, "debian-\d+(?:\.\d+){2}-amd64-netinst\.iso").Value
            if (-not $isoName) { return @() }

            $primary = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/$isoName"
            $knownMirror = "https://saimei.ftp.acc.umu.se/debian-cd/current/amd64/iso-cd/$isoName"
            $mirror = ISO-GetRedirectLocation -Url $primary

            $list = New-Object System.Collections.Generic.List[string]
            if (-not [string]::IsNullOrWhiteSpace($mirror)) { $list.Add($mirror) }
            $list.Add($knownMirror)
            $list.Add($primary)
            return @($list | Select-Object -Unique)
        } catch {
            return @()
        }
    }

    function Global:ISO-GetLatestDebianLiveUrls {
        ISO-EnableTls
        try {
            $basePath = "debian-cd/current-live/amd64/iso-hybrid"
            $dirUrl = "https://cdimage.debian.org/$basePath/"
            $dirPage = Invoke-WebRequest -UseBasicParsing -Uri $dirUrl -TimeoutSec 8 -ErrorAction Stop
            $isoName = $dirPage.Links |
                Where-Object { $_.href -match "^debian-live-\d+(?:\.\d+){2}-amd64-gnome\.iso$" } |
                Select-Object -First 1 -ExpandProperty href
            if (-not $isoName) {
                $isoName = ([regex]::Match($dirPage.Content, "debian-live-\d+(?:\.\d+){2}-amd64-gnome\.iso")).Value
            }
            if (-not $isoName) { return @() }

            return @(
                "https://saimei.ftp.acc.umu.se/debian-cd/current-live/amd64/iso-hybrid/$isoName",
                "https://cdimage.debian.org/$basePath/$isoName"
            )
        } catch {
            return @()
        }
    }

    function Global:ISO-GetLatestFedoraUrls {
        ISO-EnableTls
        try {
            $pkgPage = (Invoke-WebRequest -UseBasicParsing -Uri "https://packages.fedoraproject.org/pkgs/fedora-release/fedora-release/" -TimeoutSec 8 -ErrorAction Stop).Content
            $versions = [regex]::Matches($pkgPage, "Fedora\s+(\d+)") | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
            $release = ($versions | ForEach-Object { [int]$_ } | Sort-Object -Descending | Select-Object -First 1)
            if (-not $release) { return @() }

            $bases = @(
                "https://download.fedoraproject.org/pub/fedora/linux/releases",
                "https://download-ib01.fedoraproject.org/pub/fedora/linux/releases"
            )

            $resolvedName = $null
            try {
                $dirUrl = "$($bases[0])/$release/Workstation/x86_64/iso/"
                $isoIndex = Invoke-WebRequest -UseBasicParsing -Uri $dirUrl -TimeoutSec 8 -ErrorAction Stop
                $candidates = $isoIndex.Links |
                    Where-Object { $_.href -match "^Fedora-Workstation-Live.*\.iso$" } |
                    Select-Object -ExpandProperty href -Unique
                $parsed = foreach ($name in $candidates) {
                    if ($name -match "^Fedora-Workstation-Live(?:-x86_64)?-\d+-1\.(\d+)(?:\.x86_64)?\.iso$") {
                        [PSCustomObject]@{ Name = $name; RevMinor = [int]$Matches[1] }
                    }
                }
                if ($parsed) {
                    $resolvedName = ($parsed | Sort-Object RevMinor -Descending | Select-Object -First 1).Name
                } elseif ($candidates) {
                    $resolvedName = $candidates | Select-Object -First 1
                }
            } catch {}

            if ($resolvedName) {
                return @($bases | ForEach-Object { "$_/$release/Workstation/x86_64/iso/$resolvedName" })
            }

            $urls = New-Object System.Collections.Generic.List[string]
            foreach ($base in $bases) {
                for ($minor = 9; $minor -ge 0; $minor--) {
                    $rev = "1.$minor"
                    $urls.Add("$base/$release/Workstation/x86_64/iso/Fedora-Workstation-Live-$release-$rev.x86_64.iso")
                    $urls.Add("$base/$release/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64-$release-$rev.iso")
                }
            }
            return @($urls | Select-Object -Unique)
        } catch {
            return @()
        }
    }

    function Global:ISO-GetLatestFedoraServerUrls {
        ISO-EnableTls
        try {
            $pkgPage = (Invoke-WebRequest -UseBasicParsing -Uri "https://packages.fedoraproject.org/pkgs/fedora-release/fedora-release/" -TimeoutSec 8 -ErrorAction Stop).Content
            $versions = [regex]::Matches($pkgPage, "Fedora\s+(\d+)") | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
            $release = ($versions | ForEach-Object { [int]$_ } | Sort-Object -Descending | Select-Object -First 1)
            if (-not $release) { return @() }

            $bases = @(
                "https://download.fedoraproject.org/pub/fedora/linux/releases",
                "https://download-ib01.fedoraproject.org/pub/fedora/linux/releases"
            )

            $resolvedName = $null
            try {
                $dirUrl = "$($bases[0])/$release/Server/x86_64/iso/"
                $isoIndex = Invoke-WebRequest -UseBasicParsing -Uri $dirUrl -TimeoutSec 8 -ErrorAction Stop
                $candidates = $isoIndex.Links |
                    Where-Object { $_.href -match "^Fedora-Server-dvd.*\.iso$" } |
                    Select-Object -ExpandProperty href -Unique
                $parsed = foreach ($name in $candidates) {
                    if ($name -match "^Fedora-Server-dvd(?:-x86_64)?-\d+-1\.(\d+)(?:\.x86_64)?\.iso$") {
                        [PSCustomObject]@{ Name = $name; RevMinor = [int]$Matches[1] }
                    }
                }
                if ($parsed) {
                    $resolvedName = ($parsed | Sort-Object RevMinor -Descending | Select-Object -First 1).Name
                } elseif ($candidates) {
                    $resolvedName = $candidates | Select-Object -First 1
                }
            } catch {}

            if ($resolvedName) {
                return @($bases | ForEach-Object { "$_/$release/Server/x86_64/iso/$resolvedName" })
            }

            $urls = New-Object System.Collections.Generic.List[string]
            foreach ($base in $bases) {
                for ($minor = 9; $minor -ge 0; $minor--) {
                    $rev = "1.$minor"
                    $urls.Add("$base/$release/Server/x86_64/iso/Fedora-Server-dvd-x86_64-$release-$rev.iso")
                    $urls.Add("$base/$release/Server/x86_64/iso/Fedora-Server-dvd-$release-$rev.x86_64.iso")
                }
            }
            return @($urls | Select-Object -Unique)
        } catch {
            return @()
        }
    }

    function Global:ISO-GetLatestCachyOSUrls {
        ISO-EnableTls
        try {
            $index = Invoke-WebRequest -UseBasicParsing -Uri "https://mirror.cachyos.org/ISO/desktop/" -TimeoutSec 8 -ErrorAction Stop
            $dirs = $index.Links | Where-Object { $_.href -match "^\d{6}/$" } | ForEach-Object { $_.href.TrimEnd("/") }
            if (-not $dirs -or $dirs.Count -eq 0) { return @() }

            $latestDir = ($dirs | Sort-Object -Descending | Select-Object -First 1)
            $dirPage = Invoke-WebRequest -UseBasicParsing -Uri "https://mirror.cachyos.org/ISO/desktop/$latestDir/" -TimeoutSec 8 -ErrorAction Stop
            $iso = $dirPage.Links | Where-Object { $_.href -match "^cachyos-desktop-linux-\d{6}\.iso$" } | Select-Object -First 1 -ExpandProperty href
            if (-not $iso) { $iso = "cachyos-desktop-linux-$latestDir.iso" }

            return @("https://mirror.cachyos.org/ISO/desktop/$latestDir/$iso")
        } catch {
            return @()
        }
    }

    # ===========================================================================
    # ISO DEFINITIONS
    # ===========================================================================
    function Global:ISO-GetJobList {
        param([string]$Dest, [System.Threading.CancellationToken]$Token)

        $jobs = @()

        if (ISO-IsChecked $Global:ISO_cbUbuntuDesktop) {
            $ubuntuUrls = ISO-GetLatestUbuntuUrls
            if (-not $ubuntuUrls -or $ubuntuUrls.Count -eq 0) {
                $ubuntuUrls = @(
                    "https://mirrors.edge.kernel.org/ubuntu-releases/26.04/ubuntu-26.04-desktop-amd64.iso",
                    "https://releases.ubuntu.com/26.04/ubuntu-26.04-desktop-amd64.iso",
                    "https://releases.ubuntu.com/24.04/ubuntu-24.04.4-desktop-amd64.iso"
                )
            }

            $jobs += @{
                IsoName  = "Ubuntu Desktop"
                FileName = "ubuntu-desktop-latest-amd64.iso"
                OutFile  = Join-Path $Dest "ubuntu-desktop-latest-amd64.iso"
                UrlList  = @($ubuntuUrls)
            }
        }

        if (ISO-IsChecked $Global:ISO_cbUbuntuServer) {
            $ubuntuServerUrls = ISO-GetLatestUbuntuServerUrls
            if (-not $ubuntuServerUrls -or $ubuntuServerUrls.Count -eq 0) {
                $ubuntuServerUrls = @(
                    "https://mirrors.edge.kernel.org/ubuntu-releases/24.04.4/ubuntu-24.04.4-live-server-amd64.iso",
                    "https://releases.ubuntu.com/24.04.4/ubuntu-24.04.4-live-server-amd64.iso",
                    "https://releases.ubuntu.com/24.04/ubuntu-24.04.4-live-server-amd64.iso"
                )
            }

            $jobs += @{
                IsoName  = "Ubuntu Server"
                FileName = "ubuntu-server-latest-amd64.iso"
                OutFile  = Join-Path $Dest "ubuntu-server-latest-amd64.iso"
                UrlList  = @($ubuntuServerUrls)
            }
        }

        if (ISO-IsChecked $Global:ISO_cbDebianNetinst) {
            $debianUrls = ISO-GetLatestDebianUrls
            if (-not $debianUrls -or $debianUrls.Count -eq 0) {
                $debianUrls = @(
                    "https://saimei.ftp.acc.umu.se/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso",
                    "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso"
                )
            }

            $jobs += @{
                IsoName  = "Debian Netinst"
                FileName = "debian-netinst-latest-amd64.iso"
                OutFile  = Join-Path $Dest "debian-netinst-latest-amd64.iso"
                UrlList  = @($debianUrls)
            }
        }

        if (ISO-IsChecked $Global:ISO_cbDebianLive) {
            $debianLiveUrls = ISO-GetLatestDebianLiveUrls
            if (-not $debianLiveUrls -or $debianLiveUrls.Count -eq 0) {
                $debianLiveUrls = @(
                    "https://saimei.ftp.acc.umu.se/debian-cd/current-live/amd64/iso-hybrid/debian-live-13.4.0-amd64-gnome.iso",
                    "https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/debian-live-13.4.0-amd64-gnome.iso"
                )
            }

            $jobs += @{
                IsoName  = "Debian Live Desktop"
                FileName = "debian-live-desktop-latest-amd64.iso"
                OutFile  = Join-Path $Dest "debian-live-desktop-latest-amd64.iso"
                UrlList  = @($debianLiveUrls)
            }
        }

        if (ISO-IsChecked $Global:ISO_cbFedoraWorkstation) {
            $fedoraUrls = ISO-GetLatestFedoraUrls
            if (-not $fedoraUrls -or $fedoraUrls.Count -eq 0) {
                $fedoraUrls = @(
                    "https://download.fedoraproject.org/pub/fedora/linux/releases/44/Workstation/x86_64/iso/Fedora-Workstation-Live-44-1.7.x86_64.iso",
                    "https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/44/Workstation/x86_64/iso/Fedora-Workstation-Live-44-1.7.x86_64.iso"
                )
            }

            $jobs += @{
                IsoName  = "Fedora Workstation"
                FileName = "fedora-workstation-latest-amd64.iso"
                OutFile  = Join-Path $Dest "fedora-workstation-latest-amd64.iso"
                UrlList  = @($fedoraUrls)
            }
        }

        if (ISO-IsChecked $Global:ISO_cbFedoraServer) {
            $fedoraServerUrls = ISO-GetLatestFedoraServerUrls
            if (-not $fedoraServerUrls -or $fedoraServerUrls.Count -eq 0) {
                $fedoraServerUrls = @(
                    "https://download.fedoraproject.org/pub/fedora/linux/releases/44/Server/x86_64/iso/Fedora-Server-dvd-x86_64-44-1.7.iso",
                    "https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/44/Server/x86_64/iso/Fedora-Server-dvd-x86_64-44-1.7.iso"
                )
            }

            $jobs += @{
                IsoName  = "Fedora Server"
                FileName = "fedora-server-latest-amd64.iso"
                OutFile  = Join-Path $Dest "fedora-server-latest-amd64.iso"
                UrlList  = @($fedoraServerUrls)
            }
        }

        if (ISO-IsChecked $Global:ISO_cbArchInstaller) {
            $jobs += @{
                IsoName  = "Arch Linux"
                FileName = "archlinux-latest-amd64.iso"
                OutFile  = Join-Path $Dest "archlinux-latest-amd64.iso"
                UrlList  = @(
                    "https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso",
                    "https://mirror.rackspace.com/archlinux/iso/latest/archlinux-x86_64.iso"
                )
            }
        }

        if (ISO-IsChecked $Global:ISO_cbCachyOSDesktop) {
            $cachyUrls = ISO-GetLatestCachyOSUrls
            if (-not $cachyUrls -or $cachyUrls.Count -eq 0) {
                $cachyUrls = @(
                    "https://mirror.cachyos.org/ISO/desktop/260426/cachyos-desktop-linux-260426.iso",
                    "https://iso.cachyos.org/desktop/260426/cachyos-desktop-linux-260426.iso"
                )
            }

            $jobs += @{
                IsoName  = "CachyOS Desktop"
                FileName = "cachyos-latest-amd64.iso"
                OutFile  = Join-Path $Dest "cachyos-latest-amd64.iso"
                UrlList  = @($cachyUrls)
            }
        }

        if (ISO-IsChecked $Global:ISO_cbPopOSNvidia) {
            $jobs += @{
                IsoName  = "Pop!_OS NVIDIA"
                FileName = "pop-os-nvidia-latest-amd64.iso"
                OutFile  = Join-Path $Dest "pop-os-nvidia-latest-amd64.iso"
                UrlList  = @(
                    "https://iso.pop-os.org/22.04/amd64/nvidia/41/pop-os_22.04_amd64_nvidia_41.iso"
                )
            }
        }

        if (ISO-IsChecked $Global:ISO_cbPopOSIntel) {
            $jobs += @{
                IsoName  = "Pop!_OS Intel/AMD"
                FileName = "pop-os-intel-amd-latest-amd64.iso"
                OutFile  = Join-Path $Dest "pop-os-intel-amd-latest-amd64.iso"
                UrlList  = @(
                    "https://iso.pop-os.org/22.04/amd64/intel/41/pop-os_22.04_amd64_intel_41.iso"
                )
            }
        }

        return $jobs
    }

    # ===========================================================================
    # DOWNLOAD WORKER (runs in thread pool via RunspacePool)
    # ===========================================================================
    $Global:ISO_WorkerScript = {
        param($Job, $Queue, $CancelToken, $TotalJobs, $JobIndex)

        function Q-Log  { param($M,$T) $Queue.Enqueue([PSCustomObject]@{Type="LOG";Msg=$M;Tag=$T}) }
        function Q-FileProg { param($P,$D) $Queue.Enqueue([PSCustomObject]@{Type="FILE_PROGRESS";JobKey=$Job["JobKey"];Pct=$P;Detail=$D}) }
        function Q-FileState { param($S,$P,$D) $Queue.Enqueue([PSCustomObject]@{Type="FILE_STATE";JobKey=$Job["JobKey"];State=$S;Pct=$P;Detail=$D}) }
        function Q-Err {
            param(
                [string]$Context,
                [string]$Url,
                [int]$Attempt,
                [System.Exception]$Exception,
                [string]$ExtraMessage
            )

            if ([string]::IsNullOrWhiteSpace($Job.ErrorLogPath)) { return }
            try {
                $entry = [ordered]@{
                    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
                    context       = $Context
                    module_id     = "linux-iso-downloader"
                    distro        = $Job.IsoName
                    output_file   = $Job.OutFile
                    url           = $Url
                    attempt       = $Attempt
                    machine_name  = $env:COMPUTERNAME
                    ps_version    = $PSVersionTable.PSVersion.ToString()
                    process_id    = $PID
                    exception     = if ($Exception) {
                        [ordered]@{
                            type      = $Exception.GetType().FullName
                            message   = $Exception.Message
                            hresult   = $Exception.HResult
                            source    = $Exception.Source
                            stack     = $Exception.StackTrace
                            inner_msg = if ($Exception.InnerException) { $Exception.InnerException.Message } else { $null }
                        }
                    } else { $null }
                    message       = $ExtraMessage
                }

                [System.IO.File]::AppendAllText(
                    $Job.ErrorLogPath,
                    (($entry | ConvertTo-Json -Depth 7 -Compress) + [Environment]::NewLine),
                    [System.Text.UTF8Encoding]::new($false)
                )
            } catch {}
        }

        $result = [PSCustomObject]@{ Success=$false; IsoName=$Job.IsoName; Message="" }
        $tmp    = "$($Job.OutFile).tmp"
        $fs = $null
        $stream = $null
        $resp = $null

        try {
            $proto = [System.Net.SecurityProtocolType]::Tls12
            if ([enum]::GetNames([System.Net.SecurityProtocolType]) -contains "Tls13") {
                $proto = $proto -bor [System.Net.SecurityProtocolType]::Tls13
            }
            [System.Net.ServicePointManager]::SecurityProtocol = $proto
        } catch {}

        if ($CancelToken.IsCancellationRequested) {
            $result.Message = "Cancelled"
            return $result
        }

        Q-Log "Starting: $($Job.IsoName)" "INFO"
        Q-FileState "Running" 0 "$($Job.FileName)  |  connecting..."
        $downloaded = $false

        foreach ($url in $Job.UrlList) {
            if ($CancelToken.IsCancellationRequested) { break }
            for ($attempt = 1; $attempt -le 2 -and -not $downloaded; $attempt++) {
                if ($CancelToken.IsCancellationRequested) { break }
                try {
                    $req = [System.Net.HttpWebRequest]::Create($url)
                    $req.AllowAutoRedirect = $true
                    $req.UserAgent = "PowerTools-Suite-ISODownloader/1.0"
                    $req.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
                    $req.KeepAlive = $true
                    $req.Timeout = 60000
                    $req.ReadWriteTimeout = 60000
                    $resp   = $req.GetResponse()
                    $total  = $resp.ContentLength
                    $stream = $resp.GetResponseStream()
                    $fs     = [System.IO.File]::Create($tmp)
                    $buf    = New-Object byte[] (128KB)
                    $read   = 0
                    $sw     = [System.Diagnostics.Stopwatch]::StartNew()
                    $lastReport = 0

                    while (-not $CancelToken.IsCancellationRequested) {
                        $n = $stream.Read($buf, 0, $buf.Length)
                        if ($n -le 0) { break }
                        $fs.Write($buf, 0, $n)
                        $read += $n

                        if ($sw.ElapsedMilliseconds - $lastReport -ge 500) {
                            $lastReport = $sw.ElapsedMilliseconds
                            $mbDone  = [math]::Round($read / 1MB, 1)
                            $mbTotal = if ($total -gt 0) { [math]::Round($total / 1MB, 1) } else { "?" }
                            $speed   = if ($sw.Elapsed.TotalSeconds -gt 0) {
                                [math]::Round($read / 1MB / $sw.Elapsed.TotalSeconds, 1)
                            } else { 0 }
                            $eta = if ($total -gt 0 -and $speed -gt 0) {
                                "$([math]::Round(($total - $read) / 1MB / $speed))s"
                            } else { "..." }
                            $filePct    = if ($total -gt 0) { [int](($read / $total) * 100) } else { 0 }
                            Q-FileProg $filePct "$($Job.FileName)  |  ${mbDone}MB / ${mbTotal}MB  |  ${speed} MB/s  |  ETA: $eta"
                        }
                    }

                    $fs.Close()
                    $stream.Close()
                    $resp.Close()
                    $fs = $null
                    $stream = $null
                    $resp = $null

                    if (-not $CancelToken.IsCancellationRequested) {
                        Move-Item -Path $tmp -Destination $Job.OutFile -Force
                        $sizeMB = [math]::Round((Get-Item $Job.OutFile).Length / 1MB, 1)
                        Q-Log "Downloaded: $($Job.FileName) (${sizeMB} MB)" "OK"
                        Q-FileState "Done" 100 "$($Job.FileName)  |  complete (${sizeMB} MB)"
                        $result.Success = $true
                        $downloaded = $true
                        break
                    }

                } catch {
                    if ($null -ne $fs) { try { $fs.Close() } catch {} }
                    if ($null -ne $stream) { try { $stream.Close() } catch {} }
                    if ($null -ne $resp) { try { $resp.Close() } catch {} }
                    $fs = $null
                    $stream = $null
                    $resp = $null
                    if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }

                    $msg = $_.Exception.Message
                    Q-Log "URL failed ($url) [attempt $attempt/2]: $msg" "WARN"
                    Q-Err -Context "LinuxISO.DownloadAttemptFailed" -Url $url -Attempt $attempt -Exception $_.Exception -ExtraMessage $_.ToString()

                    if ($attempt -lt 2 -and -not $CancelToken.IsCancellationRequested) {
                        Start-Sleep -Seconds (2 * $attempt)
                    }
                }
            }
            if ($downloaded) { break }
        }

        if (-not $downloaded -and -not $CancelToken.IsCancellationRequested) {
            $result.Message = "All URLs failed"
            Q-Log "FAILED: $($Job.IsoName) — all URLs exhausted" "FAIL"
            Q-FileState "Failed" 0 "$($Job.FileName)  |  all URLs exhausted"
        }
        if ($CancelToken.IsCancellationRequested) {
            $result.Message = "Cancelled"
            Q-FileState "Cancelled" 0 "$($Job.FileName)  |  cancelled"
        }

        return $result
    }

    # ===========================================================================
    # DOWNLOAD ORCHESTRATOR
    # ===========================================================================
    function Global:ISO-RunDownloads {
        param(
            [object[]]$Jobs,
            [System.Threading.CancellationToken]$CancelToken,
            [System.Collections.Concurrent.ConcurrentQueue[object]]$Queue,
            [int]$MaxPar,
            [scriptblock]$WorkerScript
        )

        try {
            if (-not $Jobs -or $Jobs.Count -eq 0) {
                $Queue.Enqueue([PSCustomObject]@{ Type = "LOG"; Msg = "No download jobs received by coordinator."; Tag = "FAIL" })
                $Queue.Enqueue([PSCustomObject]@{ Type = "ERROR" })
                return
            }

            $total = $Jobs.Count
            if ($MaxPar -lt 1) { $MaxPar = 1 }
            if ($MaxPar -gt $total) { $MaxPar = $total }

            $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxPar)
            $pool.Open()

            $running = [System.Collections.Generic.List[object]]::new()
            $done = 0
            $ok = 0
            $failed = 0

            for ($i = 0; $i -lt $Jobs.Count; $i++) {
                if ($CancelToken.IsCancellationRequested) { break }
                $Queue.Enqueue([PSCustomObject]@{
                    Type = "LOG"
                    Msg  = "Queueing job: $($Jobs[$i].IsoName)"
                    Tag  = "INFO"
                })
                $ps = [System.Management.Automation.PowerShell]::Create()
                $ps.RunspacePool = $pool
                $null = $ps.AddScript($WorkerScript).AddArgument($Jobs[$i]).AddArgument($Queue).AddArgument($CancelToken).AddArgument($total).AddArgument($i)
                $running.Add([PSCustomObject]@{ PS = $ps; Handle = $ps.BeginInvoke(); Job = $Jobs[$i]; Done = $false })
            }

            while ($done -lt $running.Count) {
                Start-Sleep -Milliseconds 300
                foreach ($r in $running) {
                    if ($r.Handle.IsCompleted -and -not $r.Done) {
                        $r.Done = $true
                        $done++
                        try {
                            $res = $r.PS.EndInvoke($r.Handle)
                            if ($res -and $res.Count -gt 0 -and $res[0].Success) {
                                $ok++
                            } else {
                                $failed++
                                $reason = if ($res -and $res.Count -gt 0 -and $res[0].Message) { $res[0].Message } else { "No reason returned" }
                                $Queue.Enqueue([PSCustomObject]@{
                                    Type = "LOG"
                                    Msg  = "Job failed: $($r.Job.IsoName) ($reason)"
                                    Tag  = "FAIL"
                                })
                            }
                        } catch {
                            $failed++
                            $Queue.Enqueue([PSCustomObject]@{
                                Type = "LOG"
                                Msg  = "Worker exception: $($_.ToString())"
                                Tag  = "FAIL"
                            })
                        } finally {
                            $r.PS.Dispose()
                        }
                        $pct = [int](($done / $total) * 100)
                        $Queue.Enqueue([PSCustomObject]@{
                            Type   = "PROGRESS"
                            Pct    = $pct
                            Status = "Completed $done of $total ISO(s)"
                        })
                    }
                }
            }

            $pool.Close()
            $pool.Dispose()

            if ($CancelToken.IsCancellationRequested) {
                $Queue.Enqueue([PSCustomObject]@{ Type = "CANCELLED" })
            } elseif ($failed -gt 0) {
                $Queue.Enqueue([PSCustomObject]@{
                    Type = "LOG"
                    Msg  = "Finished with errors. Success: $ok, Failed: $failed"
                    Tag  = "FAIL"
                })
                $Queue.Enqueue([PSCustomObject]@{ Type = "ERROR" })
            } else {
                $Queue.Enqueue([PSCustomObject]@{ Type = "LOG"; Msg = "All downloads finished."; Tag = "OK" })
                $Queue.Enqueue([PSCustomObject]@{ Type = "DONE" })
            }
        } catch {
            $Queue.Enqueue([PSCustomObject]@{
                Type = "LOG"
                Msg  = "Fatal coordinator error: $($_.ToString())"
                Tag  = "FAIL"
            })
            $Queue.Enqueue([PSCustomObject]@{ Type = "ERROR" })
        }
    }

    # ===========================================================================
    # EVENT HANDLERS
    # ===========================================================================
    $Global:ISO_browseBtn.Add_Click({
        $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
        $fbd.Description = "Select destination folder for ISOs"
        if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $Global:ISO_destBox.Text = $fbd.SelectedPath
        }
    })

    $Global:ISO_cancelBtn.Add_Click({
        ISO-RequestCancel
    })

    $Global:ISO_startBtn.Add_Click({
        try {
            ISO-AddLog "Start requested." "INFO"

            if ($null -ne $Global:ISO_bgHandle -and -not $Global:ISO_bgHandle.IsCompleted) {
                ISO-AddLog "A download operation is already running." "WARN"
                return
            }
            ISO-CleanupBackground

            $dest = $Global:ISO_destBox.Text.Trim()
            if ($dest -eq "") {
                ISO-AddLog "No destination folder specified." "FAIL"
                return
            }
            if (-not (Test-Path $dest)) {
                try {
                    New-Item -ItemType Directory -Path $dest -Force | Out-Null
                    ISO-AddLog "Created folder: $dest" "INFO"
                } catch {
                    ISO-AddLog "Cannot create folder: $dest" "FAIL"
                    return
                }
            }
            
            $selectedNames = @()
            if (ISO-IsChecked $Global:ISO_cbUbuntuDesktop)    { $selectedNames += "Ubuntu Desktop" }
            if (ISO-IsChecked $Global:ISO_cbUbuntuServer)     { $selectedNames += "Ubuntu Server" }
            if (ISO-IsChecked $Global:ISO_cbDebianNetinst)    { $selectedNames += "Debian Netinst" }
            if (ISO-IsChecked $Global:ISO_cbDebianLive)       { $selectedNames += "Debian Live Desktop" }
            if (ISO-IsChecked $Global:ISO_cbFedoraWorkstation){ $selectedNames += "Fedora Workstation" }
            if (ISO-IsChecked $Global:ISO_cbFedoraServer)     { $selectedNames += "Fedora Server" }
            if (ISO-IsChecked $Global:ISO_cbArchInstaller)    { $selectedNames += "Arch Linux Installer" }
            if (ISO-IsChecked $Global:ISO_cbCachyOSDesktop)   { $selectedNames += "CachyOS Desktop" }
            if (ISO-IsChecked $Global:ISO_cbPopOSNvidia)      { $selectedNames += "Pop!_OS NVIDIA" }
            if (ISO-IsChecked $Global:ISO_cbPopOSIntel)       { $selectedNames += "Pop!_OS Intel/AMD" }
            ISO-AddLog "Selected distributions: $($selectedNames -join ', ')" "INFO"
            ISO-AddLog "Resolving latest ISO URLs..." "INFO"
            ISO-PumpUi

            $jobs = ISO-GetJobList -Dest $dest -Token $Global:ISO_cancelFlag.Token
            if ($jobs.Count -eq 0) {
                ISO-AddLog "No distributions selected." "WARN"
                return
            }
            for ($idx = 0; $idx -lt $jobs.Count; $idx++) {
                $jobs[$idx]["JobKey"] = "iso-$idx"
            }

            $errorLogPath = if (Get-Command -Name Get-PowerToolsErrorLogPath -ErrorAction SilentlyContinue) {
                Get-PowerToolsErrorLogPath
            } else {
                Join-Path $env:TEMP "WindowsAcolyte-errors.jsonl"
            }
            foreach ($job in $jobs) {
                $job.ErrorLogPath = $errorLogPath
            }

            ISO-AddLog "Destination: $dest" "INFO"
            ISO-AddLog "Detailed error log: $errorLogPath" "INFO"

            $Global:ISO_cancelFlag = [System.Threading.CancellationTokenSource]::new()
            $token = $Global:ISO_cancelFlag.Token

            # clear stale queue messages from previous run
            $item = $null
            while ($Global:ISO_msgQueue.TryDequeue([ref]$item)) {}

            ISO-InitializeProgressRows -Jobs $jobs
            $Global:ISO_progress.Value         = 0
            $Global:ISO_pctLabel.Text          = "0%"
            $Global:ISO_statusLabel.Foreground = $Global:PTS_Brush["TextMuted"]
            $Global:ISO_statusLabel.Text       = "Downloading $($jobs.Count) ISO(s)..."
            ISO-SetUI-Busy $true
            ISO-RegisterActiveDownload
            ISO-StartTimer

            $maxPar = 3
            if ($Global:ISO_parallel.SelectedItem -and $Global:ISO_parallel.SelectedItem.Content) {
                [void][int]::TryParse("$($Global:ISO_parallel.SelectedItem.Content)", [ref]$maxPar)
            }
            if ($maxPar -lt 1) { $maxPar = 1 }

            $capturedJobs   = @($jobs)
            $capturedRunner = ${function:Global:ISO-RunDownloads}
            $capturedQueue  = $Global:ISO_msgQueue
            $capturedWorker = $Global:ISO_WorkerScript

            $Global:ISO_bgPS = [System.Management.Automation.PowerShell]::Create()
            $null = $Global:ISO_bgPS.AddScript($capturedRunner).AddArgument($capturedJobs).AddArgument($token).AddArgument($capturedQueue).AddArgument($maxPar).AddArgument($capturedWorker)
            $Global:ISO_bgHandle = $Global:ISO_bgPS.BeginInvoke()
            ISO-AddLog "Download coordinator started (parallel max: $maxPar)." "INFO"
        } catch {
            ISO-AddLog "Failed to start download operation: $($_.ToString())" "FAIL"
            $Global:ISO_statusLabel.Text       = "Error during startup."
            $Global:ISO_statusLabel.Foreground = $Global:PTS_Brush["Danger"]
            ISO-SetUI-Busy $false
            ISO-UnregisterActiveDownload
            ISO-CleanupBackground
        }
    })

    $Global:ISO_clearLog.Add_Click({
        $Global:ISO_logBox.Text = $Global:ISO_initText
    })

    return $view
}
