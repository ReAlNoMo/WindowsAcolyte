# External tool catalogue. Links open publisher pages; no software is installed or run.
function Global:RT-GetTools {
    @(
        @{Group='GPU & Drivers'; Name='MSI Afterburner + RTSS';
          Purpose='Monitor GPU sensors and display performance metrics; RTSS adds an overlay and frame limiting.';
          Use='Compare temperatures, GPU load and frame pacing while troubleshooting or choosing an FPS cap.';
          Note='Overlays may be restricted by games or anti-cheat. Choose caps for your game and display; there is no universal best cap. Overclocking is optional.';
          Url='https://www.msi.com/Landing/afterburner/afterburner'}
        @{Group='GPU & Drivers'; Name='NVCleanstall';
          Purpose='Customize which components are included in an NVIDIA display-driver installation.';
          Use='For NVIDIA users who want to select driver components explicitly.';
          Note='Keep components needed for your hardware and features. Removing components does not guarantee higher FPS. Publisher page could not be rechecked on 2026-10-26.';
          Url='https://www.techpowerup.com/nvcleanstall/'}
        @{Group='GPU & Drivers'; Name='DDU - Display Driver Uninstaller';
          Purpose='Remove display drivers for a clean reinstallation.';
          Use='Targeted troubleshooting of driver problems or a GPU vendor change.';
          Note='Not required before every routine driver update. Follow the publisher instructions, prepare the replacement driver and use the recommended Safe Mode procedure.';
          Url='https://www.wagnardsoft.com/display-driver-uninstaller-ddu'}
        @{Group='CPU & RAM'; Name='Process Lasso';
          Purpose='Manage persistent process priorities, CPU affinities, CPU sets and power-plan rules.';
          Use='Investigate CPU contention and test per-game scheduling rules on your own hardware.';
          Note='Incorrect affinity rules can reduce performance. Test against Windows defaults. Some features require Pro.';
          Url='https://bitsum.com/'}
        @{Group='CPU & RAM'; Name='ISLC - Intelligent Standby List Cleaner';
          Purpose='Monitor and clear the Windows standby memory list using configurable thresholds.';
          Use='Optional controlled test when investigating suspected memory-related stutter.';
          Note='Cached memory is normally managed by Windows. Clearing it is not a general FPS improvement; retain only changes with a repeatable measured benefit.';
          Url='https://www.wagnardsoft.com/intelligent-standby-list-cleaner-islc'}
        @{Group='Monitor & Mouse'; Name='Dual Monitor Tools';
          Purpose='Keep the cursor on one monitor with a lock hotkey, or add resistance at monitor edges with Sticky mode.';
          Use='Multi-monitor gaming: avoid moving from a game menu onto the Windows desktop on another screen and clicking outside the game.';
          Note='Configure Cursor > Sticky and a lock/unlock hotkey. Sticky mode adds resistance; Locked mode confines the cursor to one monitor. This does not block Alt+Tab or every cause of focus loss.';
          Url='https://dualmonitortool.sourceforge.net/dmt_cursor.html'}
        @{Group='Monitor & Mouse'; Name='Custom Resolution Utility (CRU)';
          Purpose='Edit monitor EDID overrides, custom resolutions and refresh-rate timings.';
          Use='Advanced display configuration when supported modes are missing or need adjustment.';
          Note='Unsupported timings can cause a blank screen. Export the original configuration first and read the publisher recovery instructions for reset-all.exe / Safe Mode before applying changes.';
          Url='https://www.monitortests.com/forum/Thread-Custom-Resolution-Utility-CRU'}
        @{Group='Diagnostics'; Name='LatencyMon';
          Purpose='Measure ISR/DPC execution and hard pagefaults to investigate real-time audio latency problems.';
          Use='Collect driver-related clues while reproducing audio dropouts or suspected latency issues.';
          Note='A high reading is a clue, not proof that a driver causes game stutter. LatencyMon does not measure end-to-end mouse-to-display latency.';
          Url='https://www.resplendence.com/latencymon'}
        @{Group='Diagnostics'; Name='TimerTool (TimerResolution alternative)';
          Purpose='Read and request Windows timer-resolution values.';
          Use='Advanced timer experiments with repeatable before/after measurements.';
          Note='Not a general gaming recommendation. A requested value is not proof that a game uses it or gains FPS; close the tool after testing.';
          Url='https://github.com/tebjan/TimerTool'}
        @{Group='Diagnostics'; Name='InSpectre (Gibson Research)';
          Purpose='Inspect legacy Meltdown and Spectre protection information.';
          Use='Reference for these specific vulnerabilities; consult current OS and CPU-vendor guidance for a complete assessment.';
          Note='Not a complete checker for all modern CPU vulnerabilities. Disabling security mitigations is not recommended as a gaming tweak.';
          Url='https://www.grc.com/inspectre.htm'}
        @{Group='Windows Utilities'; Name='Chris Titus Tech Windows Utility (WinUtil)';
          Purpose='Install applications, select Windows tweaks, run fixes and configure updates.';
          Use='Review Windows setup and maintenance tasks in a single utility.';
          Note='System-wide operations require administrator rights. Review individual changes and avoid overlapping tweaks with WindowsAcolyte; this page only opens the documentation.';
          Url='https://winutil.christitus.com/'}
        @{Group='Windows Utilities'; Name='O&O ShutUp10++ / O&O ShutUp10';
          Purpose='Review and configure Windows privacy and convenience settings.';
          Use='Choose privacy settings individually, based on the features you use.';
          Note='Privacy changes can affect Windows features. Review each option and its restore method; this is not an FPS booster.';
          Url='https://www.oo-software.com/en/shutup10'}
    )
}

Register-PowerToolsModule `
    -Id 'recommended-tools' `
    -Name 'Recommended Tools' `
    -Description 'External tools grouped by hardware, diagnostics and Windows maintenance.' `
    -Category 'Performance' `
    -RequiresAdmin $false `
    -Show {
    $view = [System.Windows.Controls.StackPanel]::new()

    function RT-AddText {
        param($Parent, [string]$Text, [string]$Brush = 'TextDark', [int]$Size = 12)
        $label = [System.Windows.Controls.TextBlock]::new()
        $label.Text = $Text
        $label.TextWrapping = 'Wrap'
        $label.FontSize = $Size
        $label.Margin = '0,0,0,8'
        $label.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "Dyn$Brush")
        [void]$Parent.Children.Add($label)
        return $label
    }

    $intro = RT-AddText $view 'Choose tools for a specific task. Open publisher pages for documentation and downloads; nothing is installed automatically.' 'TextMid' 13
    $status = RT-AddText $view '' 'TextMuted' 11
    $status.Name = 'RTLinkStatus'
    $tools = @(RT-GetTools)
    $currentGroup = ''
    foreach ($tool in $tools) {
        if ($tool.Group -ne $currentGroup) {
            $currentGroup = $tool.Group
            $heading = RT-AddText $view $currentGroup 'Primary' 18
            $heading.FontWeight = 'SemiBold'
            $heading.Margin = '0,14,0,12'
        }
        $card = [System.Windows.Controls.Border]::new()
        $card.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'DynTileBg')
        $card.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'DynTileBorder')
        $card.BorderThickness = 1
        $card.CornerRadius = 8
        $card.Padding = '16,14'
        $card.Margin = '0,0,0,12'
        $panel = [System.Windows.Controls.StackPanel]::new()
        $name = RT-AddText $panel $tool.Name 'TextDark' 15
        $name.FontWeight = 'SemiBold'
        $null = RT-AddText $panel $tool.Purpose
        $null = RT-AddText $panel ("WHEN TO USE: " + $tool.Use) 'TextMid'
        $null = RT-AddText $panel ("KEEP IN MIND: " + $tool.Note) 'TextMuted'
        $button = [System.Windows.Controls.Button]::new()
        $button.Content = 'Open official page / download'
        $button.Tag = $tool.Url
        $button.ToolTip = $tool.Url
        $button.HorizontalAlignment = 'Left'
        $button.Padding = '12,6'
        $button.SetResourceReference([System.Windows.Controls.Button]::StyleProperty, 'SecondaryButton')
        $linkStatus = $status
        $button.Add_Click({
            param($sender, $eventArgs)
            try {
                Start-Process -FilePath ([string]$sender.Tag) -ErrorAction Stop | Out-Null
                $linkStatus.Text = 'Opened publisher page in your browser.'
            } catch {
                $linkStatus.Text = 'Could not open browser. Publisher URL: ' + [string]$sender.Tag
            }
        }.GetNewClosure())
        [void]$panel.Children.Add($button)
        $card.Child = $panel
        [void]$view.Children.Add($card)
    }
    return $view
}
