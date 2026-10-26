# PowerShell 7 -STA. Render real educational views with synthetic read-only state.
param([string]$PreviewDirectory)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework
$root=Split-Path $PSScriptRoot -Parent
function Assert-Layout($Condition,$Message){if(-not $Condition){throw $Message};"PASS: $Message"}
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $root 'modules/05-GamingOptimizer.ps1'),[ref]$tokens,[ref]$errors)
if($errors.Count){throw ($errors.Message -join '; ')}
foreach($definition in $ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -like 'Global:GO-*'},$true)){
    . ([scriptblock]::Create($definition.Extent.Text))
}
$assignment=$ast.Find({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$script:GO_tweaks'},$true)
$next=$ast.Find({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Global:GO-GetRiskColor'},$true)
. ([scriptblock]::Create($ast.Extent.Text.Substring($assignment.Extent.StartOffset,$next.Extent.StartOffset-$assignment.Extent.StartOffset)))
function Global:GO-ReadUsbBackup {param($Id) return $null}
function Global:GO-RenderInputExtras {}
function Global:GO-ShowDetailWindow {param($Tweak) $script:openedDetailId=$Tweak.Id}
function Global:Get-PowerToolsBrush {param($Name) return $Global:PTS_Brush[$Name]}
function Global:Get-PowerToolsWindow {return $script:hostWindow}
function Get-LayoutTexts($Element){
    if($Element -is [System.Windows.Controls.TextBlock]){$Element.Text}
    $count=[System.Windows.Media.VisualTreeHelper]::GetChildrenCount($Element)
    for($i=0;$i -lt $count;$i++){Get-LayoutTexts ([System.Windows.Media.VisualTreeHelper]::GetChild($Element,$i))}
}
function Save-LayoutPreview($Element,[int]$Width,[int]$Height,[string]$Path){
    $bitmap=[System.Windows.Media.Imaging.RenderTargetBitmap]::new($Width,$Height,96,96,[System.Windows.Media.PixelFormats]::Pbgra32)
    $bitmap.Render($Element)
    $encoder=[System.Windows.Media.Imaging.PngBitmapEncoder]::new();$encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
    $stream=[IO.File]::Create($Path);try{$encoder.Save($stream)}finally{$stream.Dispose()}
}
$shell=[Management.Automation.Language.Parser]::ParseFile((Join-Path $root 'WindowsAcolyte.ps1'),[ref]$tokens,[ref]$errors)
$xamlAssignment=$shell.Find({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -match '^\[xml\]\$xaml$'},$true)
. ([scriptblock]::Create($xamlAssignment.Extent.Text))
$script:hostWindow=[Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($xaml))
$script:GO_checkboxes=@{};$script:GO_applyBtn=[System.Windows.Controls.Button]::new();$script:GO_estimate=[System.Windows.Controls.TextBlock]::new();$script:GO_impactText=[System.Windows.Controls.TextBlock]::new()
$states=@{}
foreach($t in $script:GO_tweaks){
    Assert-Layout ($t.SimpleShort -and $t.SimpleLong -and $t.ShortDesc -and $t.LongDesc -and $t.Impact -and $t.SimpleShort -ne $t.ShortDesc) "Separate simple/technical summaries and details: #$($t.Id)"
    $status=if($t.Id -in @(1,3,10,13,32)){'APPLIED'}elseif($t.Id -eq 24){'CHECK ERROR'}elseif($t.Id -eq 31){'UNAVAILABLE'}else{'MISSING'}
    $states[$t.Id]=@{Status=$status;Applied=$status -eq 'APPLIED';Message='Synthetic status for layout verification.'}
}
foreach($theme in @('PTS_Theme','PTS_ThemeDark')){
    $paletteAst=$shell.Find({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq ('$Global:'+$theme)},$true)
    $palette=& ([scriptblock]::Create($paletteAst.Right.Extent.Text))
    $Global:PTS_Brush=@{};foreach($key in $palette.Keys){$Global:PTS_Brush[$key]=[System.Windows.Media.BrushConverter]::new().ConvertFromString($palette[$key])}
    foreach($width in @(540,900)){
        $script:GO_tweakList=[System.Windows.Controls.ItemsControl]::new();$script:GO_tweakList.Width=$width
        $script:GO_tweakList.Background=Get-PowerToolsBrush 'Background'
        foreach($key in $Global:PTS_Brush.Keys){$script:GO_tweakList.Resources["Dyn$key"]=$Global:PTS_Brush[$key]}
        [System.Windows.Documents.TextElement]::SetFontFamily($script:GO_tweakList,[System.Windows.Media.FontFamily]::new('Segoe UI'))
        GO-RenderList -States $states
        $script:GO_tweakList.Measure([System.Windows.Size]::new($width,[double]::PositiveInfinity))
        $height=$script:GO_tweakList.DesiredSize.Height
        $script:GO_tweakList.Arrange([System.Windows.Rect]::new(0,0,$width,$height));$script:GO_tweakList.UpdateLayout()
        Assert-Layout ($script:GO_cardViews.Count -eq 35) "All 35 cards rendered: $theme / $width"
        foreach($t in $script:GO_tweaks){
            $header=$script:GO_checkboxes[$t.Id].Parent
            Assert-Layout ([System.Windows.Controls.Grid]::GetColumn($header.Children[0]) -eq 0 -and $header.Children[0].Child.Name -eq 'TweakStatus' -and [System.Windows.Controls.Grid]::GetColumn($header.Children[2]) -eq 2) "Status precedes checkbox and title: #$($t.Id) / $theme / $width"
            Assert-Layout ($script:GO_cardViews[$t.Id].ActualWidth -le $width -and $header.Children[2].ActualWidth -gt 100) "Card and title fit available width: #$($t.Id) / $theme / $width"
            $metadata=$script:GO_cardViews[$t.Id].Child.Children[1]
            Assert-Layout ($metadata.Children.Count -eq 3 -and $metadata.Children[0].Text -like 'RISK:*' -and $metadata.Children[1].Text -like 'RESTART:*') "Risk/restart/selection are separately labeled: #$($t.Id) / $theme / $width"
        }
        Assert-Layout (-not $script:GO_checkboxes[1].IsEnabled -and $script:GO_checkboxes[1].Parent.Children[0].Child.Text -eq 'APPLIED') "OFF target is clearly APPLIED: $theme / $width"
        $detailButton=$script:GO_cardViews[1].Child.Children[-1].Children[0]
        $detailButton.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
        Assert-Layout ($detailButton.IsEnabled -and $script:openedDetailId -eq 1) "Details remain accessible for an applied target: $theme / $width"
        Assert-Layout ($script:GO_checkboxes[9].Parent.Children[0].Child.Text -eq 'ALTERNATIVE') "Exclusive alternate preset retained: $theme / $width"
        Assert-Layout (-not $script:GO_checkboxes[24].IsEnabled -and -not $script:GO_checkboxes[31].IsEnabled) "Unknown/unavailable controls remain disabled: $theme / $width"
        $script:GO_checkboxes[9].IsChecked=$true
        Assert-Layout ($script:GO_applyBtn.IsEnabled -and $script:GO_estimate.Text -notmatch 'Estimated FPS|\d+%' -and $script:GO_impactText.Text -like '*Replaces AAA*') "Selection works and preserves conflict notes without adding FPS estimates: $theme / $width"
        $detail=GO-CreateDetailWindow ($script:GO_tweaks | Where-Object Id -eq 1)
        $detail.Content.Measure([System.Windows.Size]::new(660,620));$detail.Content.Arrange([System.Windows.Rect]::new(0,0,660,620));$detail.Content.UpdateLayout()
        $texts=@(Get-LayoutTexts $detail.Content)
        Assert-Layout ('IN PLAIN ENGLISH' -in $texts -and 'TECHNICAL DETAILS' -in $texts -and 'RISK LEVEL' -in $texts -and 'IMPACT / EXPECTED EFFECT' -in $texts -and 'STATUS: APPLIED' -in $texts) "Scrollable details expose both explanations and status: $theme / $width"
        $first=$script:GO_tweaks | Where-Object Id -eq 1
        Assert-Layout ($first.SimpleLong -in $texts -and $first.LongDesc -in $texts) "Full simple and technical text is present in details: $theme / $width"
        if($PreviewDirectory){
            [void][IO.Directory]::CreateDirectory($PreviewDirectory)
            Save-LayoutPreview $script:GO_tweakList $width 1100 (Join-Path $PreviewDirectory "$theme-$width.png")
            Save-LayoutPreview $detail.Content 660 620 (Join-Path $PreviewDirectory "$theme-detail.png")
        }
        $detail.Close()
    }
}
