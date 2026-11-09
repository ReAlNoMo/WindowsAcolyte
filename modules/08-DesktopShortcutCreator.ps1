# Module: Desktop Shortcut Creator
# Creates WindowsAcolyte launch shortcuts on the current user's Desktop.

Register-PowerToolsModule `
    -Id          "desktop-shortcut-creator" `
    -Name        "WindowsAcolyte Desktop Shortcut Creator" `
    -Description "Create WindowsAcolyte shortcuts with a mandatory online update check." `
    -Category    "Windows Tweaks" `
    -Show        {

    [xml]$viewXaml = @"
<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
    </Grid.RowDefinitions>

    <Border Grid.Row="0" x:Name="InfoBorder"
            BorderThickness="1.5" CornerRadius="10" Padding="18,16" Margin="0,0,0,12">
        <StackPanel>
            <TextBlock Text="DESKTOP SHORTCUTS" Foreground="{DynamicResource DynSectionLabel}" FontSize="10"
                       FontWeight="Bold" Margin="0,0,0,8"/>
            <TextBlock x:Name="InfoText" FontSize="13" TextWrapping="Wrap" LineHeight="20"
                       Text="Install downloads and updates the permanent local app. Online runs a verified temporary copy and removes it after the app closes. Choose GitHub or windowsacolyte.de as the starter source. Profiles, backups and logs are retained."/>
        </StackPanel>
    </Border>

    <Border Grid.Row="1" x:Name="OptionsBorder"
            BorderThickness="1.5" CornerRadius="10" Padding="18,16" Margin="0,0,0,12">
        <StackPanel>
            <TextBlock Text="SHORTCUTS TO CREATE" Foreground="{DynamicResource DynSectionLabel}" FontSize="10"
                       FontWeight="Bold" Margin="0,0,0,10"/>
            <CheckBox x:Name="LocalShortcutCheck" Content="WA Install GitHub"
                      FontSize="13" IsChecked="True" Margin="0,0,0,10"/>
            <CheckBox x:Name="InstallerShortcutCheck" Content="WA Install Website"
                      FontSize="13" IsChecked="False" Margin="0,0,0,12"/>
            <CheckBox x:Name="DomainStartCheck" Content="WA Online GitHub"
                      FontSize="13" IsChecked="False" Margin="0,0,0,10"/>
            <CheckBox x:Name="DomainInstallerCheck" Content="WA Online Website"
                      FontSize="13" IsChecked="False" Margin="0,0,0,12"/>
            <TextBlock x:Name="DesktopPathText" FontSize="12" TextWrapping="Wrap"/>
            <TextBlock x:Name="IconInfoText" FontSize="12" TextWrapping="Wrap" Margin="0,6,0,0"/>
        </StackPanel>
    </Border>

    <Grid Grid.Row="2" Margin="0,0,0,12">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="140"/>
        </Grid.ColumnDefinitions>
        <Button Grid.Column="0" x:Name="CreateBtn" Content="Create Selected Shortcuts"
                Style="{DynamicResource PrimaryButton}" Height="44" FontSize="14" Margin="0,0,8,0"/>
        <Button Grid.Column="1" x:Name="ClearLogBtn" Content="Clear Log"
                Style="{DynamicResource SecondaryButton}" Height="44" FontSize="12"/>
    </Grid>

    <Grid Grid.Row="3">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Text="ACTIVITY LOG" Foreground="{DynamicResource DynSectionLabel}" FontSize="10"
                   FontWeight="Bold" Margin="0,0,0,8"/>
        <Border Grid.Row="1" x:Name="LogBorder"
                BorderThickness="1.5" CornerRadius="10" MinHeight="140">
            <ScrollViewer x:Name="LogScroller" VerticalScrollBarVisibility="Auto">
                <TextBlock x:Name="LogBox"
                           FontFamily="Cascadia Code, Consolas, Courier New"
                           FontSize="12" Padding="16,14" TextWrapping="Wrap"
                           LineHeight="20" Text="Ready. Select shortcuts and click Create."/>
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

    $Global:DSC_infoBorder      = $view.FindName("InfoBorder")
    $Global:DSC_infoText        = $view.FindName("InfoText")
    $Global:DSC_optionsBorder   = $view.FindName("OptionsBorder")
    $Global:DSC_localCheck      = $view.FindName("LocalShortcutCheck")
    $Global:DSC_installerCheck  = $view.FindName("InstallerShortcutCheck")
    $Global:DSC_domainStartCheck = $view.FindName("DomainStartCheck")
    $Global:DSC_domainInstallerCheck = $view.FindName("DomainInstallerCheck")
    $Global:DSC_desktopPathText = $view.FindName("DesktopPathText")
    $Global:DSC_iconInfoText    = $view.FindName("IconInfoText")
    $Global:DSC_createBtn       = $view.FindName("CreateBtn")
    $Global:DSC_clearLogBtn     = $view.FindName("ClearLogBtn")
    $Global:DSC_logBorder       = $view.FindName("LogBorder")
    $Global:DSC_logBox          = $view.FindName("LogBox")
    $Global:DSC_logScroller     = $view.FindName("LogScroller")
    $Global:DSC_initText        = "Ready. Select shortcuts and click Create."

    $Global:DSC_infoBorder.Background      = $Global:PTS_Brush["Surface"]
    $Global:DSC_infoBorder.BorderBrush     = $Global:PTS_Brush["Border"]
    $Global:DSC_infoText.Foreground        = $Global:PTS_Brush["TextMid"]
    $Global:DSC_optionsBorder.Background   = $Global:PTS_Brush["Surface"]
    $Global:DSC_optionsBorder.BorderBrush  = $Global:PTS_Brush["Border"]
    $Global:DSC_localCheck.Foreground      = $Global:PTS_Brush["TextDark"]
    $Global:DSC_installerCheck.Foreground  = $Global:PTS_Brush["TextDark"]
    $Global:DSC_domainStartCheck.Foreground = $Global:PTS_Brush["TextDark"]
    $Global:DSC_domainInstallerCheck.Foreground = $Global:PTS_Brush["TextDark"]
    $Global:DSC_desktopPathText.Foreground = $Global:PTS_Brush["TextMuted"]
    $Global:DSC_iconInfoText.Foreground    = $Global:PTS_Brush["TextMuted"]
    $Global:DSC_logBorder.Background       = $Global:PTS_Brush["LogBg"]
    $Global:DSC_logBorder.BorderBrush      = $Global:PTS_Brush["LogBorder"]
    $Global:DSC_logBox.Foreground          = $Global:PTS_Brush["TextMuted"]

    function Global:DSC-AddLog {
        param([string]$Msg, [string]$Type = "INFO")
        $ts  = Get-Date -Format "HH:mm:ss"
        $tag = switch ($Type) { "OK"{"[OK]  "} "FAIL"{"[FAIL]"} "WARN"{"[WARN]"} default{"[INFO]"} }
        $entry = "[$ts]  $tag  $Msg`n"
        if ($Global:DSC_logBox.Text -eq $Global:DSC_initText) { $Global:DSC_logBox.Text = $entry }
        else { $Global:DSC_logBox.Text += $entry }
        $Global:DSC_logScroller.ScrollToEnd()
    }

    function Global:DSC-GetDesktopPath {
        $desktop = [Environment]::GetFolderPath("DesktopDirectory")
        if ([string]::IsNullOrWhiteSpace($desktop)) {
            $desktop = Join-Path $env:USERPROFILE "Desktop"
        }
        return $desktop
    }

    function Global:DSC-GetShortcutHostPath {
        $hostPath = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
        if (-not (Test-Path -LiteralPath $hostPath)) {
            throw "Stable Windows PowerShell host was not found: $hostPath"
        }
        return $hostPath
    }

    function Global:DSC-EnsurePowerShell7Bootstrap {
        param([Parameter(Mandatory)][string]$InstallPath)

        if (-not (Test-Path -LiteralPath $InstallPath)) {
            New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        }

        $bootstrapPath = Join-Path $InstallPath "Start-WindowsAcolyte.ps1"
        $sourcePath = Join-Path $Global:PTS_RootPath 'Start-WindowsAcolyte.ps1'
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
            throw "Update-aware starter is missing: $sourcePath. Update WindowsAcolyte first."
        }
        if ([IO.Path]::GetFullPath($sourcePath) -ine [IO.Path]::GetFullPath($bootstrapPath)) {
            Copy-Item -LiteralPath $sourcePath -Destination $bootstrapPath -Force
        }
        return $bootstrapPath
    }

    function Global:DSC-GetIconLocation {
        $candidates = @()
        if (-not [string]::IsNullOrWhiteSpace($Global:PTS_RootPath) -and [IO.Path]::GetFileName($Global:PTS_RootPath) -notmatch '^WindowsAcolyte-Online-[0-9a-f]{32}$') {
            $candidates += (Join-Path $Global:PTS_RootPath "logo\Windows_Acolyte_Shortcut_Icon_v6.ico")
$candidates += (Join-Path $Global:PTS_RootPath "logo\Windows_Acolyte_Shortcut_Icon_v5.ico")
            $candidates += (Join-Path $Global:PTS_RootPath "logo\Windows_Acolyte_Shortcut_Icon_v4.ico")
            $candidates += (Join-Path $Global:PTS_RootPath "logo\Windows_Acolyte_Shortcut_Icon_v3.ico")
            $candidates += (Join-Path $Global:PTS_RootPath "logo\Windows_Acolyte_Shortcut_Icon_v2.ico")
            $candidates += (Join-Path $Global:PTS_RootPath "logo\Windows_Acolyte_Shortcut_Icon.ico")
            $candidates += (Join-Path $Global:PTS_RootPath "logo\Windows_Acolyte_Icon.ico")
        }
        $candidates += (Join-Path $env:LOCALAPPDATA "WindowsAcolyte\logo\Windows_Acolyte_Shortcut_Icon_v6.ico")
$candidates += (Join-Path $env:LOCALAPPDATA "WindowsAcolyte\logo\Windows_Acolyte_Shortcut_Icon_v5.ico")
        $candidates += (Join-Path $env:LOCALAPPDATA "WindowsAcolyte\logo\Windows_Acolyte_Shortcut_Icon_v4.ico")
        $candidates += (Join-Path $env:LOCALAPPDATA "WindowsAcolyte\logo\Windows_Acolyte_Shortcut_Icon_v3.ico")
        $candidates += (Join-Path $env:LOCALAPPDATA "WindowsAcolyte\logo\Windows_Acolyte_Shortcut_Icon_v2.ico")
        $candidates += (Join-Path $env:LOCALAPPDATA "WindowsAcolyte\logo\Windows_Acolyte_Shortcut_Icon.ico")
        $candidates += (Join-Path $env:LOCALAPPDATA "WindowsAcolyte\logo\Windows_Acolyte_Icon.ico")

        foreach ($candidate in $candidates | Select-Object -Unique) {
            if (Test-Path -LiteralPath $candidate) {
                return ("{0},0" -f $candidate)
            }
        }

        $fallback = Join-Path $env:SystemRoot "System32\shell32.dll"
        return ("{0},13" -f $fallback)
    }

    function Global:DSC-NewShortcut {
        param(
            [Parameter(Mandatory)][string]$Name,
            [Parameter(Mandatory)][string]$TargetPath,
            [Parameter(Mandatory)][string]$Arguments,
            [Parameter(Mandatory)][string]$WorkingDirectory,
            [Parameter(Mandatory)][string]$Description,
            [Parameter(Mandatory)][string]$IconLocation
        )

        $desktop = DSC-GetDesktopPath
        if (-not (Test-Path -LiteralPath $desktop)) {
            New-Item -ItemType Directory -Path $desktop -Force | Out-Null
        }

        $shortcutPath = Join-Path $desktop ("{0}.lnk" -f $Name)
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $TargetPath
        $shortcut.Arguments = $Arguments
        $shortcut.WorkingDirectory = $WorkingDirectory
        $shortcut.Description = $Description
        $shortcut.IconLocation = $IconLocation
        $shortcut.Save()

        if (-not (Test-Path -LiteralPath $shortcutPath)) {
            throw "Shortcut file was not created: $shortcutPath"
        }

        return $shortcutPath
    }

    function Global:DSC-CreateSelectedShortcuts {
        $Global:DSC_createBtn.IsEnabled = $false
        try {
            $createLocal = [bool]$Global:DSC_localCheck.IsChecked
            $createInstaller = [bool]$Global:DSC_installerCheck.IsChecked
            $createDomainStart = [bool]$Global:DSC_domainStartCheck.IsChecked
            $createDomainInstaller = [bool]$Global:DSC_domainInstallerCheck.IsChecked

            if (-not ($createLocal -or $createInstaller -or $createDomainStart -or $createDomainInstaller)) {
                DSC-AddLog "No shortcut selected." "WARN"
                return
            }

            $desktop = DSC-GetDesktopPath
            $shortcutHostPath = DSC-GetShortcutHostPath
            $iconLocation = DSC-GetIconLocation
            $github = 'https://raw.githubusercontent.com/ReAlNoMo/WindowsAcolyte/main/Start-WindowsAcolyte.ps1'
            $domain = 'https://windowsacolyte.de'
            $choices = @(
                @{Selected=$createLocal; Name='WA Install GitHub'; Uri=$github; Online=$false}
                @{Selected=$createInstaller; Name='WA Install Website'; Uri=$domain; Online=$false}
                @{Selected=$createDomainStart; Name='WA Online GitHub'; Uri=$github; Online=$true}
                @{Selected=$createDomainInstaller; Name='WA Online Website'; Uri=$domain; Online=$true}
            )
            foreach ($choice in $choices | Where-Object Selected) {
                $command = if ($choice.Online) {
                    '& ([scriptblock]::Create((irm ' + $choice.Uri + '))) -OnlineRun'
                } else {
                    'irm ' + $choice.Uri + ' | iex'
                }
                $arguments = '-NoLogo -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -Command "' + $command + '"'
                $description = if ($choice.Online) { 'Run a verified temporary WindowsAcolyte session.' } else { 'Install or update WindowsAcolyte locally and launch it.' }
                $path = DSC-NewShortcut -Name $choice.Name -TargetPath $shortcutHostPath -Arguments $arguments `
                    -WorkingDirectory $desktop -Description $description -IconLocation $iconLocation
                DSC-AddLog "Created: $path" 'OK'
            }
        } catch {
            DSC-AddLog $_.Exception.Message "FAIL"
        } finally {
            $Global:DSC_createBtn.IsEnabled = $true
        }
    }

    $desktopPath = DSC-GetDesktopPath
    $iconLocation = DSC-GetIconLocation
    $Global:DSC_desktopPathText.Text = "Desktop target: $desktopPath"
    $Global:DSC_iconInfoText.Text = "Icon: $iconLocation"

    if ($iconLocation -like "*,13") {
        DSC-AddLog "WindowsAcolyte icon was not found. Falling back to Windows shell32.dll icon." "WARN"
    }

    $Global:DSC_createBtn.Add_Click({ DSC-CreateSelectedShortcuts })
    $Global:DSC_clearLogBtn.Add_Click({
        $Global:DSC_logBox.Text = $Global:DSC_initText
    })

    return $view
}
