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
    $Global:DSC_localCheck.IsChecked=$false
    $Global:DSC_installerCheck.IsChecked=$false
    $Global:DSC_domainStartCheck.IsChecked=$true
    $Global:DSC_domainInstallerCheck.IsChecked=$true
    DSC-CreateSelectedShortcuts
    $links=@(Get-ChildItem -LiteralPath $testDirectory -Filter '*.lnk')
    if($links.Count -ne 2){throw 'Expected exactly two domain shortcuts'}
    $shell=New-Object -ComObject WScript.Shell
    foreach($linkFile in $links){
        $link=$shell.CreateShortcut($linkFile.FullName)
        if($link.TargetPath -ne (DSC-GetShortcutHostPath)){throw 'Unexpected shortcut host'}
        if($link.Arguments -notmatch 'irm https://windowsacolyte\.de \| iex'){throw 'Domain command missing'}
        "PASS: $($linkFile.Name) targets windowsacolyte.de"
    }
    if(-not (Test-Path -LiteralPath (Join-Path $testDirectory 'WA Online Start.lnk')) -or -not (Test-Path -LiteralPath (Join-Path $testDirectory 'WA Online Installer.lnk'))){throw 'Expected domain names missing'}
    $Global:DSC_domainStartCheck.IsChecked=$false
    $Global:DSC_domainInstallerCheck.IsChecked=$false
    $Global:DSC_localCheck.IsChecked=$true
    $Global:DSC_installerCheck.IsChecked=$true
    DSC-CreateSelectedShortcuts
    foreach($name in @('WA Local Start','WA Local Installer')) {
        $path=Join-Path $testDirectory ($name+'.lnk')
        if(-not (Test-Path -LiteralPath $path)){throw "Missing local shortcut: $name"}
        $local=$shell.CreateShortcut($path)
        if($local.Arguments -notmatch '-File' -or $local.Arguments -match 'windowsacolyte\.de'){throw 'Local selection changed'}
        "PASS: $name uses the local starter"
    }
    foreach($control in @($Global:DSC_localCheck,$Global:DSC_installerCheck,$Global:DSC_domainStartCheck,$Global:DSC_domainInstallerCheck)) {
        if(-not (Test-Path -LiteralPath (Join-Path $testDirectory ($control.Content+'.lnk')))){throw "Label does not match generated filename: $($control.Content)"}
    }
    'PASS: all four UI labels match generated filenames'
} finally {
    $safeParent=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
    $resolved=[IO.Path]::GetFullPath($testDirectory)
    if($resolved.StartsWith($safeParent,[StringComparison]::OrdinalIgnoreCase) -and [IO.Path]::GetFileName($resolved).StartsWith('WindowsAcolyte-ShortcutTest-')){Remove-Item -LiteralPath $resolved -Recurse -Force}
}
