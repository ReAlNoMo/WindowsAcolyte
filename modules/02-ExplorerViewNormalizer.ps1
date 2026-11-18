# Current-user Explorer view state only. No HKLM writes, imports, or shell restarts.
function Global:Get-EVNPaths {
    $shell = 'Software\Classes\Local Settings\Software\Microsoft\Windows\Shell'
    $explorer = 'Software\Microsoft\Windows\CurrentVersion\Explorer'
    [pscustomobject]@{
        MachineTypes = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes'
        UserTypes = "HKCU:\$explorer\FolderTypes"
        BackupDirectory = Join-Path $env:LOCALAPPDATA 'WindowsAcolyte\ExplorerViewBackups'
        Scopes = [ordered]@{
            Bags = "$shell\Bags"; BagMRU = "$shell\BagMRU"
            LegacyBags = 'Software\Microsoft\Windows\Shell\Bags'
            LegacyBagMRU = 'Software\Microsoft\Windows\Shell\BagMRU'
            DesktopStream = "$explorer\Streams\Desktop"
            DefaultStreams = "$explorer\Streams\Defaults"
            DialogSize = "$explorer\ComDlg32\CIDSizeMRU"
            FirstFolder = "$explorer\ComDlg32\FirstFolder"
            LastVisited = "$explorer\ComDlg32\LastVisitedPidlMRU"
            OpenSave = "$explorer\ComDlg32\OpenSavePidlMRU"
            FolderTypes = "$explorer\FolderTypes"
        }
    }
}

function Global:Get-EVNFolderTypes {
    $paths = Get-EVNPaths
    $types = @(Get-ChildItem -LiteralPath $paths.MachineTypes -ErrorAction Stop | Where-Object {
        Test-Path -LiteralPath (Join-Path $_.PSPath 'TopViews')
    })
    if ($types.Count -eq 0) { throw 'No Windows folder view templates found. No changes made.' }
    $types
}

function Global:Get-EVNViewPaths {
    $paths = Get-EVNPaths
    foreach ($scope in @('Bags', 'LegacyBags')) {
        $base = "HKCU:\$($paths.Scopes[$scope])"
        if (Test-Path -LiteralPath $base) {
            Get-ChildItem -LiteralPath $base -Recurse -ErrorAction Stop | Where-Object {
                $_.Name -match '\\(?:Shell|ComDlg|ComDlgLegacy)(?:\\\{[0-9a-f-]{36}\})?$'
            } | Select-Object -ExpandProperty PSPath
        }
    }
}

function Global:Get-EVNTreeSnapshot {
    param([Microsoft.Win32.RegistryKey]$Root, [string]$SubKey)
    $key = $Root.OpenSubKey($SubKey)
    if ($null -eq $key) { return }
    try {
        $values = @(foreach ($name in $key.GetValueNames()) {
            [pscustomobject]@{ Name=$name; Kind=$key.GetValueKind($name).ToString()
                Data=$key.GetValue($name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames) }
        })
        [pscustomobject]@{ Path=$SubKey; Values=$values }
        foreach ($child in $key.GetSubKeyNames()) { Get-EVNTreeSnapshot -Root $Root -SubKey "$SubKey\$child" }
    } finally { $key.Dispose() }
}

function Global:Save-EVNViewBackup {
    $paths = Get-EVNPaths
    $root = [Microsoft.Win32.Registry]::CurrentUser
    $scopes = @(foreach ($id in $paths.Scopes.Keys) {
        $subKey = $paths.Scopes[$id]
        $nodes = @(Get-EVNTreeSnapshot -Root $root -SubKey $subKey)
        foreach ($node in $nodes) { $node.Path = $node.Path.Substring($subKey.Length).TrimStart('\') }
        [pscustomobject]@{ Id=$id; Nodes=$nodes }
    })
    $backup = [pscustomobject]@{ Version=1; CreatedUtc=[DateTime]::UtcNow.ToString('o'); Scopes=$scopes }
    [IO.Directory]::CreateDirectory($paths.BackupDirectory) | Out-Null
    $file = Join-Path $paths.BackupDirectory ("views-{0}-{1}.json" -f [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmssfffffff'), [guid]::NewGuid().ToString('N'))
    # CreateNew: never overwrite an earlier snapshot. No executable .reg import is used.
    $stream = [IO.File]::Open($file, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes(($backup | ConvertTo-Json -Depth 12))
        $stream.Write($bytes, 0, $bytes.Length)
    } finally { $stream.Dispose() }
    $file
}

function Global:Get-EVNLatestBackup {
    $directory = (Get-EVNPaths).BackupDirectory
    if (Test-Path -LiteralPath $directory) {
        Get-ChildItem -LiteralPath $directory -Filter 'views-*.json' -File -ErrorAction Stop |
            Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty FullName
    }
}

function Global:Convert-EVNBackupValue {
    param($Value)
    switch -Exact ($Value.Kind) {
        'String'       { return [string]$Value.Data }
        'ExpandString' { return [string]$Value.Data }
        'MultiString'  { return ,([string[]]$Value.Data) }
        'Binary'       { return ,([byte[]]$Value.Data) }
        'None'         { return ,([byte[]]$Value.Data) }
        'DWord'        { return [int]$Value.Data }
        'QWord'        { return [long]$Value.Data }
        default       { throw 'Unsupported registry value type in view backup.' }
    }
}

function Global:Restore-EVNViewBackup {
    param([Parameter(Mandatory)][string]$File)
    $paths = Get-EVNPaths
    $backup = Get-Content -LiteralPath $File -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    if ($backup.Version -ne 1 -or @($backup.Scopes).Count -ne $paths.Scopes.Count) { throw 'Invalid view backup.' }
    $ids = @{}
    # Validate the ENTIRE snapshot before deleting anything. Scope paths come from code,
    # never from the backup. This cannot import HKLM or arbitrary user registry roots.
    foreach ($scope in $backup.Scopes) {
        if (-not $paths.Scopes.Contains($scope.Id) -or $ids.ContainsKey($scope.Id)) { throw 'Invalid backup scope.' }
        $ids[$scope.Id] = $true
        $nodes = @{}
        foreach ($node in $scope.Nodes) {
            if ($node.Path -isnot [string] -or $node.Path.Contains([char]0) -or
                $node.Path -match '(^\\|\\$|\\\\|(^|\\)\.\.?($|\\))' -or
                @($node.Path.Split('\') | Where-Object Length -gt 255).Count -gt 0 -or $nodes.ContainsKey($node.Path)) {
                throw 'Invalid backup node.'
            }
            $nodes[$node.Path] = $true
            $names = @{}
            foreach ($value in $node.Values) {
                if ($value.Name -isnot [string] -or $value.Name.Contains([char]0) -or $value.Name.Length -gt 16383 -or $names.ContainsKey($value.Name)) { throw 'Invalid backup value.' }
                $names[$value.Name] = $true
                $null = Convert-EVNBackupValue $value
            }
        }
        if (@($scope.Nodes).Count -gt 0 -and -not $nodes.ContainsKey('')) { throw 'Missing backup root.' }
    }
    # A fresh rescue snapshot keeps the pre-restore state recoverable if restore fails.
    $rescue = Save-EVNViewBackup
    $root = [Microsoft.Win32.Registry]::CurrentUser
    foreach ($scope in $backup.Scopes) {
        $subKey = $paths.Scopes[$scope.Id]
        $root.DeleteSubKeyTree($subKey, $false)
        foreach ($node in $scope.Nodes) {
            $target = $subKey
            if ($node.Path -ne '') { $target += '\' + $node.Path }
            $key = $root.CreateSubKey($target)
            try {
                foreach ($value in $node.Values) {
                    $key.SetValue($value.Name, (Convert-EVNBackupValue $value), [Microsoft.Win32.RegistryValueKind]$value.Kind)
                }
            } finally { $key.Dispose() }
        }
    }
    $rescue
}

function Global:Set-EVNNoGrouping {
    $paths = Get-EVNPaths
    $types = @(Get-EVNFolderTypes)
    if (-not (Test-Path -LiteralPath $paths.UserTypes)) { New-Item -Path $paths.UserTypes -Force -ErrorAction Stop | Out-Null }
    # Keep the complete type catalog, including types without editable TopViews.
    foreach ($type in Get-ChildItem -LiteralPath $paths.MachineTypes -ErrorAction Stop) {
        $target = Join-Path $paths.UserTypes $type.PSChildName
        # Merge missing machine defaults without replacing existing user customizations.
        $machine = $type.PSPath
        foreach ($key in @($type) + @(Get-ChildItem -LiteralPath $machine -Recurse -ErrorAction Stop)) {
            $relative = $key.Name.Substring($type.Name.Length).TrimStart('\')
            $destination = $target
            if ($relative) { $destination = Join-Path $target $relative }
            if (-not (Test-Path -LiteralPath $destination)) {
                New-Item -Path $destination -Force -ErrorAction Stop | Out-Null
            }
            $copy = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey((Get-Item -LiteralPath $destination -ErrorAction Stop).Name.Substring(18), $true)
            try {
                $existingNames = $copy.GetValueNames()
                foreach ($name in $key.GetValueNames()) {
                    if ($name -notin $existingNames) {
                        $copy.SetValue($name, $key.GetValue($name, $null, 'DoNotExpandEnvironmentNames'), $key.GetValueKind($name))
                    }
                }
            } finally { $copy.Dispose() }
        }
    }
    foreach ($type in $types) {
        $target = Join-Path $paths.UserTypes $type.PSChildName
        foreach ($view in Get-ChildItem -LiteralPath (Join-Path $target 'TopViews') -ErrorAction Stop) {
            New-ItemProperty -LiteralPath $view.PSPath -Name GroupBy -Value '' -PropertyType String -Force -ErrorAction Stop | Out-Null
            New-ItemProperty -LiteralPath $view.PSPath -Name GroupAscending -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
        }
    }
    foreach ($hostName in @('Shell', 'ComDlg', 'ComDlgLegacy')) {
        $base = "HKCU:\$($paths.Scopes.Bags)\AllFolders\$hostName"
        if (-not (Test-Path -LiteralPath $base)) { New-Item -Path $base -Force -ErrorAction Stop | Out-Null }
        foreach ($type in $types) {
            $target = Join-Path $base $type.PSChildName
            if (-not (Test-Path -LiteralPath $target)) { New-Item -Path $target -Force -ErrorAction Stop | Out-Null }
        }
    }
    foreach ($view in Get-EVNViewPaths) {
        foreach ($value in @(
            @('GroupView', 0, 'DWord'), @('GroupBy', '', 'String'),
            @('GroupByKey:FMTID', '{00000000-0000-0000-0000-000000000000}', 'String'),
            @('GroupByKey:PID', 0, 'DWord'), @('GroupByDirection', 1, 'DWord')
        )) {
            New-ItemProperty -LiteralPath $view -Name $value[0] -Value $value[1] -PropertyType $value[2] -Force -ErrorAction Stop | Out-Null
        }
    }
    # Legacy Apply-to-Folders binary defaults can override FolderTypes.
    $defaults = "HKCU:\$($paths.Scopes.DefaultStreams)"
    if (Test-Path -LiteralPath $defaults) { Remove-Item -LiteralPath $defaults -Recurse -Force -ErrorAction Stop }
}

function Global:Get-EVNGroupingState {
    $paths = Get-EVNPaths
    $missing = 0; $conflicts = 0; $saved = 0
    foreach ($type in Get-EVNFolderTypes) {
        $top = Join-Path $paths.UserTypes ($type.PSChildName + '\TopViews')
        foreach ($machineView in Get-ChildItem -LiteralPath (Join-Path $type.PSPath 'TopViews') -ErrorAction Stop) {
            if (-not (Test-Path -LiteralPath (Join-Path $top $machineView.PSChildName))) { $missing++ }
        }
        if (-not (Test-Path -LiteralPath $top)) { continue }
        foreach ($view in Get-ChildItem -LiteralPath $top -ErrorAction Stop) {
            if (-not ($view.GetValueNames() -contains 'GroupBy') -or $view.GetValueKind('GroupBy') -ne 'String' -or $view.GetValue('GroupBy') -ne '') { $conflicts++ }
        }
    }
    foreach ($view in Get-EVNViewPaths) {
        $saved++
        $p = Get-ItemProperty -LiteralPath $view -ErrorAction Stop
        if (($null -ne $p.GroupView -and $p.GroupView -ne 0) -or
            ($null -ne $p.'GroupByKey:PID' -and $p.'GroupByKey:PID' -ne 0) -or
            ($p.GroupBy -and $p.GroupBy -ne '') -or
            ($p.'GroupByKey:FMTID' -and $p.'GroupByKey:FMTID' -ne '{00000000-0000-0000-0000-000000000000}')) { $conflicts++ }
    }
    $legacy = Test-Path -LiteralPath "HKCU:\$($paths.Scopes.DefaultStreams)"
    [pscustomobject]@{ Configured=($missing -eq 0 -and $conflicts -eq 0 -and -not $legacy)
        MissingTemplates=$missing; Conflicts=$conflicts; SavedViews=$saved; LegacyDefaults=$legacy }
}


# Module: Explorer View Normalizer
# Lets users compose global Explorer defaults via checkbox options.
# Checks current state on load and applies selected settings across all folder templates.

Register-PowerToolsModule `
    -Id          "explorer-details" `
    -Name        "Explorer View Normalizer" `
    -Description "Set Explorer defaults and repair saved grouping for the current user." `
    -Category    "Windows Tweaks" `
    -Show        {

    if ($script:EVN_job) { return $script:EVN_view }

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
            <TextBlock Text="GLOBAL EXPLORER NORMALIZER" Foreground="{DynamicResource DynSectionLabel}" FontSize="10"
                       FontWeight="Bold" Margin="0,0,0,8"/>
            <TextBlock x:Name="InfoText" FontSize="13" TextWrapping="Wrap" LineHeight="20"
                Text="Selected options apply; unchecked options stay unchanged. Disable grouping repairs Windows folder-type defaults and saved Explorer/Open/Save views. Close Explorer windows and file dialogs first. View changes are backed up. Special views and custom app dialogs may differ; Windows upgrades may reset defaults."/>
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
            <TextBlock Grid.Row="0" Text="SETTINGS (SELECT TO ENFORCE)" Foreground="{DynamicResource DynSectionLabel}" FontSize="10"
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
        <TextBlock Text="ACTIVITY LOG" Foreground="{DynamicResource DynSectionLabel}" FontSize="10"
                   FontWeight="Bold" VerticalAlignment="Center"/>
        <Button x:Name="RestoreViewsBtn" Grid.Column="0" Content="Restore View Backup"
                HorizontalAlignment="Center" Style="{DynamicResource SecondaryButton}" Padding="12,6" FontSize="11"/>
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
    $script:EVN_restore      = $view.FindName("RestoreViewsBtn")
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
    $script:EVN_groupingState = $null

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

    $script:EVN_folderTypes = [ordered]@{}
    foreach ($type in Get-EVNFolderTypes) { $script:EVN_folderTypes[$type.PSChildName] = $type.PSChildName }
    $script:EVN_basePath = "HKCU:\$((Get-EVNPaths).Scopes.Bags)\AllFolders\Shell"

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

    $script:EVN_clearPaths = @((Get-EVNPaths).Scopes.GetEnumerator() |
        Where-Object Key -ne 'FolderTypes' | ForEach-Object { "HKCU:\$($_.Value)" })

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

    function Global:EVN-RemoveRegValue {
        param(
            [Parameter(Mandatory)][string]$Path,
            [Parameter(Mandatory)][string]$Name
        )
        if (Test-Path $Path) {
            Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        }
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
                Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction Stop
                EVN-AddLog "Cleared: $p" "INFO"
            }
        }
    }

    function Global:EVN-TestClearSavedViews {
        return $null # One-time action, never a persistent setting.
    }

    function Global:EVN-ApplyDetailsView {
        EVN-EnsureTemplatePaths
        foreach ($path in (EVN-GetTemplatePaths)) {
            EVN-SetRegValue -Path $path -Name "LogicalViewMode" -Value 1 -Kind DWord
            EVN-SetRegValue -Path $path -Name "Mode" -Value 4 -Kind DWord
        }
    }

    function Global:EVN-RevertDetailsView {
        foreach ($path in (EVN-GetTemplatePaths)) {
            EVN-RemoveRegValue -Path $path -Name "LogicalViewMode"
            EVN-RemoveRegValue -Path $path -Name "Mode"
        }
    }

    function Global:EVN-TestDetailsView {
        return (EVN-TestAllTemplates {
            param($p)
            ($p.LogicalViewMode -eq 1 -and $p.Mode -eq 4)
        })
    }

    function Global:EVN-ApplyDisableGrouping {
        Set-EVNNoGrouping
        $state = Get-EVNGroupingState
        if (-not $state.Configured) { throw "Grouping verification failed: $($state.Conflicts) conflicts, $($state.MissingTemplates) missing templates." }
        EVN-AddLog "Grouping defaults verified; $($state.SavedViews) saved Explorer/dialog view keys checked. Reopen file dialogs after applying." "OK"
    }

    function Global:EVN-TestDisableGrouping {
        $script:EVN_groupingState = Get-EVNGroupingState
        return $script:EVN_groupingState.Configured
    }

    function Global:EVN-ApplySortNameAsc {
        EVN-EnsureTemplatePaths
        foreach ($path in (EVN-GetTemplatePaths)) {
            EVN-SetRegValue -Path $path -Name "Sort" -Value $script:EVN_sortByNameAscending -Kind Binary
        }
    }

    function Global:EVN-RevertSortNameAsc {
        foreach ($path in (EVN-GetTemplatePaths)) {
            EVN-RemoveRegValue -Path $path -Name "Sort"
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

    function Global:EVN-RevertColumnsDefault {
        foreach ($path in (EVN-GetTemplatePaths)) {
            EVN-RemoveRegValue -Path $path -Name "ColInfo"
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

    function Global:EVN-RevertFolderTypeNotSpecified {
        foreach ($path in (EVN-GetTemplatePaths)) {
            EVN-RemoveRegValue -Path $path -Name "FolderType"
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

    function Global:EVN-RevertShowHidden {
        EVN-SetRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 2 -Kind DWord
    }

    function Global:EVN-TestShowHidden {
        $p = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue
        return ($null -ne $p -and $p.Hidden -eq 1)
    }

    function Global:EVN-ApplyShowExtensions {
        EVN-SetRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Kind DWord
    }

    function Global:EVN-RevertShowExtensions {
        EVN-SetRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 1 -Kind DWord
    }

    function Global:EVN-TestShowExtensions {
        $p = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue
        return ($null -ne $p -and $p.HideFileExt -eq 0)
    }

    function Global:EVN-ApplyHideProtectedOS {
        EVN-SetRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSuperHidden" -Value 0 -Kind DWord
    }

    function Global:EVN-RevertHideProtectedOS {
        EVN-SetRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSuperHidden" -Value 1 -Kind DWord
    }

    function Global:EVN-TestHideProtectedOS {
        $p = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue
        return ($null -ne $p -and $p.ShowSuperHidden -eq 0)
    }

    function Global:EVN-ApplyDisableCompactMode {
        EVN-SetRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "UseCompactMode" -Value 0 -Kind DWord
    }

    function Global:EVN-RevertDisableCompactMode {
        EVN-SetRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "UseCompactMode" -Value 1 -Kind DWord
    }

    function Global:EVN-TestDisableCompactMode {
        $p = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue
        return ($null -ne $p -and $p.UseCompactMode -eq 0)
    }

    function Global:EVN-ApplyDisableAutoGrouping {
        EVN-SetRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "UseAutoGrouping" -Value 0 -Kind DWord
    }

    function Global:EVN-RevertDisableAutoGrouping {
        EVN-SetRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "UseAutoGrouping" -Value 1 -Kind DWord
    }

    function Global:EVN-TestDisableAutoGrouping {
        $p = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue
        return ($null -ne $p -and $p.UseAutoGrouping -eq 0)
    }

    function Global:EVN-ApplyEnableDetailsPane {
        EVN-SetRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Modules\GlobalSettings\DetailsContainer" -Name "DetailsContainer" -Value $script:EVN_detailsPaneState -Kind Binary
        EVN-SetRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Modules\GlobalSettings\Sizer" -Name "DetailsContainerSizer" -Value $script:EVN_detailsPaneSizer -Kind Binary
    }

    function Global:EVN-RevertEnableDetailsPane {
        EVN-RemoveRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Modules\GlobalSettings\DetailsContainer" -Name "DetailsContainer"
        EVN-RemoveRegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Modules\GlobalSettings\Sizer" -Name "DetailsContainerSizer"
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

    function Global:EVN-RevertEnablePreviewPane {
        $policyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
        if (-not (Test-Path $policyPath)) { New-Item -Path $policyPath -Force | Out-Null }
        EVN-SetRegValue -Path $policyPath -Name "NoReadingPane" -Value 1 -Kind DWord
        EVN-SetRegValue -Path $policyPath -Name "NoPreviewPane" -Value 1 -Kind DWord
    }

    function Global:EVN-ApplySmallDesktopIcons {
        $desktopBagPath = "HKCU:\Software\Microsoft\Windows\Shell\Bags\1\Desktop"
        EVN-SetRegValue -Path $desktopBagPath -Name "IconSize" -Value 32 -Kind DWord
    }

    function Global:EVN-RevertSmallDesktopIcons {
        $desktopBagPath = "HKCU:\Software\Microsoft\Windows\Shell\Bags\1\Desktop"
        EVN-SetRegValue -Path $desktopBagPath -Name "IconSize" -Value 48 -Kind DWord
    }

    function Global:EVN-TestSmallDesktopIcons {
        $desktopBagPath = "HKCU:\Software\Microsoft\Windows\Shell\Bags\1\Desktop"
        $p = Get-ItemProperty -Path $desktopBagPath -ErrorAction SilentlyContinue
        return ($null -ne $p -and $p.IconSize -eq 32)
    }

    function Global:EVN-TestEnablePreviewPane {
        $p = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ErrorAction SilentlyContinue
        if ($null -eq $p) { return $true }
        if ($p.PSObject.Properties.Name -contains "NoReadingPane" -and $p.NoReadingPane -eq 1) { return $false }
        if ($p.PSObject.Properties.Name -contains "NoPreviewPane" -and $p.NoPreviewPane -eq 1) { return $false }
        return $true
    }

    function Global:EVN-RestartExplorer {
        # Share the desktop-shell, session and owner checks with Shortcut Arrow Visibility.
        $shellId = SAV-RestartExplorer
        EVN-AddLog "Explorer restarted in the current session (PID $shellId)." "OK"
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
            Revert = $null
            DefaultChecked = $true
        }
        details_view = [ordered]@{
            Label = "Force Details View (LogicalViewMode=1, Mode=4) for all folder templates"
            Test  = { EVN-TestDetailsView }
            Apply = { EVN-ApplyDetailsView }
            Revert = { EVN-RevertDetailsView }
            DefaultChecked = $true
        }
        disable_grouping = [ordered]@{
            Label = "Disable grouping (folder defaults + saved Explorer/Open/Save views)"
            Test  = { EVN-TestDisableGrouping }
            Apply = { EVN-ApplyDisableGrouping }
            Revert = $null
            DefaultChecked = $true
        }
        sort_name_asc = [ordered]@{
            Label = "Sort by Name (Ascending) globally"
            Test  = { EVN-TestSortNameAsc }
            Apply = { EVN-ApplySortNameAsc }
            Revert = { EVN-RevertSortNameAsc }
            DefaultChecked = $true
        }
        columns_default = [ordered]@{
            Label = "Set default columns: Name, Date modified, Type, Size"
            Test  = { EVN-TestColumnsDefault }
            Apply = { EVN-ApplyColumnsDefault }
            Revert = { EVN-RevertColumnsDefault }
            DefaultChecked = $true
        }
        foldertype_notspecified = [ordered]@{
            Label = "Disable Folder Type Discovery (FolderType=NotSpecified)"
            Test  = { EVN-TestFolderTypeNotSpecified }
            Apply = { EVN-ApplyFolderTypeNotSpecified }
            Revert = { EVN-RevertFolderTypeNotSpecified }
            DefaultChecked = $true
        }
        show_hidden = [ordered]@{
            Label = "Show hidden files"
            Test  = { EVN-TestShowHidden }
            Apply = { EVN-ApplyShowHidden }
            Revert = { EVN-RevertShowHidden }
            DefaultChecked = $true
        }
        show_extensions = [ordered]@{
            Label = "Show file extensions"
            Test  = { EVN-TestShowExtensions }
            Apply = { EVN-ApplyShowExtensions }
            Revert = { EVN-RevertShowExtensions }
            DefaultChecked = $true
        }
        hide_protected_os = [ordered]@{
            Label = "Keep protected operating system files hidden"
            Test  = { EVN-TestHideProtectedOS }
            Apply = { EVN-ApplyHideProtectedOS }
            Revert = { EVN-RevertHideProtectedOS }
            DefaultChecked = $true
        }
        disable_compact = [ordered]@{
            Label = "Disable Compact View"
            Test  = { EVN-TestDisableCompactMode }
            Apply = { EVN-ApplyDisableCompactMode }
            Revert = { EVN-RevertDisableCompactMode }
            DefaultChecked = $true
        }
        disable_auto_grouping = [ordered]@{
            Label = "Legacy UseAutoGrouping=0 hint (not a grouping lock)"
            Test  = { EVN-TestDisableAutoGrouping }
            Apply = { EVN-ApplyDisableAutoGrouping }
            Revert = { EVN-RevertDisableAutoGrouping }
            DefaultChecked = $true
        }
        enable_details_pane = [ordered]@{
            Label = "Enable Details Pane"
            Test  = { EVN-TestEnableDetailsPane }
            Apply = { EVN-ApplyEnableDetailsPane }
            Revert = { EVN-RevertEnableDetailsPane }
            DefaultChecked = $true
        }
        enable_preview_pane = [ordered]@{
            Label = "Allow Preview Pane (remove restrictive Explorer policies)"
            Test  = { EVN-TestEnablePreviewPane }
            Apply = { EVN-ApplyEnablePreviewPane }
            Revert = { EVN-RevertEnablePreviewPane }
            DefaultChecked = $true
        }
        small_desktop_icons = [ordered]@{
            Label = "Use small desktop icons (IconSize=32, desktop only)"
            Test  = { EVN-TestSmallDesktopIcons }
            Apply = { EVN-ApplySmallDesktopIcons }
            Revert = { EVN-RevertSmallDesktopIcons }
            DefaultChecked = $true
        }
        restart_explorer = [ordered]@{
            Label = "Restart Explorer automatically after apply"
            Test  = { EVN-TestRestartExplorer }
            Apply = { EVN-RestartExplorer }
            Revert = $null
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
        $hdr.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, 'DynTextDark')
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

        $script:EVN_statusText.Text = "Checked: $setCount already set, $unsetCount not set. Unchecked options stay unchanged."
        if ($script:EVN_groupingState) {
            $g = $script:EVN_groupingState
            $script:EVN_statusText.Text += " Grouping: $($g.Conflicts) stored conflicts, $($g.MissingTemplates) missing templates; legacy defaults: $($g.LegacyDefaults). Registry readback is not a live window check."
        }
        $script:EVN_restore.IsEnabled = [bool](Get-EVNLatestBackup)
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

    function Global:EVN-StartWork {
        param([string[]]$Selected = @(), [string]$RestoreFile)
        if ($script:EVN_job) { return }
        $definitions = @(Get-Command -CommandType Function | Where-Object {
            $_.Name -match '^(EVN-|(?:Get|Set|Save|Restore|Convert)-EVN)'
        } | ForEach-Object { "function Global:$($_.Name) { $($_.Definition) }" })
        $state = @{}
        foreach ($name in @('folderTypes','basePath','sortByNameAscending','detailsColumns','detailsPaneState','detailsPaneSizer','clearPaths')) {
            $state["EVN_$name"] = Get-Variable -Name "EVN_$name" -Scope Script -ValueOnly
        }
        $actions = @(foreach ($id in $script:EVN_options.Keys) {
            if ($id -in $Selected -and $id -ne 'restart_explorer') {
                [pscustomobject]@{ Label=$script:EVN_options[$id].Label; Code=$script:EVN_options[$id].Apply.ToString() }
            }
        })
        $queue = [Collections.Concurrent.ConcurrentQueue[object]]::new()
        $worker = [PowerShell]::Create()
        $null = $worker.AddScript({
            param($Definitions, $State, $Actions, $Queue, $RestoreFile)
            $ErrorActionPreference = 'Stop'
            foreach ($definition in $Definitions) { . ([scriptblock]::Create($definition)) }
            foreach ($name in $State.Keys) { Set-Variable -Name $name -Value $State[$name] -Scope Script }
            $script:EVN_queue = $Queue
            function Global:EVN-AddLog {
                param([string]$Msg, [string]$Type='INFO')
                $script:EVN_queue.Enqueue([pscustomobject]@{Message=$Msg;Type=$Type})
            }
            if ($RestoreFile) {
                $rescue = Restore-EVNViewBackup -File $RestoreFile
                EVN-AddLog "View backup restored. Pre-restore rescue backup: $rescue" 'OK'
            } elseif ($Actions.Count -gt 0) {
                $backup = Save-EVNViewBackup
                EVN-AddLog "Folder-view backup: $backup" 'OK'
                foreach ($action in $Actions) {
                    & ([scriptblock]::Create($action.Code))
                    EVN-AddLog "Applied: $($action.Label)" 'OK'
                }
            }
        }).AddArgument($definitions).AddArgument($state).AddArgument($actions).AddArgument($queue).AddArgument($RestoreFile)
        try {
            $script:EVN_job = @{Worker=$worker; Queue=$queue; Selected=$Selected; Handle=$worker.BeginInvoke()}
            foreach ($control in @($script:EVN_apply,$script:EVN_restore,$script:EVN_recheck,$script:EVN_selAll,$script:EVN_selNone,$script:EVN_optionsPanel)) { $control.IsEnabled=$false }
            Register-PTSActiveOperation -ModuleId 'explorer-details' -ModuleName 'Explorer View Normalizer' -Description 'Saving/restoring Explorer view settings. Please wait until completion.'
            $script:EVN_workTimer = [Windows.Threading.DispatcherTimer]::new()
            $script:EVN_workTimer.Interval = [TimeSpan]::FromMilliseconds(150)
            $script:EVN_workTimer.Add_Tick({
                $job = $script:EVN_job
                $entry = $null
                while ($job.Queue.TryDequeue([ref]$entry)) { EVN-AddLog $entry.Message $entry.Type }
                if (-not $job.Handle.IsCompleted) { return }
                $script:EVN_workTimer.Stop()
                try {
                    $null = $job.Worker.EndInvoke($job.Handle)
                    while ($job.Queue.TryDequeue([ref]$entry)) { EVN-AddLog $entry.Message $entry.Type }
                    if ($job.Worker.Streams.Error.Count) { throw ($job.Worker.Streams.Error -join '; ') }
                    if ($job.Selected -contains 'restart_explorer') { EVN-RestartExplorer }
                    EVN-AddLog 'Finished. Reopen applications with file dialogs; running apps may retain older views.' 'OK'
                } catch { EVN-AddLog "Operation failed; previous steps may have applied. View backups are available. $_" 'FAIL' }
                finally {
                    $job.Worker.Dispose()
                    $script:EVN_job = $null
                    Unregister-PTSActiveOperation -ModuleId 'explorer-details'
                    foreach ($control in @($script:EVN_apply,$script:EVN_restore,$script:EVN_recheck,$script:EVN_selAll,$script:EVN_selNone,$script:EVN_optionsPanel)) { $control.IsEnabled=$true }
                    try { EVN-RecheckOptionStates } catch { EVN-AddLog "State check failed: $_" 'FAIL' }
                }
            })
            $script:EVN_workTimer.Start()
        } catch {
            if ($script:EVN_job) { $worker.Stop(); $script:EVN_job=$null }
            $worker.Dispose()
            Unregister-PTSActiveOperation -ModuleId 'explorer-details'
            foreach ($control in @($script:EVN_apply,$script:EVN_restore,$script:EVN_recheck,$script:EVN_selAll,$script:EVN_selNone,$script:EVN_optionsPanel)) { $control.IsEnabled=$true }
            EVN-AddLog "Could not start operation: $_" 'FAIL'
        }
    }

    $script:EVN_apply.Add_Click({
        $selected = @(EVN-GetSelectedOptions)
        if ($selected.Count -eq 0) { EVN-AddLog 'No settings selected. Nothing changed.'; return }
        if ($selected -contains 'clear_saved_views' -or $selected -contains 'disable_grouping') {
            $answer = [Windows.MessageBox]::Show('Close Explorer windows and all Open/Save dialogs first. A folder-view backup will be saved. Disable grouping clears legacy Apply-to-Folders defaults but keeps saved columns. Reset saved views also removes saved layouts and dialog history. Continue?', 'Explorer View Normalizer', 'YesNo', 'Warning')
            if ($answer -ne 'Yes') { return }
        }
        EVN-StartWork -Selected $selected
    })

    $script:EVN_restore.Add_Click({
        $file = Get-EVNLatestBackup
        if (-not $file) { EVN-AddLog 'No view backup available.' 'WARN'; return }
        $picker = [Microsoft.Win32.OpenFileDialog]::new()
        $picker.Title = 'Select Explorer view backup'
        $picker.Filter = 'Explorer view backup (*.json)|*.json'
        $picker.InitialDirectory = (Get-EVNPaths).BackupDirectory
        $picker.FileName = $file
        if ($picker.ShowDialog() -ne $true) { return }
        $file = $picker.FileName
        $answer = [Windows.MessageBox]::Show("Restore folder-view backup?`n$file`n`nThis replaces saved folder views, templates and dialog history, including newer customizations. Other Explorer options are not restored. Close Explorer and file dialogs first. Current views are backed up before restore.", 'Restore Explorer Views', 'YesNo', 'Warning')
        if ($answer -eq 'Yes') { EVN-StartWork -RestoreFile $file }
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

    $script:EVN_view = $view
    return $view
}
