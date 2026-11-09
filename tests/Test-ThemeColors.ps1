# Run with pwsh -NoProfile -STA -File tests/Test-ThemeColors.ps1.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework
$root = Split-Path $PSScriptRoot -Parent
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $root 'WindowsAcolyte.ps1'), [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors.Message -join '; ') }
foreach ($name in @('PTS_Theme', 'PTS_ThemeDark')) {
    $assignment = $ast.Find({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq ('$Global:' + $name)}, $true)
    . ([scriptblock]::Create($assignment.Extent.Text))
}
foreach ($name in @('New-PTSBrush', 'Apply-PTSTheme', 'Update-PTSStyles')) {
    $definition = $ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq "Global:$name"}, $true)
    . ([scriptblock]::Create($definition.Extent.Text))
}
function Global:Build-PTSSidebar { }
function Luminance($hex) {
    $color = [Windows.Media.ColorConverter]::ConvertFromString($hex)
    $channels = @($color.R, $color.G, $color.B) | ForEach-Object {
        $v = $_ / 255.0
        if ($v -le 0.04045) { $v / 12.92 } else { [math]::Pow(($v + 0.055) / 1.055, 2.4) }
    }
    return 0.2126*$channels[0] + 0.7152*$channels[1] + 0.0722*$channels[2]
}
foreach ($palette in @($Global:PTS_Theme, $Global:PTS_ThemeDark)) {
    foreach ($pair in @(@('PrimaryText','Primary'), @('PrimaryText','PrimaryHover'), @('TextDark','Surface'), @('TextMid','Surface'), @('TextMuted','LogBg'), @('SectionLabel','Surface'), @('Success','Surface'), @('Danger','Surface'), @('Warning','Surface'), @('TextDark','AccentSoft'), @('AccentText','SidebarBadgeBgActive'))) {
        $a = Luminance $palette[$pair[0]]; $b = Luminance $palette[$pair[1]]
        $ratio = ([math]::Max($a,$b)+0.05)/([math]::Min($a,$b)+0.05)
        if ($ratio -lt 4.5) { throw "Insufficient contrast: $($pair -join '/') = $ratio" }
    }
}
'PASS: Theme text and status color pairs meet 4.5:1 contrast'
$assignment = $ast.Find({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -match '\$xaml$'}, $true)
. ([scriptblock]::Create($assignment.Extent.Text))
$Global:PTS_Window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($xaml))
$Global:PTS_Brush = @{}
foreach ($key in $Global:PTS_Theme.Keys) { $Global:PTS_Brush[$key] = New-PTSBrush $Global:PTS_Theme[$key] }
$Global:PTS_UI = @{}
foreach ($name in @('SidebarGrid','ContentScroller','HeaderEyebrow','HeaderTitle','HeaderSubtitle','HeaderBorder','FooterBorder','FooterStatus','FooterLeft','FooterMid','SidebarDivTop','SidebarDivBot','DarkModeLabel','LogoBorder','ContentHost')) {
    $Global:PTS_UI[$name] = $Global:PTS_Window.FindName($name)
    if (-not $Global:PTS_UI[$name]) { throw "Missing UI element: $name" }
}
$panel = [Windows.Controls.StackPanel]::new()
$label = [Windows.Controls.TextBlock]::new(); $label.Foreground = $Global:PTS_Brush.TextDark
$check = [Windows.Controls.CheckBox]::new(); $check.IsChecked = $true
$panel.Children.Add($label) | Out-Null; $panel.Children.Add($check) | Out-Null
$Global:PTS_UI.ContentHost.Content = $panel
$brush = $label.Foreground
foreach ($dark in @($true, $false)) {
    Apply-PTSTheme $dark
    $palette = if ($dark) { $Global:PTS_ThemeDark } else { $Global:PTS_Theme }
    if (-not [object]::ReferenceEquals($brush, $Global:PTS_Brush.TextDark) -or $label.Foreground.Color -ne [Windows.Media.ColorConverter]::ConvertFromString($palette.TextDark)) { throw "Existing view did not update: dark=$dark" }
    if (-not [object]::ReferenceEquals($panel, $Global:PTS_UI.ContentHost.Content) -or -not $check.IsChecked) { throw "Theme change reset open view: dark=$dark" }
    if ($Global:PTS_Window.Resources.DynPrimaryText.Color -ne [Windows.Media.ColorConverter]::ConvertFromString($palette.PrimaryText)) { throw "Primary text resource incorrect: dark=$dark" }
}
'PASS: Existing WPF view and selection survive both theme changes and shared colors update'
