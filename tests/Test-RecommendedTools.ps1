# Run with pwsh -STA -File tests/Test-RecommendedTools.ps1. No system tweaks or browser launches.
param([string]$PreviewDirectory)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework
$root = Split-Path $PSScriptRoot -Parent
function Assert-RT($Condition, $Message) {
    if (-not $Condition) { throw $Message }
    Write-Output "PASS: $Message"
}
function Get-RTLuminance($Color) {
    $channels = @($Color.R, $Color.G, $Color.B) | ForEach-Object {
        $value = $_ / 255.0
        if ($value -le 0.04045) { $value / 12.92 } else { [math]::Pow(($value + 0.055) / 1.055, 2.4) }
    }
    return 0.2126*$channels[0] + 0.7152*$channels[1] + 0.0722*$channels[2]
}
$tokens = $null; $errors = $null
$shellAst = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $root 'WindowsAcolyte.ps1'), [ref]$tokens, [ref]$errors)
foreach ($name in @('Register-PowerToolsModule', 'Show-PTSModuleView')) {
    $definition = $shellAst.Find({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq "Global:$name"}, $true)
    . ([scriptblock]::Create($definition.Extent.Text))
}
$Global:PTS_Modules = [System.Collections.ArrayList]::new()
. (Join-Path $root 'modules\05-GamingOptimizer.ps1')
. (Join-Path $root 'modules\12-RecommendedTools.ps1')
$module = $Global:PTS_Modules | Where-Object Id -eq 'recommended-tools'
Assert-RT ($module.Category -eq 'Performance' -and -not $module.RequiresAdmin) 'Standalone recommendation module registered in Performance'
$Global:PTS_CategoryDisplayNames = @{Performance='Gaming Performance'}
$Global:PTS_UI = @{
    BackBtn=[System.Windows.Controls.Button]::new()
    ContentHost=[System.Windows.Controls.ContentControl]::new()
    ContentScroller=[System.Windows.Controls.ScrollViewer]::new()
}
function Global:Set-PTSHeader { param($Eyebrow,$Title,$Subtitle) $script:headerTitle=$Title }
function Global:Set-PTSFooterStatus { param($Text) }
function Global:Write-PTSExceptionReport { throw 'Unexpected navigation error' }
function Global:Start-Process { param($FilePath) $script:openedUrls += [string]$FilePath }
$script:openedUrls = @()
[System.Windows.Application]::new() | Out-Null
$shellXaml = $shellAst.Find({param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -match '\$xaml$'}, $true)
. ([scriptblock]::Create($shellXaml.Extent.Text))
$shellWindow = [Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($xaml))
foreach ($key in $shellWindow.Resources.Keys) {
    [System.Windows.Application]::Current.Resources[$key] = $shellWindow.Resources[$key]
}
$tools = @(RT-GetTools)
Assert-RT ($tools.Count -eq 12 -and @($tools.Group | Select-Object -Unique).Count -eq 5) 'Twelve tools in five groups'
foreach ($themeName in @('PTS_Theme','PTS_ThemeDark')) {
    # Use the shell palettes rather than hardcoded color values.
    $assignment = $shellAst.Find({param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq ('$Global:' + $themeName)}, $true)
    if (-not $assignment) { throw "Missing shell theme: $themeName" }
    $palette = & ([scriptblock]::Create($assignment.Right.Extent.Text))
    foreach ($key in $palette.Keys) {
        if ([System.Windows.Application]::Current.Resources.Contains("Dyn$key")) {
            [System.Windows.Application]::Current.Resources["Dyn$key"] = [System.Windows.Media.BrushConverter]::new().ConvertFromString($palette[$key])
        }
    }
    Show-PTSModuleView $module
    $view = $Global:PTS_UI.ContentHost.Content
    $view.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($palette.Background)
    [System.Windows.Documents.TextElement]::SetFontFamily($view, [System.Windows.Media.FontFamily]::new('Segoe UI'))
    Assert-RT ($view -is [System.Windows.Controls.StackPanel] -and $script:headerTitle -eq 'Recommended Tools') "Shell navigation loads page: $themeName"
    $notice = $view.Children | Where-Object Name -eq 'RTExternalLinksNotice'
    Assert-RT ($view.Children[0] -eq $notice -and $notice.Child.Children[0].Text -like '*HAFTUNGSHINWEIS*') "Prominent labeled external-link warning precedes every tool: $themeName"
    $expectedNoticeBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($palette.AccentSoft)
    Assert-RT ($notice.Background.ToString() -eq $expectedNoticeBrush.ToString() -and $notice.BorderThickness.Left -eq 5) "Notice has theme-aware warning colors and strong border: $themeName"
    $noticeForeground = $notice.Child.Children[0].Foreground.Color
    $light = Get-RTLuminance $noticeForeground
    $dark = Get-RTLuminance $notice.Background.Color
    $contrast = ([math]::Max($light,$dark)+0.05) / ([math]::Min($light,$dark)+0.05)
    Assert-RT ($contrast -ge 4.5) "Disclaimer text contrast is at least 4.5:1: $themeName"
    $report = $notice.Child.Children | Where-Object { $_ -is [System.Windows.Controls.Button] }
    $report.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
    Assert-RT ($script:openedUrls[-1] -eq 'https://github.com/ReAlNoMo/WindowsAcolyte/issues') "Link reporting opens the project issue page: $themeName"
    $cards = @($view.Children | Where-Object { $_ -is [System.Windows.Controls.Border] -and $_.Tag -eq 'RecommendedToolCard' })
    Assert-RT ($cards.Count -eq 12) "All tool cards rendered: $themeName"
    foreach ($card in $cards) {
        $button = $card.Child.Children | Where-Object { $_ -is [System.Windows.Controls.Button] }
        $button.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
        Assert-RT ($script:openedUrls[-1] -eq $button.Tag) "Correct publisher link: $($card.Child.Children[0].Text)"
    }
    $view.Measure([System.Windows.Size]::new(760, [double]::PositiveInfinity))
    $view.Arrange([System.Windows.Rect]::new(0,0,760,$view.DesiredSize.Height))
    $view.UpdateLayout()
    $expectedBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($palette.TileBg)
    Assert-RT ($cards[0].Background.ToString() -eq $expectedBrush.ToString()) "Theme resource resolved: $themeName"
    if ($PreviewDirectory) {
        [void][IO.Directory]::CreateDirectory($PreviewDirectory)
        $bitmap = [System.Windows.Media.Imaging.RenderTargetBitmap]::new(760,[int][Math]::Ceiling($view.ActualHeight),96,96,[System.Windows.Media.PixelFormats]::Pbgra32)
        $bitmap.Render($view)
        $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
        $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
        $stream = [IO.File]::Create((Join-Path $PreviewDirectory "$themeName.png"))
        try { $encoder.Save($stream) } finally { $stream.Dispose() }
    }
}
$optimizer = [IO.File]::ReadAllText((Join-Path $root 'modules\05-GamingOptimizer.ps1'))
Assert-RT ($optimizer -notmatch 'SoftwareInfoBtn|GO_softInfoBtn|GO-ShowSoftwareInfo') 'Old button, binding and dialog removed'
$optimizerAst = [System.Management.Automation.Language.Parser]::ParseInput($optimizer, [ref]$tokens, [ref]$errors)
$optimizerXamlAssignment = $optimizerAst.Find({param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -match '\$viewXaml$'}, $true)
. ([scriptblock]::Create($optimizerXamlAssignment.Extent.Text))
$reader = [System.Xml.XmlNodeReader]::new($viewXaml)
$optimizerView = [Windows.Markup.XamlReader]::Load($reader)
Assert-RT ($null -ne $optimizerView.FindName('HardwareText')) 'Optimizer XAML loads and retains hardware controls'
function Global:Start-Process { param($FilePath) throw 'Simulated browser failure' }
$lastButton = $cards[-1].Child.Children | Where-Object { $_ -is [System.Windows.Controls.Button] }
$lastButton.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
Assert-RT (($view.Children | Where-Object Name -eq 'RTLinkStatus').Text -like 'Could not open browser.*') 'Browser failure displays publisher URL fallback'
