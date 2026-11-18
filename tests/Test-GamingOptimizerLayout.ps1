# PowerShell 7 -STA. Real WPF workspace with synthetic states; no system changes.
param([string]$PreviewDirectory)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework
$root=Split-Path $PSScriptRoot -Parent
$script:checks=0
function Assert-Layout($Condition,$Message){if(-not $Condition){throw $Message};$script:checks++;"PASS: $Message"}
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
function Global:GO-RenderInputExtras {[void]$script:GO_extraList.Items.Add('Synthetic pointer/update fixture')}
function Global:Get-PowerToolsBrush {param($Name) return $Global:PTS_Brush[$Name]}
function Global:Get-PowerToolsWindow {return $script:hostWindow}
function Get-LayoutTexts($Element){
    if($Element -is [Windows.Controls.TextBlock]){$Element.Text}
    $count=[Windows.Media.VisualTreeHelper]::GetChildrenCount($Element)
    for($i=0;$i -lt $count;$i++){Get-LayoutTexts ([Windows.Media.VisualTreeHelper]::GetChild($Element,$i))}
}
function Save-LayoutPreview($Element,[int]$Width,[int]$Height,[string]$Path){
    $bitmap=[Windows.Media.Imaging.RenderTargetBitmap]::new($Width,$Height,96,96,[Windows.Media.PixelFormats]::Pbgra32)
    $bitmap.Render($Element)
    $encoder=[Windows.Media.Imaging.PngBitmapEncoder]::new();$encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
    $stream=[IO.File]::Create($Path);try{$encoder.Save($stream)}finally{$stream.Dispose()}
}
function Get-VisibleIds {@($script:GO_tweaks | Where-Object {$script:GO_cardViews[$_.Id].Visibility -eq 'Visible'} | ForEach-Object Id)}
function Arrange-Workspace($View,[int]$Width,[int]$Height){
    $View.Measure([Windows.Size]::new($Width,$Height));$View.Arrange([Windows.Rect]::new(0,0,$Width,$Height));$View.UpdateLayout()
    GO-UpdateResponsive;$View.UpdateLayout()
}
$shell=[Management.Automation.Language.Parser]::ParseFile((Join-Path $root 'WindowsAcolyte.ps1'),[ref]$tokens,[ref]$errors)
$xamlAssignment=$shell.Find({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -match '^\[xml\]\$xaml$'},$true)
. ([scriptblock]::Create($xamlAssignment.Extent.Text))
$script:hostWindow=[Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($xaml))
$states=@{}
foreach($t in $script:GO_tweaks){
    Assert-Layout ($t.SimpleShort -and $t.SimpleLong -and $t.ShortDesc -and $t.LongDesc -and $t.Impact) "Explanations retained: #$($t.Id)"
    $status=if($t.Id -in @(1,3,10,13,32)){'APPLIED'}elseif($t.Id -eq 24){'CHECK ERROR'}elseif($t.Id -eq 31){'UNAVAILABLE'}else{'MISSING'}
    $states[$t.Id]=@{Status=$status;Applied=$status -eq 'APPLIED';Message='Synthetic check information.'}
}
foreach($theme in @('PTS_Theme','PTS_ThemeDark')){
    $paletteAst=$shell.Find({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq ('$Global:'+$theme)},$true)
    $palette=& ([scriptblock]::Create($paletteAst.Right.Extent.Text))
    $Global:PTS_Brush=@{};foreach($key in $palette.Keys){$Global:PTS_Brush[$key]=[Windows.Media.BrushConverter]::new().ConvertFromString($palette[$key])}
    foreach($width in @(540,900,1280)){
        $view=GO-NewWorkspace
        $script:GO_hwText.Text="CPU: Example processor`nGPU: Example graphics`nRAM: 32 GB | Windows Build: 26100"
        GO-RenderList -States $states
        foreach($line in 1..8){GO-AddLog "Synthetic activity line $line" 'INFO'}
        Arrange-Workspace $view $width 700
        Assert-Layout ($script:GO_cardViews.Count -eq 35 -and $script:GO_categoryButtons.Count -eq 10) "35 settings, eight categories plus All/Selected: $theme/$width"
        Assert-Layout (((Get-VisibleIds) -join ',') -eq '12,13,14,15') "Default shows four graphics settings: $theme/$width"
        Assert-Layout (-not $script:GO_applyBtn.IsEnabled) "No automatic pending changes: $theme/$width"
        Assert-Layout ($script:GO_detailsPane.Visibility -eq 'Collapsed' -and -not $script:GO_tools.IsExpanded) "Secondary tools and details start closed: $theme/$width"
        Assert-Layout ($script:GO_hwInfo.Visibility -eq 'Visible' -and $script:GO_hwInfo.Parent -eq $script:GO_tools.Parent) "PC information is outside collapsed tools: $theme/$width"
        Assert-Layout ($script:GO_logArea.Visibility -eq 'Visible' -and -not $view.FindName('LogExpander')) "Log is permanently visible: $theme/$width"
        Assert-Layout ($script:GO_logScroller.ActualHeight -eq 54 -and $script:GO_logBox.LineHeight -eq 18 -and $script:GO_logBox.LineStackingStrategy -eq 'BlockLineHeight') "Log viewport is exactly three text lines: $theme/$width"
        Assert-Layout ($script:GO_logBox.Text -like '*Synthetic activity line 1*' -and $script:GO_logBox.Text -like '*Synthetic activity line 8*') "Older log messages remain available by scrolling: $theme/$width"
        $menu=$view.FindName('ProfilesBtn').ContextMenu
        Assert-Layout ($menu.Items.Count -eq 3 -and $menu.Items[1] -is [Windows.Controls.Separator] -and $menu.Template -and $menu.Items[0].Template -and $menu.Items[2].Template) "Profile commands have gutter-free rows and a divider: $theme/$width"
        Assert-Layout ($script:GO_cardViews[12].ActualHeight -le 100) "Compact GPU row: $theme/$width"
        foreach($t in $script:GO_tweaks){
            $row=$script:GO_cardViews[$t.Id]
            Assert-Layout ($row.Child.Children[1].Children[0].Text -like 'Risk:*') "Visible risk: #$($t.Id)/$theme/$width"
            Assert-Layout ([object]::ReferenceEquals($row.Child.Children[1].Children[0].Foreground,(GO-GetRiskColor $t.Risk))) "Semantic risk color: #$($t.Id)/$theme/$width"
            Assert-Layout ($script:GO_checkboxes[$t.Id].Parent.Children[0].Child.FontSize -ge 13) "Readable status font: #$($t.Id)/$theme/$width"
            if($t.NeedsReboot){Assert-Layout ('Restart required' -in $row.Child.Children[1].Children.Text) "Visible restart: #$($t.Id)/$theme/$width"}
        }
        $actions=$script:GO_cardViews[13].Child.Children[0].Children[3]
        $detailPoint=$actions.Children[0].TranslatePoint([Windows.Point]::new(0,0),$actions)
        $resetPoint=$actions.Children[1].TranslatePoint([Windows.Point]::new(0,0),$actions)
        Assert-Layout ($actions.Orientation -eq 'Horizontal' -and $detailPoint.Y -eq $resetPoint.Y -and $resetPoint.X -gt $detailPoint.X) "Details and Reset share one horizontal row: $theme/$width"
        $script:GO_checkboxes[12].IsChecked=$true
        GO-SetCategory 'Power & CPU';$script:GO_checkboxes[9].IsChecked=$true
        Assert-Layout ($script:GO_checkboxes[12].IsChecked -and @(Get-VisibleIds).Count -eq 7) "Category switch preserves hidden selection: $theme/$width"
        $script:GO_search.Text='AutoGameModeEnabled'
        Assert-Layout (((Get-VisibleIds) -join ',') -eq '13') "Global technical search: $theme/$width"
        $script:GO_statusFilter.SelectedIndex=1
        Assert-Layout (@(Get-VisibleIds).Count -eq 0 -and $script:GO_emptyMessage.Visibility -eq 'Visible') "Explicit empty filter result: $theme/$width"
        $script:GO_statusFilter.SelectedIndex=0;GO-SetCategory 'Power & CPU'
        Assert-Layout (-not $script:GO_search.Text -and @(Get-VisibleIds).Count -eq 7) "Current category clears search: $theme/$width"
        GO-SetCategory 'Selected'
        Assert-Layout (((Get-VisibleIds) -join ',') -eq '9,12') "Selected view spans categories: $theme/$width"
        GO-RenderList -States $states
        Assert-Layout ($script:GO_checkboxes[9].IsChecked -and $script:GO_checkboxes[12].IsChecked) "Recheck retains valid selection: $theme/$width"
        GO-SetCategory 'All settings'
        Assert-Layout (@(Get-VisibleIds).Count -eq 35) "All settings reachable: $theme/$width"
        Assert-Layout (-not $script:GO_checkboxes[1].IsEnabled -and $script:GO_checkboxes[1].Parent.Children[0].Child.Text -eq 'APPLIED') "OFF target remains APPLIED: $theme/$width"
        Assert-Layout ($script:GO_checkboxes[9].Parent.Children[0].Child.Text -eq 'ALTERNATIVE') "Exclusive preset status: $theme/$width"
        Assert-Layout (-not $script:GO_checkboxes[24].IsEnabled -and -not $script:GO_checkboxes[31].IsEnabled) "Unknown/unavailable targets blocked: $theme/$width"
        GO-SetCategory 'Windows & Lighting'
        Assert-Layout (((Get-VisibleIds) -join ',') -eq '18,19,20,21,29') "Merged visuals/lighting category: $theme/$width"
        GO-SetCategory 'Input & USB'
        Assert-Layout ($script:GO_inputExtras.Visibility -eq 'Visible' -and -not $script:GO_inputExtras.IsExpanded) "Optional tools on demand: $theme/$width"
        GO-SetCategory 'Graphics & Gaming'
        $detailButton=$script:GO_cardViews[12].Child.Children[0].Children[3].Children[0]
        $detailButton.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent));Arrange-Workspace $view $width 700
        Assert-Layout ($script:GO_detailsPane.Visibility -eq 'Visible') "Actual Details button opens content: $theme/$width"
        Assert-Layout (($script:GO_listArea.Visibility -eq 'Visible') -eq ($width -ge 1120)) "Adaptive detail pane: $theme/$width"
        $expanders=@($script:GO_detailsContent.Children | Where-Object {$_ -is [Windows.Controls.Expander]})
        Assert-Layout ($expanders.Count -eq 2 -and -not $expanders[1].IsExpanded -and $expanders[1].Content.Text -like '*HwSchMode*') "Technical detail accessible but initially collapsed: $theme/$width"
        if($PreviewDirectory){[void][IO.Directory]::CreateDirectory($PreviewDirectory);Save-LayoutPreview $view $width 700 (Join-Path $PreviewDirectory "$theme-$width-details.png")}
        $view.FindName('CloseDetailsBtn').RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent));Arrange-Workspace $view $width 400
        Assert-Layout ($script:GO_listArea.Visibility -eq 'Visible' -and $script:GO_checkboxes[12].IsChecked) "Closing details preserves context: $theme/$width"
        $footer=$view.FindName('EstimateBar');$point=$footer.TranslatePoint([Windows.Point]::new(0,0),$view)
        Assert-Layout ($point.Y -ge 0 -and ($point.Y+$footer.ActualHeight) -le 400) "Fixed actions inside short viewport: $theme/$width"
        $review=GO-CreateReviewWindow @($script:GO_tweaks | Where-Object Id -in @(9,12))
        $review.Content.Measure([Windows.Size]::new(640,570));$review.Content.Arrange([Windows.Rect]::new(0,0,640,570));$review.Content.UpdateLayout()
        $texts=@(Get-LayoutTexts $review.Content)
        Assert-Layout (@($texts | Where-Object {$_ -like '*Replaces AAA*'}).Count -eq 1 -and 'BACKUP OPTIONS' -in $texts) "Review includes effects and backup choices: $theme/$width"
        $review.Close()
        # Bind the actual production apply handler; cancellation must precede any IO.
        $handler=$ast.Find({param($n)$n -is [Management.Automation.Language.InvokeMemberExpressionAst] -and $n.Expression.Extent.Text -eq '$script:GO_applyBtn' -and $n.Member.Value -eq 'Add_Click'},$true)
        . ([scriptblock]::Create($handler.Extent.Text))
        function Global:GO-ConfirmSelection {param($Selected) $script:reviewedIds=@($Selected.Id);return $false}
        function Global:GO-CreateBackup {throw 'Unexpected backup IO'}
        function Global:GO-ApplyVerifiedTweak {throw 'Unexpected system IO'}
        $script:GO_applyBtn.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
        Assert-Layout (($script:reviewedIds -join ',') -eq '9,12') "Cancel review applies nothing: $theme/$width"
        if($PreviewDirectory){Arrange-Workspace $view $width 700;Save-LayoutPreview $view $width 700 (Join-Path $PreviewDirectory "$theme-$width.png")}
        if($PreviewDirectory){
            $menu.Measure([Windows.Size]::new(200,100));$menu.Arrange([Windows.Rect]::new(0,0,200,100));$menu.UpdateLayout()
            Save-LayoutPreview $menu 200 100 (Join-Path $PreviewDirectory "$theme-profiles.png")
        }
        # Exercise the actual shell ScrollViewer/ContentControl hierarchy, including its margins.
        $outer=$script:hostWindow.FindName('ContentScroller');$hostContent=$script:hostWindow.FindName('ContentHost')
        $outer.VerticalScrollBarVisibility='Disabled';$hostContent.Content=$view
        $outer.Measure([Windows.Size]::new($width,500));$outer.Arrange([Windows.Rect]::new(0,0,$width,500));$outer.UpdateLayout()
        $footerPoint=$view.FindName('EstimateBar').TranslatePoint([Windows.Point]::new(0,0),$outer)
        Assert-Layout ($footerPoint.Y -ge 0 -and ($footerPoint.Y+$view.FindName('EstimateBar').ActualHeight) -le 500) "Actions remain in actual shell viewport: $theme/$width"
        $hostContent.Content=$null
    }
}
"PASS: $script:checks layout/navigation assertions"
