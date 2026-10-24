# ⚡ WindowsAcolyte

> 🧰 **Unified WPF launcher for Windows utility scripts**
> 🚀 One-click install via PowerShell
> 🎨 **Dynamic Light/Dark Theme**

---

## 🟢 Quick Start

### ⚡ Install / Update

> ✅ Fast • Trusted • No setup

```powershell
irm "https://raw.githubusercontent.com/ReAlNoMo/WindowsAcolyte/main/install.ps1" | iex
```

---

## ⚙️ Requirements

| Requirement | Details |
|------------|--------|
| 🟦 PowerShell | 7.0+ (auto-download if missing) |
| 🪟 Windows | 10 / 11 (WPF required) |
| 🔐 Admin | Required for some modules |

**Current version:** `v1.6`

---

# 🧰 Modules (11 Total)

---

## 🎨 Dark Mode
> **Global theme toggle** for the entire UI

| Light Mode | Dark Mode |
|---|---|
| <img src="https://raw.githubusercontent.com/ReAlNoMo/WindowsAcolyte/main/screenshots/00-main-window-light.png" alt="WindowsAcolyte main window light mode" width="420"> | <img src="https://raw.githubusercontent.com/ReAlNoMo/WindowsAcolyte/main/screenshots/00-main-window-dark.png" alt="WindowsAcolyte main window dark mode" width="420"> |

- Toggle button (bottom-left sidebar)
- **Light + Dark themes** (all 50+ colors)
- Dynamic brush updates in real-time
- **Persistent across all modules**
- Logo border auto-adjusts
- All native controls + custom elements

---

## 🔒 1. Hash Verifier
> **Category:** Security
> **Admin:** ❌ No

<img src="https://raw.githubusercontent.com/ReAlNoMo/WindowsAcolyte/main/screenshots/01-hash-verifier.png" alt="Hash Verifier module" width="720">

### ✔ What it does
- Generate file hashes (SHA-256, SHA-512, SHA-384, SHA-1, MD5)
- Compare computed hash against an expected value
- Detect tampering or file corruption
- Live progress bar with percentage display
- Activity log with timestamps and status codes
- Background processing via Runspace + DispatcherTimer (non-blocking UI)

💡 **Use case:** Verify downloads before execution
🪶 **Windows changes:** None

---

## 🗂️ 2. Explorer View Normalizer
> **Category:** Windows Tools
> **Admin:** ⚠️ Yes

<img src="https://raw.githubusercontent.com/ReAlNoMo/WindowsAcolyte/main/screenshots/02-explorer-view-normalizer.png" alt="Explorer View Normalizer module" width="720">

### ✔ What it does
- Lets you compose global Explorer defaults using checkbox fields
- Splits settings list into **Already Set** and **Not Selected**
- Checks all settings on module load and shows current state immediately
- Reset saved Explorer folder views
- Force **Details view** across all normal folder types
- Disable grouping completely (`Last week`, `Last month`, etc.)
- Sort by **Name (ASC)**
- Apply columns: **Name**, **Date modified**, **Type**, **Size**
- Show hidden files
- Show file extensions
- Keep protected operating system files hidden
- Disable Compact View
- Enable Details Pane and keep Preview Pane available
- Optional: use **small desktop icons** (`IconSize=32`)
- Disable Folder Type Discovery with `FolderType = NotSpecified`
- Apply to all folder types (Generic, Downloads, Documents, Pictures, Music, Videos, UserFiles, Searches)
- Clear Shell Bags, BagMRU, Desktop/Defaults Streams, and common Open/Save dialog view caches
- Restart Explorer automatically
- Apply now supports **apply + revert**: unchecked options are reverted when possible
- Automatic recheck runs immediately after apply so new states are shown without manual refresh

⚠️ **Important**
> This resets saved Explorer folder views. Existing custom folder layouts are removed and replaced with the WindowsAcolyte defaults.

### 🧠 Registry Changes
```reg
HKCU:\...\Shell\Bags\AllFolders\Shell\*
  LogicalViewMode  = 1
  Mode             = 4
  GroupView        = 0
  GroupBy          = ""
  GroupByKey:PID   = 0
  GroupByDirection = 1
  Sort             = Name ascending (REG_BINARY)
  ColInfo          = Name, Date modified, Type, Size (REG_BINARY)
  FolderType       = NotSpecified

HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced
  Hidden           = 1
  HideFileExt      = 0
  ShowSuperHidden  = 0
  UseCompactMode   = 0
  UseAutoGrouping  = 0
```

---

## 🧪 3. Hardware Inventory
> **Category:** Diagnostics
> **Admin:** ⚠️ Yes

<img src="https://raw.githubusercontent.com/ReAlNoMo/WindowsAcolyte/main/screenshots/03-hardware-inventory.png" alt="Hardware Inventory module" width="720">

### ✔ What it does
- System / Mainboard info (manufacturer, model, BIOS version and date)
- CPU details (cores, clock speed, socket, cache sizes, driver version)
- RAM slots (capacity, speed, manufacturer, part number, serial number)
- GPU (VRAM, resolution, driver version and date)
- Storage drives and logical partitions (size, free space, file system)
- Network adapters (MAC, driver, IP address)
- Audio devices with driver info
- Full PnP driver list (sortable by class and device name)
- Styled **HTML report** saved to the Desktop
- Background processing with progress bar

📄 **Output**
```
Desktop\Hardware_Report_YYYY-MM-DD_HH-MM.html
```

### ✨ Features
- Dark-themed HTML report
- Sortable tables
- Activity log with timestamps
- Re-open last report button
- Concurrent background processing

🪶 **Windows changes:** None (read-only)

---

## 🧱 4. Sandboxie Browser Launcher
> **Category:** Security
> **Admin:** ❌ No

<img src="https://raw.githubusercontent.com/ReAlNoMo/WindowsAcolyte/main/screenshots/04-sandboxie-browser-launcher.png" alt="Sandboxie Browser Launcher module" width="720">

### ✔ What it does
- Launch browsers sandboxed via Sandboxie-Plus
- Private / Incognito mode per browser
- Auto-detect installed browsers on launch
- 6 supported browsers
- Configurable sandbox name
- Prerequisite check (Sandboxie-Plus + each browser)
- Status display and activity log

### 🌐 Supported Browsers

| Browser | Incognito | Private Mode | Auto-Detect |
|---------|-----------|--------------|------------|
| Chrome | ✅ | N/A | ✅ |
| Chromium | ✅ | N/A | ✅ |
| Firefox | N/A | ✅ | ✅ |
| Brave | ✅ | N/A | ✅ |
| Vivaldi | N/A | ✅ | ✅ |
| LibreWolf | N/A | ✅ | ✅ |

⚠️ **Requirements**
- Sandboxie-Plus installed
- At least one supported browser installed

### 🧠 UI Features
- ✅ One button per browser (auto-disabled if not installed)
- ✅ Configurable sandbox name field
- 🔍 Prerequisite check on load (Sandboxie-Plus + all browsers)
- 🪵 Activity log

💡 **Use case**
> Safely browse untrusted websites, test malware links, isolate browsing activity

---

## 🎮 5. Windows 11 Gaming Optimizer
> **Category:** Gaming Performance
> **Admin:** ⚠️ Yes

<img src="https://raw.githubusercontent.com/ReAlNoMo/WindowsAcolyte/main/screenshots/05-gaming-optimizer.png" alt="Windows 11 Gaming Optimizer module" width="720">

> 🚀 **35 selectable options**: 29 existing tweaks + 6 optional input/USB settings, with verified configuration readback. Additional controls offer custom desktop pointer speed and local Windows Update status.

---

### 🔥 High Impact Tweaks

| Tweak | Effect | Reboot | Risk |
|------|--------|--------|------|
| HVCI Disable | 🚀 Up to +25% FPS | ✅ Yes | 🔴 High |
| VBS Disable | 🚀 +2-8% FPS | ✅ Yes | 🔴 High |
| GPU Scheduling | ⏱️ -2ms latency | ✅ Yes | 🟢 Low |
| GameDVR Disable | 🚀 +2-5% FPS | ✅ Yes | 🟢 Low |
| Spectre/Meltdown Disable | ⚡ +5-15% CPU | ✅ Yes | 🔴 High |
| NVMe Stack Optimization | 💾 Up to 45% less CPU per I/O | ✅ Yes | 🟡 Medium |
| Win32Priority | 🎯 Frame consistency | ❌ No | 🟢 Low |
| Network Throttling Off | 🌐 +10-30ms ping reduction | ❌ No | 🟢 Low |

---

### ⚙️ Complete Tweaks List (35 Selectable Options)

| ID | Option | Configuration checked |
|----|--------|-----------------------|
| 1 | HVCI OFF | HVCI + VBS registry flags |
| 2 | VBS configuration OFF | VBS registry flag; does not remove Virtual Machine Platform |
| 3 | GameDVR recording OFF | User flag + machine policy |
| 4 | Spectre/Meltdown configuration OFF | Override + mask; high risk |
| 5 | Ultimate Performance | Active plan identity |
| 6 | Power throttling OFF | PowerThrottlingOff |
| 7 | System responsiveness 10 | SystemResponsiveness |
| 8 | Network throttling OFF | NetworkThrottlingIndex = 0xFFFFFFFF |
| 9 | Competitive priority | Win32PrioritySeparation = 36 (0x24) |
| 10 | AAA priority | Win32PrioritySeparation = 24 (0x18); alternative to #9 |
| 11 | Startup delay OFF | StartupDelayInMSec |
| 12 | GPU scheduling ON | HwSchMode; runtime support not verified |
| 13 | Game Mode ON | AutoGameModeEnabled |
| 14 | Legacy fullscreen flags | Both GameDVR compatibility flags; not the windowed-games switch |
| 15 | Games scheduling High | Scheduling Category |
| 16 | Nagle/ACK configuration | Three values per active physical Ethernet/Wi-Fi adapter |
| 17 | Advanced TCP configuration | Autotuning, RSS, RSC, ECN, timestamps |
| 18 | Transparency OFF | EnableTransparency |
| 19 | Window animations OFF | MinAnimate |
| 20 | Menu delay 0 | MenuShowDelay |
| 21 | Taskbar animations OFF | TaskbarAnimations |
| 22 | NTFS last-access updates OFF | Numeric NTFS flags, including system-managed states |
| 23 | NTFS 8.3 creation OFF | Global numeric policy = 1 |
| 24 | Experimental NVMe override | Registry override only; build 26100+, driver activation not verified |
| 25 | Paging executive OFF | DisablePagingExecutive |
| 26 | Telemetry policy request | AllowTelemetry + DiagTrack startup/status |
| 27 | Search history OFF | IsDeviceSearchHistoryEnabled |
| 28 | Share across devices OFF | CdpSessionUserAuthzPolicy |
| 29 | Dynamic lighting OFF | Both managed lighting flags |
| 30 | USBHUB3 selective-suspend override (optional) | `DisableSelectiveSuspend` exists as REG_DWORD `1`; driver effect not verified |
| 31 | USB root hubs: prevent power-off (optional) | Every present, supported root hub has `MSPower_DeviceEnable.Enable=False`: **Allow the computer to turn off this device to save power is unchecked** |
| 32 | Filter Keys + activation shortcut OFF (optional) | Live Windows API flags: feature and Right Shift shortcut disabled; original timing preferences preserved |
| 33 | Sticky Keys + activation shortcut OFF (optional) | Live Windows API flags: feature and five-times-Shift shortcut disabled; other persistent preferences preserved |
| 34 | Active-plan USB selective suspend OFF (optional) | Current plan GUID and separate AC/DC indexes, both `0` (Disabled) |
| 35 | Enhance Pointer Precision OFF (optional comfort) | Live Windows mouse acceleration flag `0`; thresholds and pointer speed unchanged |

### Input & USB Stability - Optional

All six options (#30-35) target troubleshooting, prevention of accidental accessibility activation or desktop comfort, not higher FPS. They start unselected and are excluded from **All**, **Missing Only**, **Safe Only** and recommended pre-selection. Select them individually; explicitly saved profiles can also select them. No settings are changed merely by opening the module or checking status.

- **USBHUB3 override (experimental):** sets `HKLM\SYSTEM\CurrentControlSet\Services\USBHUB3\DisableSelectiveSuspend` to DWORD `1`. This exact driver override is not reliably documented across Windows versions. `APPLIED` confirms the stored value/type, not that the driver honors it or disconnects are fixed.
- **Root-hub power permission:** clears the device power-off permission on all currently present USB root hubs with an unambiguous supported WMI provider. Unsupported hubs block Apply before any device write. Other USB devices and wake permissions are untouched; devices are not disabled or reconnected.
- **Filter Keys / Sticky Keys:** separate opt-in options disable the feature and its activation shortcut, with an explicit accessibility warning before Apply. Do not disable assistive features you need. Original Filter Keys timings and unrelated persistent flags are preserved. Live state is read/set using `SystemParametersInfoW` with preference persistence and change notification, not by guessing registry values. Reset restores original preferences; it does not replay transient held/latched modifier keys. No universal raw-input latency improvement is claimed.
- **Active power-plan USB policy:** sets selective suspend to Disabled for both AC and DC and displays current indexes separately. Each edited plan GUID keeps its own baseline across repeated Apply and plan switches. Settings are re-applied if that plan is still active; Reset does not deliberately select an inactive saved plan. Missing plans or partial failures retain the recovery baseline. This policy overlaps the separate Ultimate Performance module: applying that module again can overwrite a restored value. Microsoft recommends leaving selective suspend enabled unless addressing a specific problem.
- **Enhance Pointer Precision:** optional desktop/non-Raw comfort setting only; threshold values and pointer speed remain unchanged. Genuine Raw Mouse Input bypasses Windows pointer ballistics. No FPS, latency or connection gain is claimed.
- Before changing an optional input/USB setting, its original values are saved under `%ProgramData%\WindowsAcolyte\GamingOptimizer`. Machine USB baselines and per-user input baselines are separate; input filenames include the Windows user SID and reject another user's baseline. The target is the user running the elevated app, not every logged-in user. Repeated Apply preserves originals, including after partial failures. Reset restores originals, not guessed defaults. Without an app backup, Reset leaves existing settings unchanged.
- Disconnected hubs retain their backup: reconnect and retry Reset. New hubs require **Recheck All** and explicit Apply. Backups survive app updates; successful full restoration archives the baseline.
- The original USB driver/hub options use the existing reboot prompt; input preferences and power-plan policy do not request a reboot. No USB device restart occurs. None of these options guarantees a cure for faulty cables, drivers or devices.

**Additional explicit controls in this group:**

- **Pointer Speed:** slider `1-20`, initialized from current Windows state. Moving it only selects a target; **Apply Speed** performs the change and verifies readback. **Reset Speed** restores the saved original. This changes desktop/non-Raw speed, not sensor DPI. It is independent of acceleration, excluded from profile save/load, and included in **Reset Managed Settings** only if a baseline exists.
- **Read Local Update Status:** reads Windows version, the most recent successful installation within the last 100 local update-history events, and Windows Update's pending-reboot status. It does not perform an online scan or claim that Windows is fully up to date. Errors remain visibly unknown/unavailable. **Open Windows Update** only opens `ms-settings:windowsupdate`; the tool does not request installation or restart.

No queue-size, HPET, timer, keyboard-repeat or wake-permission tweaks were added, and no background programs or drivers are automatically removed.

API references: [WMI power management](https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/wmi-and-the-power-management-tab), [SystemParametersInfoW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-systemparametersinfow), [local update history](https://learn.microsoft.com/en-us/windows/win32/api/wuapi/nf-wuapi-iupdatesearcher-queryhistory).

---

### 🧠 UI Features
- ✅ Checkbox selection with risk indicators (🟢 SAFE / 🟡 MODERATE / 🔴 HIGH)
- 🔍 Hardware detection (Intel 12+ / AMD Ryzen 5000+ / AMD X3D / NVIDIA)
- ⚠️ X3D CPU auto-detection with Game Mode guidance (not forced)
- 🔍 Status detection (APPLIED / MISSING / ALTERNATIVE / UNAVAILABLE / CHECK ERROR)
- Network throttling status handles both signed and unsigned DWORD representations of `0xFFFFFFFF`
- Numeric NTFS checks avoid language/output-format mismatches; 8.3 policy `1` is correctly recognized as globally disabled
- Multi-value settings verify every managed field; TCP checks all five configured values, and telemetry checks the DiagTrack service too
- Native command exit codes and registry/service errors are checked before reporting success
- Conflicts and reset effects appear directly below options, in selection details and in reset confirmations
- Apply/Reset compares before/after states and logs previously applied options that become inactive
- Bulk selection preserves the active priority preset; unavailable options and failed checks cannot be selected
- 🔄 Re-scan button
- 🪵 Activity log with timestamps & status codes
- 💾 Profile Save/Load (JSON format)
- 🔧 Restore Points auto-creation
- 📋 Registry backup before changes
- 🎨 Dark Mode support
- ✨ Recommended pre-selection based on hardware

---

### 📋 Profile System
- Save current tweak configuration
- Load saved profiles
- Hardware context stored (CPU, GPU, RAM, Build)
- JSON format (human-readable)
- Multiple profiles supported
- JSON numeric IDs are normalized before matching UI controls
- Conflicting priority IDs and malformed profiles are rejected before changing the selection
- Save includes applied settings and pending selections; a pending priority alternative replaces the active one in the profile

---

### ⚠️ Important Notes

> 🔴 **Reboot required** for many tweaks
> 🧠 **AMD X3D CPUs** → Keep Game Mode enabled; its Reset action disables it
> 🔒 **High-Risk tweaks** → User confirmation popup required
> 💾 **Selected backups** → Created before Apply; failed selected backups stop Apply. Restore-point creation is verified (including Windows creation-frequency limits).
> ⚡ **Competitive vs AAA** → Only one Win32Priority mode can be active: Competitive = 36 (`0x24`), AAA = 24 (`0x18`). The other mode is an alternative, not a missing setting; automatic pre-selection preserves the active mode.
> 📊 **Estimates** → FPS gains are approximate; actual results vary per system

`APPLIED` confirms stored configuration, not a measured FPS improvement or proof that a reboot-dependent feature is already effective. The NVMe option only checks an experimental feature override and is never automatically recommended.

HVCI OFF also writes VBS OFF. Resetting either shared security setting can invalidate the other; the UI explains this and logs status changes. Resetting the power-plan option switches to Balanced, including when the separate Ultimate Performance module's plan was active. **Reset Managed Settings** uses documented module presets, not a snapshot of your original Windows configuration; optional input/USB controls are exceptions and restore saved originals only, including custom pointer speed. Accessibility Reset can re-enable previously active assistive features. The 8.3 reset policy is per-volume (`2`).

Validation (PowerShell 7 on Windows):

```powershell
pwsh -NoProfile -STA -File .\tests\Test-GamingOptimizer.ps1
pwsh -NoProfile -STA -File .\tests\Test-GamingOptimizerUsb.ps1
pwsh -NoProfile -STA -File .\tests\Test-GamingOptimizerInput.ps1
pwsh -NoProfile -File .\tests\Test-GamingOptimizerAudit.ps1
pwsh -NoProfile -File .\tests\Test-GamingOptimizerAudit.ps1 -ReadOnly
```

The legacy audit covers 29 Apply/Check/Reset lifecycles and all 812 ordered option pairs for both Apply and Reset in an isolated model. The USB suite separately checks typed registry restoration and supported/disconnected hub behavior. The input suite checks selective accessibility flags/timings, per-user originals, explicit pointer-speed changes, localized power-plan parsing, independent AC/DC baselines across plan switches, partial failures and WPF controls. Registry writes use temporary HKCU keys; device, input and power-plan writes are simulated. Native input reads are checked without changing your preferences. These tests do not establish driver activation, OS-edition support, reboot behavior or performance gains.

Command semantics: [Microsoft fsutil behavior](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/fsutil-behavior), [8.3 policy values](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/fsutil-8dot3name), [powercfg](https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options).

---

### 🔧 Recommended Tools (External)

Integrated recommendations for:
- **ISLC** – Intelligent Standby List Cleaner (very high impact)
- **Process Lasso** – CPU prioritization (Intel 12+/AMD X3D)
- **NVCleanstall** – NVIDIA driver bloatware removal
- **TimerResolution** – Windows timer boost (competitive games)
- **DDU** – Complete driver uninstall
- **MSI Afterburner + RTSS** – FPS limiting to refresh rate -3
- **O&O ShutUp10++** – Privacy & telemetry GUI
- **InSpectre** – CPU mitigation status

---

## ⚡ 6. Ultimate Performance Power Plan
> **Category:** Gaming Performance
> **Admin:** ⚠️ Yes

<img src="https://raw.githubusercontent.com/ReAlNoMo/WindowsAcolyte/main/screenshots/10-ultimate-performance-power-plan.png" alt="Ultimate Performance Power Plan module" width="720">

### ✔ What it does
- Creates a dedicated **WindowsAcolyte Ultimate Performance** power plan from the Windows Ultimate Performance template
- Activates the plan and applies maximum-performance AC/DC settings
- Keeps monitors awake forever (`Turn off display after = Never`)
- Disables sleep, hibernate, hybrid sleep, and hard-disk idle timers
- Sets CPU minimum and maximum processor state to 100%
- Applies aggressive CPU boost, maximum boost policy, performance-first EPP, and core parking disablement where Windows exposes those settings
- Disables PCIe Link State Power Management, USB selective suspend, and wireless adapter power saving
- Sets video playback to quality/performance mode
- Shows the exact `powercfg` subgroup, setting, AC/DC value, and effect before applying
- Includes Recheck, Apply, Set Balanced, and Activity Log actions
- Skips unsupported hardware-specific settings safely and logs them as warnings

⚠️ **Important**
> This profile is built for maximum responsiveness, not battery life. Expect higher idle power use, heat, and fan activity.

---

## 🐧 7. Linux ISO Downloader
> **Category:** Downloader
> **Admin:** ❌ No

<img src="https://raw.githubusercontent.com/ReAlNoMo/WindowsAcolyte/main/screenshots/06-linux-iso-downloader.png" alt="Linux ISO Downloader module" width="720">

### ✔ What it does
- Download latest ISOs from official sources
- Parallel downloads (1–5 concurrent)
- Parent/child distro selection (main distro = all variants, sub-option = single variant)
- Preset buttons for All, Only Server, and Only Desktop selections
- Separate live progress row for every selected ISO
- SHA256 verification (where available)
- Auto mirror fallback
- Resume / skip existing files
- Background processing via ConcurrentQueue + DispatcherTimer

---

### 📦 Supported Distributions

| Distro | Variants | Default | Source |
|--------|----------|---------|--------|
| Ubuntu | Desktop (Consumer), Server | ✅ Both | ubuntu.com |
| Debian | Netinst (Server), Live Desktop | ✅ Both | debian.org |
| Fedora | Workstation (Consumer), Server | ✅ Both | fedoraproject.org |
| Arch Linux | Installer ISO | ✅ | archlinux.org |
| CachyOS | Desktop | ❌ Opt-in | cachyos.org |
| Pop!_OS | Desktop NVIDIA, Desktop Intel/AMD | ❌ Opt-in | pop-os.org |

> Clicking a main distro selects or clears all of its variants. Selecting only a sub-option downloads only that specific ISO. Presets can quickly select all variants, server-oriented ISOs only, or desktop-oriented ISOs only.

---

### ✨ Features
- Overall progress bar plus one persistent progress row per selected ISO
- Speed indicator (MB/s) and ETA
- Queued/running/done/failed/cancelled state per ISO
- Activity log dynamically resizes under the progress area
- Resume / skip existing files
- Activity log
- Mirror failover
- Parallel download control

📁 **Default Output** (Auto-Detected)
```
C:\Users\[CurrentUser]\Downloads\ISOs
```

> ℹ️ Automatically detects the current Windows user — no hardcoded paths

---

## 🦠 8. AV Scanner Downloader
> **Category:** Downloader
> **Admin:** ❌ No

<img src="https://raw.githubusercontent.com/ReAlNoMo/WindowsAcolyte/main/screenshots/07-av-scanner-downloader.png" alt="AV Scanner Downloader module" width="720">

### ✔ What it does
- Download portable AV scanner tools from official vendor servers
- Parallel downloads (1–4 concurrent)
- Background processing via RunspacePool
- Per-file progress tracking with speed and ETA
- MD5/SHA256 verification (where available)
- Live queue-based UI updates

---

### 📦 Supported Scanners

| Scanner | Vendor | Portable | Verification |
|---------|--------|----------|--------------|
| EEK | Emsisoft | ✅ | ✅ MD5 |
| KVRT | Kaspersky | ✅ | ✅ SHA256 |
| AdwCleaner | Malwarebytes | ✅ | ❌ |
| HouseCall | Trend Micro | ✅ | ✅ SHA256 |

---

### ✨ Features
- Per-file speed indicator (MB/s)
- ETA calculation
- Overall progress + file count
- Activity log
- Download coordination
- ConcurrentQueue architecture

📁 **Default Output** (Auto-Detected)
```
C:\Users\[CurrentUser]\Downloads\AVScanners
```

> ℹ️ Automatically detects the current Windows user — portable & flexible

---

### 🏗️ Architecture
- **Orchestrator Pattern**: Isolated RunspacePool per download batch
- **Thread Safety**: ConcurrentQueue for cross-runspace communication
- **UI Updates**: DispatcherTimer-based polling (no blocking)
- **Cancellation**: System.Threading.CancellationToken support

💡 **Use case**
> Bulk download of portable security tools for offline scanning

---

## 🖥️ 9. Desktop Shortcut Creator
> **Category:** Windows Tools
> **Admin:** ❌ No

<img src="https://raw.githubusercontent.com/ReAlNoMo/WindowsAcolyte/main/screenshots/08-desktop-shortcut-creator.png" alt="Desktop Shortcut Creator module" width="720">

### ✔ What it does
- Creates WindowsAcolyte shortcuts on the current user's Desktop
- Supports **Local Start** and **Online Installer** shortcut variants
- Uses English shortcut names:
  - `WindowsAcolyte - Start (Local).lnk`
  - `WindowsAcolyte - Installer (Online).lnk`
- Uses a stable Windows PowerShell shortcut host plus a local bootstrap that resolves PowerShell 7 (`pwsh.exe`) at launch time; Store version updates cannot invalidate the shortcut target
- Uses the dedicated white-background shortcut icon from `logo/Windows_Acolyte_Shortcut_Icon.ico`
- Logs created shortcut paths and missing local install warnings

💡 **Use case**
> Recreate WindowsAcolyte Desktop launch shortcuts directly from the app.

---

## 🧯 10. Rescue ISO Downloader
> **Category:** Downloader
> **Admin:** ❌ No

<img src="https://raw.githubusercontent.com/ReAlNoMo/WindowsAcolyte/main/screenshots/09-rescue-iso-downloader.png" alt="Rescue ISO Downloader module" width="720">

### ✔ What it does
- Downloads current rescue, partitioning, cloning, malware cleanup, RAM test, wipe, and boot repair images
- Keeps stable local filenames like `systemrescue-latest-amd64.iso`
- Replaces older matching files in the destination folder after a successful download
- Supports parallel downloads with one progress row per selected tool
- Extracts ISO files from upstream ZIP packages where required (`Memtest86+`, `Super Grub2 Disk`)
- Uses official project pages, GitHub Releases, SourceForge project pages, and vendor latest URLs

### 📦 Supported Rescue Tools

| Tool | Purpose | Source |
|------|---------|--------|
| SystemRescue | Data rescue and system recovery | system-rescue.org / SourceForge |
| GParted Live | Partitioning | SourceForge |
| Rescuezilla | Backup, restore, clone | GitHub Releases |
| Clonezilla Live | Disk and partition cloning | SourceForge |
| Hiren's BootCD PE | Windows PE repair toolkit | hirensbootcd.org |
| Kaspersky Rescue Disk | Offline malware cleanup | Kaspersky latest URL |
| Avira Rescue System | Offline malware cleanup | Avira latest URL |
| Memtest86+ | RAM testing | memtest.org |
| ShredOS | Secure disk wiping | GitHub Releases |
| Super Grub2 Disk | Boot repair | SourceForge |

📁 **Default Output** (Auto-Detected)
```
C:\Users\[CurrentUser]\Downloads\RescueISOs
```

> ℹ️ Existing older matching ISO files are removed only after the new download has completed successfully.

---

## 🔗 11. Shortcut Arrow Visibility
> **Category:** Windows Tools
> **Admin:** Required

Hides the small shortcut-arrow overlay while retaining each shortcut's icon, target and `.lnk` behavior.

- Checks the native registry view at `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons` and value `29` before making changes.
- **Hide Arrows** creates the key if needed and sets `29` as `REG_SZ`, pointing to `%ProgramData%\WindowsAcolyte\ShortcutArrowOverlay\transparent-arrow.ico,0`.
- Generates a genuine transparent ICO with 16, 24, 32, 48, 64, 128 and 256 px frames; validates it and repairs missing/corrupt managed assets. It does not use an undocumented blank DLL resource index or remove `IsShortcut`.
- Stores the original value, existence and data type in an administrator-protected `original-29.json`. Repeated Apply never replaces that baseline.
- **Restore Previous Setting** reinstates the original value/type. If `29` was originally absent, only that value is removed; the key and unrelated entries are preserved. Restore refuses to overwrite a later external customization.
- Both actions confirm before modifying settings and restarting the current user's desktop Explorer process. Finish file copy/move operations first; Explorer windows may close. Other users' sessions are not restarted.
- **Recheck** reports the stored configuration and asset integrity. **Restart Explorer** allows an explicit refresh/retry without a registry change.

The registry setting is system-wide; other signed-in users need their own Explorer restart or sign-out/in. A configured value is not proof of the visual result: Windows builds, policies and icon caching can affect the overlay. If necessary, sign out/in. No icon-cache databases are deleted. If restart verification fails after Apply, the saved setting remains and the log explains the next step.

Assets and backup live outside the installation directory so app updates cannot remove the referenced icon. After Restore, the previous backup is archived as `restored-29-*.json`; a future Apply captures a fresh baseline. Do not delete the managed ICO while value `29` references it.

Validation:

```powershell
pwsh -NoProfile -STA -File .\tests\Test-ShortcutArrowVisibility.ps1
```

Tests use a temporary HKCU key and temporary files, verify typed backup/restore and all ICO frames, load the actual WPF view, and simulate restart orchestration. They do not change the real HKLM value or restart your desktop. APIs: [explicit registry views](https://learn.microsoft.com/en-us/dotnet/api/microsoft.win32.registrykey.openbasekey), [desktop shell identification](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getshellwindow).

---

# 🛠️ Installation (Manual)

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install.ps1
```

📁 Install location:
```
%LOCALAPPDATA%\WindowsAcolyte
```

---

# 🧹 Uninstall

If Shortcut Arrow Visibility was applied, use **Restore Previous Setting** before uninstalling to restore the original overlay. Removing the app alone intentionally leaves the ProgramData icon/backup intact so a still-configured `29` does not reference a deleted file.

If optional Gaming Optimizer input/USB settings were changed through the app, use their **Reset** buttons before uninstalling when you want the original preferences back, including **Reset Speed** for custom pointer speed. Uninstalling does not restore system settings or remove protected ProgramData baselines. Reconnect missing hubs and restore missing power plans before completing Reset; user preferences must be restored from the original Windows account.

```powershell
Remove-Item "$env:LOCALAPPDATA\WindowsAcolyte" -Recurse -Force
```

Remove from PowerShell profile:
```
$PROFILE
```

---

# 🧩 Custom Modules

📄 File naming:
```
modules/NN-Name.ps1
```

### 🧠 Template

```powershell
Register-PowerToolsModule `
    -Id "custom-id" `
    -Name "Custom Module" `
    -Description "What it does" `
    -Category "Category" `
    -RequiresAdmin $false `
    -Show { }
```

### ✔ Best Practices
- Inline XAML only
- Logging with timestamps + status codes
- Try/Catch everywhere
- Use dynamic theme brushes (`$Global:PTS_Brush`)
- Background processing for long tasks
- ConcurrentQueue for thread-safe communication

---

# 🧯 Troubleshooting

| Problem | Solution |
|--------|---------|
| PowerShell 7 missing | Install from aka.ms/powershell |
| Command not found | Restart terminal |
| ExecutionPolicy error | Set RemoteSigned |
| Modules missing | Check `/modules` folder |
| Gaming tweaks missing | Run as Admin |
| Logo color wrong | Toggle dark mode |
| ISO path invalid | Uses auto-detected `Downloads\ISOs` folder |
| Browser buttons greyed out | Browser or Sandboxie-Plus not installed |

---

# 🧩 Compatibility

| Component | Requirement |
|----------|------------|
| PowerShell | 7.0+ |
| Windows | 10 / 11 |
| WPF | Required |
| Display | 1024×600+ |
| Download modules | .NET HttpClient (built-in) |

---

# 📋 Version History

## v1.6 (Current)
- ✅ 11 modules available
- ✅ Shortcut Arrow Visibility: precheck, transparent multi-size ICO, typed original-value backup/restore and current-session Explorer restart
- ✅ Ultimate Performance Power Plan: creates a dedicated WindowsAcolyte power plan, activates it, disables monitor standby/sleep/disk idle, and enforces maximum CPU/PCIe/USB/WLAN performance settings
- ✅ Rescue ISO Downloader: latest rescue/partition/cloning/malware/memory/wipe/boot images with replacement cleanup
- ✅ Dynamic Light/Dark theme (all 50+ colors)
- ✅ Logo updated to `logo/Windows_Acolyte_Logo.png`
- ✅ Windows icon generated from the logo as `logo/Windows_Acolyte_Icon.ico`
- ✅ Desktop shortcut icon uses white background via `logo/Windows_Acolyte_Shortcut_Icon.ico`
- ✅ Theme colors aligned with the logo palette
- ✅ Explorer View Normalizer: checkbox UI, grouped state view, apply/revert, auto-recheck, small desktop icons
- ✅ Linux ISO Downloader: distro variant selection, All/Only Server/Only Desktop presets, and one progress row per ISO
- ✅ Active operation guard: downloads/hash/report jobs survive theme changes and warn before module switches or app close
- ✅ Desktop Shortcut Creator: local start and online installer links from Windows Tools
- ✅ Desktop shortcuts use a stable Windows PowerShell host and resolve PowerShell 7 dynamically at launch, avoiding versioned Microsoft Store executable paths
- ✅ Shortcut launch paths cleaned up without `-NoExit`
- ✅ Gaming Optimizer: 35 selectable options + profiles; optional Input & USB Stability group, per-user accessibility/desktop comfort backups, per-plan AC/DC USB policy, explicit pointer-speed control and local Windows Update status
- ✅ AV Scanner: RunspacePool orchestration
- ✅ All modules use PTS_Brush theming
- ✅ Background processing via DispatcherTimer
- ✅ ConcurrentQueue for thread-safe communication
- ✅ Window starts maximized

---

# ⚠️ Disclaimer

> 🚨 **Use at your own risk**

This software is provided **"as is"**, without any warranties of any kind, express or implied, including but not limited to functionality, reliability, security, or compatibility.

By using this software, you agree that:
- All actions are performed **at your own risk**
- System-level modifications (registry, performance tweaks, etc.) may cause issues
- You are responsible for **backups and system protection**

To the fullest extent permitted by law, the author shall **not be liable for any damages**, including but not limited to data loss, system instability, hardware damage, security vulnerabilities, or indirect/consequential damages.

💡 **Recommendation:** Test in a VM or secondary system before applying changes.

---

# 📜 License
MIT

---

# 👤 Author
**ReAlNoMo**
Version 1.5 • May 2026

---

## 🔗 Repository
https://github.com/ReAlNoMo/WindowsAcolyte
