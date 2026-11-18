# Run with pwsh -NoProfile -STA -File tests/Test-ThemeColors.ps1.
param([string]$RenderDirectory, [switch]$Maximized)
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
foreach ($name in @('SidebarGrid','ContentScroller','HeaderEyebrow','HeaderTitle','HeaderSubtitle','HeaderBorder','FooterBorder','FooterStatus','FooterLeft','FooterMid','SidebarDivTop','SidebarDivBot','DarkModeLabel','DarkModeToggle','LogoBorder','ContentHost')) {
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

# Exercise the actual startup assignments and one-shot activation handler.
$nativeActivation = $ast.EndBlock.Statements | Where-Object { $_.Extent.Text -like 'Add-Type -TypeDefinition*' }
. ([scriptblock]::Create($nativeActivation.Extent.Text))
foreach ($target in @('$Global:PTS_DarkModeEnabled', '$Global:PTS_UI.DarkModeToggle.IsChecked', '$script:PTS_StartupActivationHandler')) {
    $node = $ast.Find({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq $target}, $true)
    if (-not $node) { throw "Missing startup assignment: $target" }
    . ([scriptblock]::Create($node.Extent.Text))
}
$startupTheme = $ast.EndBlock.Statements | Where-Object { $_.Extent.Text -eq 'Apply-PTSTheme -DarkMode $Global:PTS_DarkModeEnabled' }
if (-not $startupTheme) { throw 'Missing startup theme application' }
. ([scriptblock]::Create($startupTheme.Extent.Text))
if (-not $Global:PTS_DarkModeEnabled -or -not $Global:PTS_UI.DarkModeToggle.IsChecked -or
    $Global:PTS_Window.Background.Color -ne [Windows.Media.ColorConverter]::ConvertFromString($Global:PTS_ThemeDark.Background)) {
    throw 'Startup must apply Dark mode and check the toggle before showing the window'
}
Add-Type @'
public static class ShellStartupProbe {
    [System.Runtime.InteropServices.DllImport("user32.dll")]
    public static extern System.IntPtr GetForegroundWindow();
    [System.Runtime.InteropServices.DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(System.IntPtr window, out uint processId);
}
'@
$Global:PTS_Window.WindowState = if ($Maximized) { 'Maximized' } else { 'Normal' }
$Global:PTS_Window.Width = 1060
$Global:PTS_Window.Height = 792
$Global:PTS_Window.FindName('BrandLogoImage').Source = [Windows.Media.Imaging.BitmapImage]::new(
    [Uri](Join-Path $root 'logo/Windows_Acolyte_Logo.png'))
$cover = [Windows.Window]::new()
$cover.Title = 'Startup focus test'
$cover.Width = 300
$cover.Height = 100
$cover.Show()
$activation = $ast.EndBlock.Statements | Where-Object { $_.Extent.Text -eq '$Global:PTS_Window.Add_ContentRendered($script:PTS_StartupActivationHandler)' }
if (-not $activation) { throw 'Missing startup activation subscription' }
. ([scriptblock]::Create($activation.Extent.Text))
$script:startupFailure = $null
$timer = [Windows.Threading.DispatcherTimer]::new()
$timer.Interval = [TimeSpan]::FromMilliseconds(500)
$timer.Add_Tick({
    $timer.Stop()
    try {
        $handle = [Windows.Interop.WindowInteropHelper]::new($Global:PTS_Window).Handle
        if ([ShellStartupProbe]::GetForegroundWindow() -ne $handle -or -not $Global:PTS_Window.IsActive -or
            -not $Global:PTS_Window.IsKeyboardFocusWithin -or $Global:PTS_Window.Topmost) {
            $foregroundPid = [uint32]0
            [void][ShellStartupProbe]::GetWindowThreadProcessId([ShellStartupProbe]::GetForegroundWindow(), [ref]$foregroundPid)
            throw ("Startup activation failed. Foreground process={0}, active={1}, keyboard focus={2}, topmost={3}" -f
                (Get-Process -Id $foregroundPid).ProcessName, $Global:PTS_Window.IsActive,
                $Global:PTS_Window.IsKeyboardFocusWithin, $Global:PTS_Window.Topmost)
        }
        $border = $Global:PTS_UI.LogoBorder
        if ($border.BorderThickness -ne [Windows.Thickness]::new(1)) { throw 'Logo frame must cover all four sides' }
        $image = $Global:PTS_Window.FindName('BrandLogoImage')
        if ($image.ActualWidth + $border.Padding.Left + $border.Padding.Right + 2 -gt $border.ActualWidth + 0.1) {
            throw 'Logo and its padding must fit inside the full frame'
        }
        if ($RenderDirectory) {
            [void][IO.Directory]::CreateDirectory($RenderDirectory)
            $bitmap = [Windows.Media.Imaging.RenderTargetBitmap]::new(
                [int]$border.ActualWidth, [int]$border.ActualHeight, 96, 96, [Windows.Media.PixelFormats]::Pbgra32)
            $bitmap.Render($border)
            $encoder = [Windows.Media.Imaging.PngBitmapEncoder]::new()
            $encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
            $stream = [IO.File]::Create((Join-Path $RenderDirectory 'logo-frame.png'))
            try { $encoder.Save($stream) } finally { $stream.Dispose() }
        }
        # A later render must not steal focus again.
        $cover.Owner = $Global:PTS_Window
        [void]$cover.Activate()
        $renderMethod = [Windows.Window].GetMethod('OnContentRendered', [Reflection.BindingFlags]'Instance,NonPublic')
        $renderMethod.Invoke($Global:PTS_Window, @([EventArgs]::Empty))
        $coverHandle = [Windows.Interop.WindowInteropHelper]::new($cover).Handle
        if ([ShellStartupProbe]::GetForegroundWindow() -ne $coverHandle) { throw 'Later renders must preserve the active window' }
    } catch { $script:startupFailure = $_ }
    finally { $cover.Close(); $Global:PTS_Window.Close() }
})
try {
    $timer.Start()
    $Global:PTS_Window.ShowDialog() | Out-Null
    if ($script:startupFailure) { throw $script:startupFailure }
    'PASS: Dark startup, complete unclipped logo frame, foreground/keyboard focus and one-shot activation'
} finally {
    $timer.Stop()
    $cover.Close()
    $Global:PTS_Window.Close()
}
