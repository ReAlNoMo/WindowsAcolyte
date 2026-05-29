# Module: Rescue ISO Downloader
# Downloads current rescue, partitioning, cloning, malware cleanup, and boot repair images.

Register-PowerToolsModule `
    -Id          "rescue-iso-downloader" `
    -Name        "Rescue ISO Downloader" `
    -Description "Download latest rescue, partitioning, cloning, malware cleanup, memory test, wipe, and boot repair images." `
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
        <RowDefinition Height="*"/>
    </Grid.RowDefinitions>

    <Border Grid.Row="0" x:Name="InfoBorder"
            BorderThickness="1.5" CornerRadius="10" Padding="16,14" Margin="0,0,0,12">
        <TextBlock x:Name="InfoText" FontSize="13" TextWrapping="Wrap" LineHeight="20"
                   Text="Download current rescue ISOs for data recovery, partitioning, cloning, malware cleanup, RAM testing, secure wiping, and boot repair. Finished downloads replace older matching files in the destination folder."/>
    </Border>

    <StackPanel Grid.Row="1" Margin="0,0,0,14">
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

    <StackPanel Grid.Row="2" Margin="0,0,0,14">
        <TextBlock Text="RESCUE TOOLS" Foreground="{DynamicResource DynSectionLabel}" FontSize="10"
                   FontWeight="Bold" Margin="0,0,0,8"/>
        <WrapPanel ItemWidth="215">
            <CheckBox x:Name="CbSystemRescue" Content="SystemRescue" IsChecked="True" FontSize="13" Margin="0,0,16,8"/>
            <CheckBox x:Name="CbGParted" Content="GParted Live" IsChecked="True" FontSize="13" Margin="0,0,16,8"/>
            <CheckBox x:Name="CbRescuezilla" Content="Rescuezilla" IsChecked="True" FontSize="13" Margin="0,0,16,8"/>
            <CheckBox x:Name="CbClonezilla" Content="Clonezilla Live" IsChecked="True" FontSize="13" Margin="0,0,16,8"/>
            <CheckBox x:Name="CbHiren" Content="Hiren's BootCD PE" IsChecked="True" FontSize="13" Margin="0,0,16,8"/>
            <CheckBox x:Name="CbKaspersky" Content="Kaspersky Rescue Disk" IsChecked="True" FontSize="13" Margin="0,0,16,8"/>
            <CheckBox x:Name="CbAvira" Content="Avira Rescue System" IsChecked="True" FontSize="13" Margin="0,0,16,8"/>
            <CheckBox x:Name="CbMemtest" Content="Memtest86+" IsChecked="True" FontSize="13" Margin="0,0,16,8"/>
            <CheckBox x:Name="CbShredOS" Content="ShredOS" IsChecked="True" FontSize="13" Margin="0,0,16,8"/>
            <CheckBox x:Name="CbSuperGrub" Content="Super Grub2 Disk" IsChecked="True" FontSize="13" Margin="0,0,16,8"/>
        </WrapPanel>
    </StackPanel>

    <Grid Grid.Row="3" Margin="0,0,0,14">
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
                <ComboBoxItem Content="2" IsSelected="True"/>
                <ComboBoxItem Content="3"/>
                <ComboBoxItem Content="4"/>
            </ComboBox>
        </StackPanel>
        <Button Grid.Column="2" x:Name="StartBtn" Content="Start Download"
                Style="{DynamicResource PrimaryButton}" Height="40" VerticalAlignment="Bottom"/>
        <Button Grid.Column="4" x:Name="CancelBtn" Content="Cancel"
                Style="{DynamicResource SecondaryButton}" Height="40"
                VerticalAlignment="Bottom" IsEnabled="False"/>
    </Grid>

    <Grid Grid.Row="4" Margin="0,0,0,4">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock x:Name="StatusLabel" Grid.Column="0"
                   Text="Idle" Foreground="{DynamicResource DynTextMuted}" FontSize="11" VerticalAlignment="Center"/>
        <TextBlock x:Name="PctLabel" Grid.Column="1"
                   Text="" Foreground="{DynamicResource DynAccent}" FontSize="11" FontWeight="Bold" VerticalAlignment="Center"/>
    </Grid>
    <ProgressBar Grid.Row="5" x:Name="ProgressBar" Height="8"
                 Minimum="0" Maximum="100" Value="0" Margin="0,0,0,14"/>

    <Grid Grid.Row="6">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0" x:Name="ProgressListBorder"
                BorderThickness="1.5" CornerRadius="10"
                Padding="10" Margin="0,0,0,14"
                Visibility="Collapsed" MaxHeight="260">
            <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                <StackPanel x:Name="DownloadProgressPanel"/>
            </ScrollViewer>
        </Border>

        <Grid Grid.Row="1" Margin="0,0,0,8">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock Text="ACTIVITY LOG" Foreground="{DynamicResource DynSectionLabel}" FontSize="10"
                       FontWeight="Bold" VerticalAlignment="Center"/>
            <Button x:Name="ClearLogBtn" Grid.Column="1" Content="Clear Log"
                    Style="{DynamicResource SecondaryButton}" Padding="12,6" FontSize="11"/>
        </Grid>

        <Border Grid.Row="2" x:Name="LogBorder"
                BorderThickness="1.5" CornerRadius="10" MinHeight="140">
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
</Grid>
"@

    $win    = Get-PowerToolsWindow
    $reader = New-Object System.Xml.XmlNodeReader $viewXaml
    $view   = [Windows.Markup.XamlReader]::Load($reader)

    foreach ($k in @("PrimaryButton","SecondaryButton")) {
        $view.Resources.Add($k, $win.FindResource($k))
    }

    $Global:RISO_infoBorder = $view.FindName("InfoBorder")
    $Global:RISO_infoText   = $view.FindName("InfoText")
    $Global:RISO_destBox    = $view.FindName("DestBox")
    $Global:RISO_browseBtn  = $view.FindName("BrowseBtn")
    $Global:RISO_parallel   = $view.FindName("ParallelCombo")
    $Global:RISO_startBtn   = $view.FindName("StartBtn")
    $Global:RISO_cancelBtn  = $view.FindName("CancelBtn")
    $Global:RISO_progress   = $view.FindName("ProgressBar")
    $Global:RISO_statusLabel = $view.FindName("StatusLabel")
    $Global:RISO_pctLabel   = $view.FindName("PctLabel")
    $Global:RISO_progressListBorder = $view.FindName("ProgressListBorder")
    $Global:RISO_progressPanel = $view.FindName("DownloadProgressPanel")
    $Global:RISO_clearLog   = $view.FindName("ClearLogBtn")
    $Global:RISO_logBox     = $view.FindName("LogBox")
    $Global:RISO_logBorder  = $view.FindName("LogBorder")
    $Global:RISO_initText   = "Ready."
    $Global:RISO_msgQueue   = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    $Global:RISO_timer      = $null
    $Global:RISO_cancelFlag = [System.Threading.CancellationTokenSource]::new()
    $Global:RISO_bgPS       = $null
    $Global:RISO_bgHandle   = $null
    $Global:RISO_progressRows = @{}

    $Global:RISO_checks = [ordered]@{
        SystemRescue = $view.FindName("CbSystemRescue")
        GParted      = $view.FindName("CbGParted")
        Rescuezilla  = $view.FindName("CbRescuezilla")
        Clonezilla   = $view.FindName("CbClonezilla")
        Hiren        = $view.FindName("CbHiren")
        Kaspersky    = $view.FindName("CbKaspersky")
        Avira        = $view.FindName("CbAvira")
        Memtest      = $view.FindName("CbMemtest")
        ShredOS      = $view.FindName("CbShredOS")
        SuperGrub    = $view.FindName("CbSuperGrub")
    }

    $Global:RISO_destBox.Text = Join-Path $env:USERPROFILE "Downloads\RescueISOs"

    $Global:RISO_infoBorder.Background = $Global:PTS_Brush["Surface"]
    $Global:RISO_infoBorder.BorderBrush = $Global:PTS_Brush["Border"]
    $Global:RISO_infoText.Foreground = $Global:PTS_Brush["TextMid"]
    $Global:RISO_destBox.Background = $Global:PTS_Brush["InputBg"]
    $Global:RISO_destBox.Foreground = $Global:PTS_Brush["InputFg"]
    $Global:RISO_destBox.BorderBrush = $Global:PTS_Brush["Border"]
    $Global:RISO_parallel.Foreground = $Global:PTS_Brush["InputFg"]
    $Global:RISO_parallel.Background = $Global:PTS_Brush["InputBg"]
    $Global:RISO_parallel.BorderBrush = $Global:PTS_Brush["Border"]
    $Global:RISO_logBox.Foreground = $Global:PTS_Brush["TextMuted"]
    $Global:RISO_logBorder.Background = $Global:PTS_Brush["LogBg"]
    $Global:RISO_logBorder.BorderBrush = $Global:PTS_Brush["LogBorder"]
    $Global:RISO_progressListBorder.Background = $Global:PTS_Brush["Surface"]
    $Global:RISO_progressListBorder.BorderBrush = $Global:PTS_Brush["Border"]
    foreach ($cb in $Global:RISO_checks.Values) {
        if ($cb) { $cb.Foreground = $Global:PTS_Brush["TextMid"] }
    }
    foreach ($cbItem in $Global:RISO_parallel.Items) {
        if ($cbItem -is [System.Windows.Controls.ComboBoxItem]) {
            $cbItem.Foreground = $Global:PTS_Brush["InputFg"]
            $cbItem.Background = $Global:PTS_Brush["InputBg"]
        }
    }

    function Global:RISO-AddLog {
        param([string]$Msg, [string]$Type = "INFO")
        $ts  = Get-Date -Format "HH:mm:ss"
        $tag = switch ($Type) { "OK"{"[OK]  "} "FAIL"{"[FAIL]"} "WARN"{"[WARN]"} default{"[INFO]"} }
        $entry = "[$ts]  $tag  $Msg`n"
        if ($Global:RISO_logBox.Text -eq $Global:RISO_initText) { $Global:RISO_logBox.Text = $entry }
        else { $Global:RISO_logBox.Text += $entry }
        $Global:RISO_logBox.ScrollToEnd()
    }

    function Global:RISO-IsChecked {
        param([System.Windows.Controls.CheckBox]$CheckBox)
        return ($null -ne $CheckBox -and $CheckBox.IsChecked -eq $true)
    }

    function Global:RISO-SetUIBusy {
        param([bool]$Busy)
        $Global:RISO_startBtn.IsEnabled  = -not $Busy
        $Global:RISO_cancelBtn.IsEnabled = $Busy
        $Global:RISO_startBtn.Content    = if ($Busy) { "Downloading..." } else { "Start Download" }
    }

    function Global:RISO-CleanupBackground {
        if ($null -ne $Global:RISO_bgPS) {
            try {
                if ($null -ne $Global:RISO_bgHandle -and $Global:RISO_bgHandle.IsCompleted) {
                    $null = $Global:RISO_bgPS.EndInvoke($Global:RISO_bgHandle)
                }
            } catch {
            } finally {
                try { $Global:RISO_bgPS.Dispose() } catch {}
                $Global:RISO_bgPS = $null
                $Global:RISO_bgHandle = $null
            }
        }
    }

    function Global:RISO-ClearProgressRows {
        $Global:RISO_progressRows = @{}
        $Global:RISO_progressPanel.Children.Clear()
        $Global:RISO_progressListBorder.Visibility = [System.Windows.Visibility]::Collapsed
    }

    function Global:RISO-CreateProgressRow {
        param([string]$Key, [string]$Name, [string]$FileName)

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
        $Global:RISO_progressPanel.Children.Add($outer) | Out-Null
        $Global:RISO_progressRows[$Key] = [PSCustomObject]@{
            Percent = $pct
            Bar = $bar
            Detail = $detail
            State = "Queued"
        }
        $Global:RISO_progressListBorder.Visibility = [System.Windows.Visibility]::Visible
    }

    function Global:RISO-InitializeProgressRows {
        param([object[]]$Jobs)
        RISO-ClearProgressRows
        foreach ($job in $Jobs) {
            RISO-CreateProgressRow -Key $job.JobKey -Name $job.IsoName -FileName $job.FileName
        }
    }

    function Global:RISO-UpdateProgressRow {
        param([string]$Key, [string]$State, [int]$Pct, [string]$Detail)
        if (-not $Global:RISO_progressRows.ContainsKey($Key)) { return }
        $row = $Global:RISO_progressRows[$Key]
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
            }
            "Failed" {
                $row.Percent.Text = "Failed"
                $row.Percent.Foreground = $Global:PTS_Brush["Danger"]
            }
            "Cancelled" {
                $row.Percent.Text = "Cancelled"
                $row.Percent.Foreground = $Global:PTS_Brush["Warning"]
            }
            default {
                $row.Percent.Text = $State
                $row.Percent.Foreground = $Global:PTS_Brush["TextMuted"]
            }
        }
    }

    function Global:RISO-MarkUnfinishedProgressRows {
        param([string]$State, [string]$Detail)
        foreach ($key in @($Global:RISO_progressRows.Keys)) {
            $row = $Global:RISO_progressRows[$key]
            if ($row.State -notin @("Done","Failed","Cancelled")) {
                RISO-UpdateProgressRow -Key $key -State $State -Pct ([int]$row.Bar.Value) -Detail $Detail
            }
        }
    }

    function Global:RISO-StartTimer {
        $Global:RISO_timer = New-Object System.Windows.Threading.DispatcherTimer
        $Global:RISO_timer.Interval = [TimeSpan]::FromMilliseconds(200)
        $Global:RISO_timer.Add_Tick({
            $item = $null
            while ($Global:RISO_msgQueue.TryDequeue([ref]$item)) {
                switch ($item.Type) {
                    "LOG" {
                        RISO-AddLog -Msg $item.Msg -Type $item.Tag
                    }
                    "PROGRESS" {
                        $Global:RISO_progress.Value = $item.Pct
                        $Global:RISO_statusLabel.Text = $item.Status
                        $Global:RISO_pctLabel.Text = "$($item.Pct)%"
                    }
                    "FILE_PROGRESS" {
                        RISO-UpdateProgressRow -Key $item.JobKey -State "Running" -Pct $item.Pct -Detail $item.Detail
                    }
                    "FILE_STATE" {
                        RISO-UpdateProgressRow -Key $item.JobKey -State $item.State -Pct $item.Pct -Detail $item.Detail
                    }
                    "DONE" {
                        $Global:RISO_timer.Stop()
                        $Global:RISO_progress.Value = 100
                        $Global:RISO_pctLabel.Text = "100%"
                        $Global:RISO_statusLabel.Text = "All downloads complete."
                        $Global:RISO_statusLabel.Foreground = $Global:PTS_Brush["Success"]
                        RISO-SetUIBusy $false
                        RISO-CleanupBackground
                    }
                    "CANCELLED" {
                        $Global:RISO_timer.Stop()
                        RISO-MarkUnfinishedProgressRows -State "Cancelled" -Detail "Download operation cancelled."
                        $Global:RISO_statusLabel.Text = "Cancelled."
                        $Global:RISO_statusLabel.Foreground = $Global:PTS_Brush["Warning"]
                        RISO-SetUIBusy $false
                        RISO-CleanupBackground
                    }
                    "ERROR" {
                        $Global:RISO_timer.Stop()
                        RISO-MarkUnfinishedProgressRows -State "Cancelled" -Detail "Stopped because download operation ended with errors."
                        $Global:RISO_statusLabel.Text = "Error."
                        $Global:RISO_statusLabel.Foreground = $Global:PTS_Brush["Danger"]
                        RISO-SetUIBusy $false
                        RISO-CleanupBackground
                    }
                }
            }
        })
        $Global:RISO_timer.Start()
    }

    function Global:RISO-EnableTls {
        try {
            $proto = [System.Net.SecurityProtocolType]::Tls12
            if ([enum]::GetNames([System.Net.SecurityProtocolType]) -contains "Tls13") {
                $proto = $proto -bor [System.Net.SecurityProtocolType]::Tls13
            }
            [System.Net.ServicePointManager]::SecurityProtocol = $proto
        } catch {}
    }

    function Global:RISO-GetNewestReleaseName {
        param([string[]]$Names)
        $parsed = foreach ($name in ($Names | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
            if ($name -match "^(?<ver>\d+(?:\.\d+)+)(?:-(?<rev>\d+))?") {
                try {
                    [PSCustomObject]@{
                        Raw = $name
                        Version = [version]$Matches.ver
                        Rev = if ($Matches.rev) { [int]$Matches.rev } else { 0 }
                    }
                } catch {}
            }
        }
        if (-not $parsed) { return $null }
        return ($parsed | Sort-Object Version, Rev -Descending | Select-Object -First 1).Raw
    }

    function Global:RISO-GitHubLatestAsset {
        param(
            [Parameter(Mandatory)][string]$Repo,
            [Parameter(Mandatory)][scriptblock]$Filter,
            [scriptblock]$Sort
        )
        RISO-EnableTls
        $headers = @{ "User-Agent" = "WindowsAcolyte-RescueISODownloader" }
        $release = Invoke-RestMethod -Headers $headers -Uri "https://api.github.com/repos/$Repo/releases/latest" -TimeoutSec 20 -ErrorAction Stop
        $assets = @($release.assets | Where-Object $Filter)
        if ($Sort) { $assets = @($assets | Sort-Object -Property $Sort) }
        return ($assets | Select-Object -First 1)
    }

    function Global:RISO-GetSourceForgeDirectUrl {
        param(
            [Parameter(Mandatory)][string]$DownloadPageUrl,
            [Parameter(Mandatory)][string]$ExpectedFileName
        )
        RISO-EnableTls
        $headers = @{
            "User-Agent" = "Mozilla/5.0 WindowsAcolyte"
            "Accept"     = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        }
        $page = (Invoke-WebRequest -UseBasicParsing -Uri $DownloadPageUrl -Headers $headers -TimeoutSec 25 -ErrorAction Stop).Content
        $meta = [regex]::Match(
            $page,
            'url=(https://downloads\.sourceforge\.net/[^"<>]+?' + [regex]::Escape($ExpectedFileName) + '[^"<>]*)"',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
        if (-not $meta.Success) {
            $meta = [regex]::Match(
                $page,
                'https://downloads\.sourceforge\.net/[^"<>]+?' + [regex]::Escape($ExpectedFileName) + '[^"<>]*',
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            )
        }
        if (-not $meta.Success) {
            throw "SourceForge direct mirror URL not found for $ExpectedFileName."
        }

        $raw = if ($meta.Groups.Count -gt 1 -and -not [string]::IsNullOrWhiteSpace($meta.Groups[1].Value)) {
            $meta.Groups[1].Value
        } else {
            $meta.Value
        }
        return [System.Web.HttpUtility]::HtmlDecode($raw)
    }

    function Global:RISO-ResolveSystemRescue {
        RISO-EnableTls
        $page = (Invoke-WebRequest -UseBasicParsing -Uri "https://www.system-rescue.org/Download/" -TimeoutSec 20 -ErrorAction Stop).Content
        $name = ([regex]::Match($page, "systemrescue-[0-9.]+-amd64\.iso")).Value
        if (-not $name) { throw "SystemRescue ISO name not found." }
        $version = ([regex]::Match($name, "[0-9.]+")).Value
        return @(
            "https://fastly-cdn.system-rescue.org/releases/$version/$name",
            "https://sourceforge.net/projects/systemrescuecd/files/sysresccd-x86/$version/$name/download"
        )
    }

    function Global:RISO-ResolveGParted {
        RISO-EnableTls
        $base = "https://sourceforge.net/projects/gparted/files/gparted-live-stable/"
        $page = (Invoke-WebRequest -UseBasicParsing -Uri $base -TimeoutSec 20 -ErrorAction Stop).Content
        $dirs = [regex]::Matches($page, "/projects/gparted/files/gparted-live-stable/([^/""<>]+)/") |
            ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
        $latest = RISO-GetNewestReleaseName -Names $dirs
        if (-not $latest) { throw "GParted release directory not found." }
        $releasePage = (Invoke-WebRequest -UseBasicParsing -Uri "$base$latest/" -TimeoutSec 20 -ErrorAction Stop).Content
        $name = ([regex]::Match($releasePage, "gparted-live-[0-9.]+-[0-9]+-amd64\.iso")).Value
        if (-not $name) { throw "GParted ISO name not found." }
        $downloadPage = "$base$latest/$name/download"
        $directUrl = RISO-GetSourceForgeDirectUrl -DownloadPageUrl $downloadPage -ExpectedFileName $name
        return @($directUrl, $downloadPage)
    }

    function Global:RISO-ResolveRescuezilla {
        $asset = RISO-GitHubLatestAsset -Repo "rescuezilla/rescuezilla" -Filter {
            $_.name -match "64bit.*\.iso$" -and $_.name -match "resolute|questing|noble|oracular|jammy"
        } -Sort {
            if ($_.name -match "resolute") { 0 }
            elseif ($_.name -match "questing") { 1 }
            elseif ($_.name -match "noble") { 2 }
            elseif ($_.name -match "oracular") { 3 }
            else { 9 }
        }
        if (-not $asset) {
            $asset = RISO-GitHubLatestAsset -Repo "rescuezilla/rescuezilla" -Filter { $_.name -match "64bit.*\.iso$" }
        }
        if (-not $asset) { throw "Rescuezilla ISO asset not found." }
        return @($asset.browser_download_url)
    }

    function Global:RISO-ResolveClonezilla {
        RISO-EnableTls
        $base = "https://sourceforge.net/projects/clonezilla/files/clonezilla_live_stable/"
        $page = (Invoke-WebRequest -UseBasicParsing -Uri $base -TimeoutSec 20 -ErrorAction Stop).Content
        $dirs = [regex]::Matches($page, "/projects/clonezilla/files/clonezilla_live_stable/([^/""<>]+)/") |
            ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
        $latest = RISO-GetNewestReleaseName -Names $dirs
        if (-not $latest) { throw "Clonezilla release directory not found." }
        $releasePage = (Invoke-WebRequest -UseBasicParsing -Uri "$base$latest/" -TimeoutSec 20 -ErrorAction Stop).Content
        $name = ([regex]::Match($releasePage, "clonezilla-live-[0-9.]+-[0-9]+-amd64\.iso")).Value
        if (-not $name) { throw "Clonezilla ISO name not found." }
        $downloadPage = "$base$latest/$name/download"
        $directUrl = RISO-GetSourceForgeDirectUrl -DownloadPageUrl $downloadPage -ExpectedFileName $name
        return @($directUrl, $downloadPage)
    }

    function Global:RISO-ResolveHiren {
        RISO-EnableTls
        try {
            $page = (Invoke-WebRequest -UseBasicParsing -Uri "https://www.hirensbootcd.org/download/" -TimeoutSec 20 -ErrorAction Stop).Content
            $url = ([regex]::Match($page, "https?://[^""'<> ]+HBCD_PE_x64\.iso")).Value
            if ($url) { return @($url) }
        } catch {}
        return @("https://www.hirensbootcd.org/files/HBCD_PE_x64.iso")
    }

    function Global:RISO-ResolveMemtest {
        RISO-EnableTls
        $page = (Invoke-WebRequest -UseBasicParsing -Uri "https://memtest.org/" -TimeoutSec 20 -ErrorAction Stop).Content
        $path = ([regex]::Match($page, "/download/v[^""'<> ]+/mt86plus_[^""'<> ]+_x86_64\.iso\.zip")).Value
        if (-not $path) { throw "Memtest86+ ISO ZIP link not found." }
        return @("https://memtest.org$path")
    }

    function Global:RISO-ResolveShredOS {
        $asset = RISO-GitHubLatestAsset -Repo "PartialVolume/shredos.x86_64" -Filter {
            $_.name -match "x86-64.*\.iso$" -and $_.name -notmatch "_lite|plus-partition"
        }
        if (-not $asset) {
            $asset = RISO-GitHubLatestAsset -Repo "PartialVolume/shredos.x86_64" -Filter {
                $_.name -match "x86-64.*\.iso$"
            }
        }
        if (-not $asset) { throw "ShredOS ISO asset not found." }
        return @($asset.browser_download_url)
    }

    function Global:RISO-ResolveSuperGrub {
        RISO-EnableTls
        [xml]$rss = (Invoke-WebRequest -UseBasicParsing -Uri "https://sourceforge.net/projects/supergrub2/rss?path=/" -TimeoutSec 20 -ErrorAction Stop).Content
        $items = @($rss.rss.channel.item)
        $preferred = $items | Where-Object {
            $title = if ($_.title.'#cdata-section') { $_.title.'#cdata-section' } else { [string]$_.title }
            $title -match "supergrub2-classic-.*x86_64_efi-CD\.iso$"
        } | Select-Object -First 1

        if (-not $preferred) {
            $preferred = $items | Where-Object {
                $title = if ($_.title.'#cdata-section') { $_.title.'#cdata-section' } else { [string]$_.title }
                $title -match "supergrub2-classic-.*multiarch-CD\.iso$"
            } | Select-Object -First 1
        }

        if (-not $preferred) { throw "Super Grub2 Disk ISO not found in SourceForge RSS." }
        $link = [string]$preferred.link
        $name = [System.IO.Path]::GetFileName(($link -replace "/download$", ""))
        $directUrl = RISO-GetSourceForgeDirectUrl -DownloadPageUrl $link -ExpectedFileName $name
        return @($directUrl, $link)
    }

    function Global:RISO-NewJob {
        param(
            [string]$Name,
            [string]$FileName,
            [string]$OutFile,
            [string[]]$UrlList,
            [string[]]$CleanupPatterns,
            [bool]$ExtractIso = $false,
            [string]$ExtractPattern = "*.iso"
        )
        return @{
            IsoName = $Name
            FileName = $FileName
            OutFile = $OutFile
            UrlList = @($UrlList)
            CleanupPatterns = @($CleanupPatterns)
            ExtractIso = $ExtractIso
            ExtractPattern = $ExtractPattern
            JobKey = ([guid]::NewGuid().ToString("N"))
        }
    }

    function Global:RISO-AddJobSafe {
        param(
            [System.Collections.Generic.List[object]]$Jobs,
            [string]$Name,
            [string]$FileName,
            [string]$OutFile,
            [scriptblock]$Resolver,
            [string[]]$CleanupPatterns,
            [bool]$ExtractIso = $false,
            [string]$ExtractPattern = "*.iso"
        )
        try {
            RISO-AddLog "Resolving latest source: $Name"
            $urls = @(& $Resolver)
            if (-not $urls -or $urls.Count -eq 0) { throw "No download URL resolved." }
            $Jobs.Add((RISO-NewJob -Name $Name -FileName $FileName -OutFile $OutFile -UrlList $urls -CleanupPatterns $CleanupPatterns -ExtractIso $ExtractIso -ExtractPattern $ExtractPattern)) | Out-Null
            RISO-AddLog "Resolved: $Name" "OK"
        } catch {
            RISO-AddLog "Resolve failed for $Name`: $($_.Exception.Message)" "FAIL"
        }
    }

    function Global:RISO-GetJobList {
        param([string]$Dest)

        $jobs = [System.Collections.Generic.List[object]]::new()

        if (RISO-IsChecked $Global:RISO_checks.SystemRescue) {
            RISO-AddJobSafe -Jobs $jobs -Name "SystemRescue" -FileName "systemrescue-latest-amd64.iso" -OutFile (Join-Path $Dest "systemrescue-latest-amd64.iso") -Resolver { RISO-ResolveSystemRescue } -CleanupPatterns @("systemrescue*.iso")
        }
        if (RISO-IsChecked $Global:RISO_checks.GParted) {
            RISO-AddJobSafe -Jobs $jobs -Name "GParted Live" -FileName "gparted-live-latest-amd64.iso" -OutFile (Join-Path $Dest "gparted-live-latest-amd64.iso") -Resolver { RISO-ResolveGParted } -CleanupPatterns @("gparted-live*.iso")
        }
        if (RISO-IsChecked $Global:RISO_checks.Rescuezilla) {
            RISO-AddJobSafe -Jobs $jobs -Name "Rescuezilla" -FileName "rescuezilla-latest-64bit.iso" -OutFile (Join-Path $Dest "rescuezilla-latest-64bit.iso") -Resolver { RISO-ResolveRescuezilla } -CleanupPatterns @("rescuezilla*.iso")
        }
        if (RISO-IsChecked $Global:RISO_checks.Clonezilla) {
            RISO-AddJobSafe -Jobs $jobs -Name "Clonezilla Live" -FileName "clonezilla-live-latest-amd64.iso" -OutFile (Join-Path $Dest "clonezilla-live-latest-amd64.iso") -Resolver { RISO-ResolveClonezilla } -CleanupPatterns @("clonezilla-live*.iso")
        }
        if (RISO-IsChecked $Global:RISO_checks.Hiren) {
            RISO-AddJobSafe -Jobs $jobs -Name "Hiren's BootCD PE" -FileName "hirens-bootcd-pe-latest-x64.iso" -OutFile (Join-Path $Dest "hirens-bootcd-pe-latest-x64.iso") -Resolver { RISO-ResolveHiren } -CleanupPatterns @("hiren*.iso","HBCD*.iso")
        }
        if (RISO-IsChecked $Global:RISO_checks.Kaspersky) {
            RISO-AddJobSafe -Jobs $jobs -Name "Kaspersky Rescue Disk" -FileName "kaspersky-rescue-disk-latest.iso" -OutFile (Join-Path $Dest "kaspersky-rescue-disk-latest.iso") -Resolver { @("https://rescuedisk.s.kaspersky-labs.com/latest/krd.iso") } -CleanupPatterns @("kaspersky-rescue*.iso","krd*.iso")
        }
        if (RISO-IsChecked $Global:RISO_checks.Avira) {
            RISO-AddJobSafe -Jobs $jobs -Name "Avira Rescue System" -FileName "avira-rescue-system-latest.iso" -OutFile (Join-Path $Dest "avira-rescue-system-latest.iso") -Resolver { @("https://download.avira.com/download/rescue-system/avira-rescue-system.iso") } -CleanupPatterns @("avira-rescue*.iso")
        }
        if (RISO-IsChecked $Global:RISO_checks.Memtest) {
            RISO-AddJobSafe -Jobs $jobs -Name "Memtest86+" -FileName "memtest86plus-latest-x86_64.iso" -OutFile (Join-Path $Dest "memtest86plus-latest-x86_64.iso") -Resolver { RISO-ResolveMemtest } -CleanupPatterns @("memtest86plus*.iso","mt86plus*.iso") -ExtractIso $true -ExtractPattern "*x86_64*.iso"
        }
        if (RISO-IsChecked $Global:RISO_checks.ShredOS) {
            RISO-AddJobSafe -Jobs $jobs -Name "ShredOS" -FileName "shredos-latest-x86_64.iso" -OutFile (Join-Path $Dest "shredos-latest-x86_64.iso") -Resolver { RISO-ResolveShredOS } -CleanupPatterns @("shredos*.iso")
        }
        if (RISO-IsChecked $Global:RISO_checks.SuperGrub) {
            RISO-AddJobSafe -Jobs $jobs -Name "Super Grub2 Disk" -FileName "super-grub2-disk-latest-x86_64_efi.iso" -OutFile (Join-Path $Dest "super-grub2-disk-latest-x86_64_efi.iso") -Resolver { RISO-ResolveSuperGrub } -CleanupPatterns @("super*grub*.iso","sgd*.iso") -ExtractIso $true -ExtractPattern "*x86_64*efi*CD*.iso"
        }

        return @($jobs)
    }

    $Global:RISO_WorkerScript = {
        param($Job, $Queue, $CancelToken)

        function Q-Log { param($M,$T) $Queue.Enqueue([PSCustomObject]@{Type="LOG";Msg=$M;Tag=$T}) }
        function Q-FileProg { param($P,$D) $Queue.Enqueue([PSCustomObject]@{Type="FILE_PROGRESS";JobKey=$Job["JobKey"];Pct=$P;Detail=$D}) }
        function Q-FileState { param($S,$P,$D) $Queue.Enqueue([PSCustomObject]@{Type="FILE_STATE";JobKey=$Job["JobKey"];State=$S;Pct=$P;Detail=$D}) }

        function Remove-OldMatchingFiles {
            param([string]$OutFile, [string[]]$Patterns)
            $dir = Split-Path -Parent $OutFile
            $targetName = [System.IO.Path]::GetFileName($OutFile)
            foreach ($pattern in $Patterns) {
                Get-ChildItem -LiteralPath $dir -Filter $pattern -File -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -ne $targetName -and $_.Name -notlike "*.tmp" } |
                    Remove-Item -Force -ErrorAction SilentlyContinue
            }
        }

        function Complete-DownloadedFile {
            param([string]$TempPath, [hashtable]$Job)
            if ($Job.ExtractIso) {
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                $extractDir = Join-Path (Split-Path -Parent $Job.OutFile) ("_extract_" + $Job.JobKey)
                if (Test-Path -LiteralPath $extractDir) { Remove-Item -LiteralPath $extractDir -Recurse -Force -ErrorAction SilentlyContinue }
                New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
                [System.IO.Compression.ZipFile]::ExtractToDirectory($TempPath, $extractDir)
                $iso = Get-ChildItem -LiteralPath $extractDir -Filter $Job.ExtractPattern -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                if (-not $iso) {
                    $iso = Get-ChildItem -LiteralPath $extractDir -Filter "*.iso" -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                }
                if (-not $iso) { throw "No ISO found inside archive." }
                Remove-OldMatchingFiles -OutFile $Job.OutFile -Patterns $Job.CleanupPatterns
                Copy-Item -LiteralPath $iso.FullName -Destination $Job.OutFile -Force
                Remove-Item -LiteralPath $extractDir -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $TempPath -Force -ErrorAction SilentlyContinue
            } else {
                Remove-OldMatchingFiles -OutFile $Job.OutFile -Patterns $Job.CleanupPatterns
                Move-Item -LiteralPath $TempPath -Destination $Job.OutFile -Force
            }
        }

        $result = [PSCustomObject]@{ Success=$false; IsoName=$Job.IsoName; Message="" }
        $tmp = "$($Job.OutFile).tmp"
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
                    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
                    $req = [System.Net.HttpWebRequest]::Create($url)
                    $req.AllowAutoRedirect = $true
                    $req.UserAgent = "WindowsAcolyte-RescueISODownloader/1.0"
                    $req.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
                    $req.Timeout = 90000
                    $req.ReadWriteTimeout = 90000
                    $resp = $req.GetResponse()
                    $total = $resp.ContentLength
                    $contentType = $resp.ContentType
                    $finalUrl = $resp.ResponseUri.AbsoluteUri
                    if ($contentType -match "text/html" -or ($finalUrl -match "sourceforge\.net/projects/.*/files/" -and $finalUrl -notmatch "\.dl\.sourceforge\.net")) {
                        throw "Source returned HTML instead of a downloadable ISO/archive. Resolver needs a direct mirror URL."
                    }
                    $stream = $resp.GetResponseStream()
                    $fs = [System.IO.File]::Create($tmp)
                    $buf = New-Object byte[] (256KB)
                    $read = 0
                    $sw = [System.Diagnostics.Stopwatch]::StartNew()
                    $lastReport = 0

                    while (-not $CancelToken.IsCancellationRequested) {
                        $n = $stream.Read($buf, 0, $buf.Length)
                        if ($n -le 0) { break }
                        $fs.Write($buf, 0, $n)
                        $read += $n

                        if ($sw.ElapsedMilliseconds - $lastReport -ge 500) {
                            $lastReport = $sw.ElapsedMilliseconds
                            $mbDone = [math]::Round($read / 1MB, 1)
                            $mbTotal = if ($total -gt 0) { [math]::Round($total / 1MB, 1) } else { "?" }
                            $speed = if ($sw.Elapsed.TotalSeconds -gt 0) { [math]::Round($read / 1MB / $sw.Elapsed.TotalSeconds, 1) } else { 0 }
                            $eta = if ($total -gt 0 -and $speed -gt 0) { "$([math]::Round(($total - $read) / 1MB / $speed))s" } else { "..." }
                            $filePct = if ($total -gt 0) { [int](($read / $total) * 100) } else { 0 }
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
                        Q-FileState "Running" 99 "$($Job.FileName)  |  finalizing..."
                        Complete-DownloadedFile -TempPath $tmp -Job $Job
                        $sizeMB = [math]::Round((Get-Item -LiteralPath $Job.OutFile).Length / 1MB, 1)
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
                    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
                    Q-Log "URL failed ($url) [attempt $attempt/2]: $($_.Exception.Message)" "WARN"
                    if ($attempt -lt 2 -and -not $CancelToken.IsCancellationRequested) {
                        Start-Sleep -Seconds (2 * $attempt)
                    }
                }
            }
            if ($downloaded) { break }
        }

        if (-not $downloaded -and -not $CancelToken.IsCancellationRequested) {
            $result.Message = "All URLs failed"
            Q-Log "FAILED: $($Job.IsoName) - all URLs exhausted" "FAIL"
            Q-FileState "Failed" 0 "$($Job.FileName)  |  all URLs exhausted"
        }
        if ($CancelToken.IsCancellationRequested) {
            $result.Message = "Cancelled"
            Q-FileState "Cancelled" 0 "$($Job.FileName)  |  cancelled"
        }

        return $result
    }

    function Global:RISO-RunDownloads {
        param(
            [object[]]$Jobs,
            [System.Threading.CancellationToken]$CancelToken,
            [System.Collections.Concurrent.ConcurrentQueue[object]]$Queue,
            [int]$MaxPar,
            [scriptblock]$WorkerScript
        )

        try {
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
                $Queue.Enqueue([PSCustomObject]@{ Type = "LOG"; Msg = "Queueing job: $($Jobs[$i].IsoName)"; Tag = "INFO" })
                $ps = [System.Management.Automation.PowerShell]::Create()
                $ps.RunspacePool = $pool
                $null = $ps.AddScript($WorkerScript).AddArgument($Jobs[$i]).AddArgument($Queue).AddArgument($CancelToken)
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
                                $Queue.Enqueue([PSCustomObject]@{ Type = "LOG"; Msg = "Job failed: $($r.Job.IsoName) ($reason)"; Tag = "FAIL" })
                            }
                        } catch {
                            $failed++
                            $Queue.Enqueue([PSCustomObject]@{ Type = "LOG"; Msg = "Worker exception: $($_.ToString())"; Tag = "FAIL" })
                        } finally {
                            $r.PS.Dispose()
                        }

                        $pct = [int](($done / $total) * 100)
                        $Queue.Enqueue([PSCustomObject]@{ Type = "PROGRESS"; Pct = $pct; Status = "$done / $total complete ($ok OK, $failed failed)" })
                    }
                }

                if ($CancelToken.IsCancellationRequested) {
                    $Queue.Enqueue([PSCustomObject]@{ Type = "CANCELLED" })
                    break
                }
            }
        } catch {
            $Queue.Enqueue([PSCustomObject]@{ Type = "LOG"; Msg = "Coordinator failed: $($_.Exception.Message)"; Tag = "FAIL" })
            $Queue.Enqueue([PSCustomObject]@{ Type = "ERROR" })
        } finally {
            if ($pool) {
                try { $pool.Close() } catch {}
                try { $pool.Dispose() } catch {}
            }
        }

        if ($CancelToken.IsCancellationRequested) {
            $Queue.Enqueue([PSCustomObject]@{ Type = "CANCELLED" })
        } else {
            $Queue.Enqueue([PSCustomObject]@{ Type = "DONE" })
        }
    }

    function Global:RISO-StartDownload {
        $dest = $Global:RISO_destBox.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($dest)) {
            RISO-AddLog "Destination folder is empty." "FAIL"
            return
        }

        try {
            if (-not (Test-Path -LiteralPath $dest)) {
                New-Item -ItemType Directory -Path $dest -Force | Out-Null
            }
        } catch {
            RISO-AddLog "Cannot create destination folder: $($_.Exception.Message)" "FAIL"
            return
        }

        RISO-SetUIBusy $true
        $Global:RISO_progress.Value = 0
        $Global:RISO_pctLabel.Text = "0%"
        $Global:RISO_statusLabel.Text = "Resolving latest downloads..."
        $Global:RISO_statusLabel.Foreground = $Global:PTS_Brush["TextMuted"]
        $Global:RISO_msgQueue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()

        $jobs = @(RISO-GetJobList -Dest $dest)
        if (-not $jobs -or $jobs.Count -eq 0) {
            RISO-AddLog "No tools selected or no download sources resolved." "FAIL"
            RISO-SetUIBusy $false
            return
        }

        for ($i = 0; $i -lt $jobs.Count; $i++) {
            $jobs[$i]["JobKey"] = ([guid]::NewGuid().ToString("N"))
        }

        RISO-InitializeProgressRows -Jobs $jobs
        $Global:RISO_statusLabel.Text = "Starting $($jobs.Count) download(s)..."

        $selected = $Global:RISO_parallel.SelectedItem
        $maxPar = 2
        if ($selected -is [System.Windows.Controls.ComboBoxItem]) {
            [int]::TryParse([string]$selected.Content, [ref]$maxPar) | Out-Null
        }

        if ($Global:RISO_cancelFlag) { try { $Global:RISO_cancelFlag.Dispose() } catch {} }
        $Global:RISO_cancelFlag = [System.Threading.CancellationTokenSource]::new()
        RISO-StartTimer

        $runDownloadsScript = ${function:RISO-RunDownloads}
        $Global:RISO_bgPS = [System.Management.Automation.PowerShell]::Create()
        $null = $Global:RISO_bgPS.AddScript({
            param($Jobs, $Token, $Queue, $MaxPar, $WorkerScript, $RunDownloadsScript)
            & $RunDownloadsScript -Jobs $Jobs -CancelToken $Token -Queue $Queue -MaxPar $MaxPar -WorkerScript $WorkerScript
        }).AddArgument($jobs).AddArgument($Global:RISO_cancelFlag.Token).AddArgument($Global:RISO_msgQueue).AddArgument($maxPar).AddArgument($Global:RISO_WorkerScript).AddArgument($runDownloadsScript)
        $Global:RISO_bgHandle = $Global:RISO_bgPS.BeginInvoke()
    }

    $Global:RISO_browseBtn.Add_Click({
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description = "Select destination folder for rescue ISO downloads"
        $dlg.SelectedPath = $Global:RISO_destBox.Text
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $Global:RISO_destBox.Text = $dlg.SelectedPath
        }
    })

    $Global:RISO_startBtn.Add_Click({ RISO-StartDownload })

    $Global:RISO_cancelBtn.Add_Click({
        if ($Global:RISO_cancelFlag) {
            $Global:RISO_cancelFlag.Cancel()
            RISO-AddLog "Cancellation requested..." "WARN"
        }
    })

    $Global:RISO_clearLog.Add_Click({
        $Global:RISO_logBox.Text = $Global:RISO_initText
    })

    return $view
}
