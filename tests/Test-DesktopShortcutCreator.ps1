# PowerShell 7 -STA. Creates test links only inside a temporary directory.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework
$root=Split-Path $PSScriptRoot -Parent
$testDirectory=Join-Path ([IO.Path]::GetTempPath()) ('WindowsAcolyte-ShortcutTest-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($testDirectory)
try {
    $Global:PTS_RootPath=$root
    $Global:PTS_Brush=@{}
    foreach($key in @('Surface','Border','TextMid','TextDark','TextMuted','LogBg','LogBorder')){$Global:PTS_Brush[$key]=[System.Windows.Media.Brushes]::Gray}
    $script:hostWindow=[System.Windows.Window]::new()
    foreach($style in @('PrimaryButton','SecondaryButton')){$script:hostWindow.Resources.Add($style,[System.Windows.Style]::new([System.Windows.Controls.Button]))}
    function Global:Get-PowerToolsWindow {return $script:hostWindow}
    function Global:Register-PowerToolsModule {param($Id,$Name,$Description,$Category,$Show,$RequiresAdmin) $script:moduleShow=$Show; $script:moduleName=$Name}
    . (Join-Path $root 'modules/08-DesktopShortcutCreator.ps1')
    if($script:moduleName -ne 'WindowsAcolyte Desktop Shortcut Creator'){throw 'Incorrect module name'}
    $view=& $script:moduleShow
    function Global:DSC-GetDesktopPath {return $testDirectory}
    function Global:DSC-EnsurePowerShell7Bootstrap {param($InstallPath) return (Join-Path $testDirectory 'Start-WindowsAcolyte.ps1')}
    $Global:DSC_localCheck.IsChecked=$true
    $Global:DSC_installerCheck.IsChecked=$true
    $Global:DSC_domainStartCheck.IsChecked=$true
    $Global:DSC_domainInstallerCheck.IsChecked=$true
    DSC-CreateSelectedShortcuts
    $links=@(Get-ChildItem -LiteralPath $testDirectory -Filter '*.lnk')
    if($links.Count -ne 4){throw 'Expected four shortcuts'}
    $shell=New-Object -ComObject WScript.Shell
    $expected=@{
        'WA Install Git'=@{Uri='raw.githubusercontent.com';Online=$false}
        'WA Install .de'=@{Uri='https://windowsacolyte.de';Online=$false}
        'WA Online Git'=@{Uri='raw.githubusercontent.com';Online=$true}
        'WA Online .de'=@{Uri='https://windowsacolyte.de';Online=$true}
    }
    foreach($name in $expected.Keys){
        $path=Join-Path $testDirectory ($name+'.lnk')
        if(-not (Test-Path -LiteralPath $path)){throw "Missing shortcut: $name"}
        $link=$shell.CreateShortcut($path)
        if($link.TargetPath -ne (DSC-GetShortcutHostPath)){throw "Incorrect host: $name"}
        if(-not $link.Arguments.Contains($expected[$name].Uri)){throw "Incorrect source: $name"}
        if(($link.Arguments -match '-OnlineRun') -ne $expected[$name].Online){throw "Incorrect run mode: $name"}
        "PASS: $name uses the correct source and mode"
    }
    foreach($control in @($Global:DSC_localCheck,$Global:DSC_installerCheck,$Global:DSC_domainStartCheck,$Global:DSC_domainInstallerCheck)) {
        if(-not (Test-Path -LiteralPath (Join-Path $testDirectory ($control.Content+'.lnk')))){throw "Label mismatch: $($control.Content)"}
    }
    'PASS: all four labels match their filenames'
} finally {
    $safeParent=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
    $resolved=[IO.Path]::GetFullPath($testDirectory)
    if($resolved.StartsWith($safeParent,[StringComparison]::OrdinalIgnoreCase) -and [IO.Path]::GetFileName($resolved).StartsWith('WindowsAcolyte-ShortcutTest-')){Remove-Item -LiteralPath $resolved -Recurse -Force}
}
