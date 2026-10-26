# WindowsAcolyte - Project Overview

Current version: `v1.7.4` (2026-10-26).

This overview accompanies the [main README](https://github.com/ReAlNoMo/WindowsAcolyte/blob/main/README.md). Paths below are relative to the Git repository root. The local workspace also keeps a matching copy of this overview one directory above the checkout.

## Overview

WindowsAcolyte is a Windows PowerShell 7 + WPF desktop toolkit for administration, diagnostics, controlled system tuning and downloads. The shell dynamically loads twelve modules from `modules/*.ps1`. The application self-elevates; individual module metadata still describes which operations need administrator rights.

## Features and modules

| Module | Category | Purpose |
|---|---|---|
| Hash Verifier | Security | File hashes and expected-hash comparison |
| Explorer View Normalizer | Windows Tools | Compose Explorer settings, grouped state readback, apply/revert, optional small desktop icons |
| Hardware Inventory | Diagnostics | CIM/WMI inventory and desktop HTML report |
| Sandboxie Browser Launcher | Security | Detect browsers and Sandboxie, start supported browsers sandboxed |
| Windows 11 Gaming Optimizer | Gaming Performance | 35 selectable settings, profiles, backup/reset, optional input/USB controls and read-only Windows Update history |
| Linux ISO Downloader | Downloader | Distro variants, desktop/server presets, per-ISO progress, parallel downloads and fallback |
| AV Scanner Downloader | Downloader | Portable scanner downloads, source checks and progress |
| Desktop Shortcut Creator | Windows Tools | Stable Windows PowerShell desktop links to the update-aware starter |
| Rescue ISO Downloader | Downloader | Recovery, partitioning, cloning, malware, memory-test, wiping and boot-repair images |
| Ultimate Performance Power Plan | Gaming Performance | Dedicated plan and explicit AC/DC processor, display and device settings |
| Shortcut Arrow Visibility | Windows Tools | Overlay precheck, typed original-state backup, transparent ICO and restore |
| Recommended Tools | Gaming Performance | Thirteen entries grouped into GPU/drivers, CPU/RAM, monitor/mouse, diagnostics, audio and Windows utilities; Equalizer APO + Peace has separate official project links |

The shell supports Light/Dark themes, category tiles, JSONL exception logging and an active-operation guard for downloads/hash/report work during theme changes, navigation and app close. Documentation screenshots may show an earlier version.

## Tech stack and architecture

- App: PowerShell 7+, WPF (`PresentationFramework`, `PresentationCore`, `WindowsBase`) and Windows APIs.
- Starter: Windows PowerShell 5.1 or PowerShell 7; Windows Forms provides visible update status and failure messages.
- Long-running modules: runspaces/runspace pools, `ConcurrentQueue` and WPF `DispatcherTimer` polling.
- System integration: Registry APIs/providers, CIM/WMI, native input APIs and `powercfg`.
- No package-manager dependencies, `.env`, database, web server or separate build step are required.

Shortcut startup sequence:

1. Stable Windows PowerShell host runs the installed `Start-WindowsAcolyte.ps1`.
2. Acquire the per-installation update lock; resolve the current GitHub `main` commit and its complete tree.
3. Compare local managed-file Git blob hashes. Stage missing/changed files from that immutable commit and verify hashes and syntax with the PowerShell 7 app runtime; also validate the starter against its current host.
4. Back up destinations, apply the update, verify copied files and write `.installed-release.json`. Failed application rolls back earlier writes; incomplete recovery retains backup files and blocks launch.
5. Only after a successful online check, resolve PowerShell 7 and start the app. Offline/API/download/update failures block startup with a visible message.
6. App checks PowerShell 7, elevates if needed, loads WPF assemblies/themes/modules, then renders category navigation.

Directly running `WindowsAcolyte.ps1` is a developer path and bypasses the shortcut's update gate. Use the starter or desktop link for the checked user launch.

Each module calls `Register-PowerToolsModule` with an ID, name, description, category, administrator metadata and a `-Show` scriptblock returning the WPF view. Module source filenames are discovered automatically; no static module list needs editing.

## Project structure

```text
WindowsAcolyte.ps1              App shell, themes, navigation, logging
Start-WindowsAcolyte.ps1        Online update gate and local startup
README.md                      User guide and version history
docs/README.md                 This architecture/operator overview
modules/                       Twelve PowerShell modules, 01 through 12
tests/                         Seven standalone PowerShell test scripts
logo/                          Logo and app/shortcut ICO assets
screenshots/                   README illustrations, not installed
.github/ISSUE_TEMPLATE/        GitHub issue templates
CONTRIBUTING.md                 Contribution conventions and completion checks
SECURITY.md / DISCLAIMER.md    Security policy and operating risks
LICENSE / CODE_OF_CONDUCT.md   License and community rules
pull_request_template.md        Pull request guidance
```

The installer name used in older documentation, `install.ps1`, is no longer present. `Start-WindowsAcolyte.ps1` installs/repairs/updates the app and then starts it.

## Installation and CLI

Install PowerShell 7 separately if missing; the starter does not download the runtime.

```powershell
irm "https://raw.githubusercontent.com/ReAlNoMo/WindowsAcolyte/main/Start-WindowsAcolyte.ps1" | iex
```

From the repository root, install/update and launch the local installation:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\Start-WindowsAcolyte.ps1
```

Perform the identical online check/update without launching the app:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "$env:LOCALAPPDATA\WindowsAcolyte\Start-WindowsAcolyte.ps1" -UpdateOnly
```

`-OnlineInstaller` is retained for existing online-installer links; it uses the same update-and-start path. There is no offline bypass option. `-UpdateOnly` reports the revision and changed/removed file counts; it exits with an error if the check fails.

Developer launch of the checkout, without overwriting it with remote application files:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -STA -File .\WindowsAcolyte.ps1
```

Create desktop shortcuts in **Windows Tools > Desktop Shortcut Creator**. Both link variants run the canonical checked starter. The existing **WindowsAcolyte - Start (Local)** link remains usable after updates.

## Configuration and persistence

| Location or variable | Purpose |
|---|---|
| `%LOCALAPPDATA%\WindowsAcolyte` | Installed app, modules, logos and both READMEs |
| `.installed-release.json` inside installation | Last verified GitHub revision, UTC check time and managed-file list |
| `.update.lock` / `.updates` inside installation | Update serialization and staging/rollback workspace |
| `logs/errors-YYYY-MM-dd.jsonl` inside app directory | Structured exception logs |
| `%LOCALAPPDATA%\WindowsAcolyte\GamingOptimizer` | Gaming optimizer profile JSON files |
| `%ProgramData%\WindowsAcolyte\GamingOptimizer` | Saved original optional input/USB settings, including user-SID-scoped input backups |
| `%ProgramData%\WindowsAcolyte\ShortcutArrowOverlay` | Protected transparent ICO and original typed overlay value |
| `%USERPROFILE%` and Desktop/Downloads folders | Default report and downloader destinations |

There are no application API keys or secrets to configure. The updater uses public GitHub HTTPS endpoints (`api.github.com` and `raw.githubusercontent.com`). The managed-file allowlist covers the app, starter, both READMEs, module scripts and logo PNG/ICO/SVG assets. Profiles, logs, backups and untracked custom modules are retained. Previously tracked managed files removed from GitHub are removed locally. Other policy/developer documents remain available in the repository rather than being installed.

## Development and testing

Edit the checkout and launch it directly for development. Preserve control names/event wiring, module registration and Light/Dark resources. Add modules through the existing registry contract. Use isolated test storage and mocked system-write APIs where possible; do not assume registry readback proves runtime performance.

From the repository root:

```powershell
pwsh -NoProfile -STA -File .\tests\Test-GamingOptimizer.ps1
pwsh -NoProfile -STA -File .\tests\Test-GamingOptimizerAudit.ps1
pwsh -NoProfile -STA -File .\tests\Test-GamingOptimizerInput.ps1
pwsh -NoProfile -STA -File .\tests\Test-GamingOptimizerUsb.ps1
pwsh -NoProfile -STA -File .\tests\Test-ShortcutArrowVisibility.ps1
pwsh -NoProfile -STA -File .\tests\Test-RecommendedTools.ps1
pwsh -NoProfile -File .\tests\Test-LocalUpdater.ps1
powershell.exe -NoProfile -File .\tests\Test-LocalUpdater.ps1
```

These scripts cover isolated temporary HKCU/file IO, simulated system writes/hub providers/power plans, WPF views and link routing, plus updater online-check gating, changed/missing files, document synchronization, corrupt downloads, syntax errors, locks and rollback. They do not establish full live hardware, driver, download-source or game-performance correctness. `Test-GamingOptimizerAudit.ps1 -ReadOnly` additionally reads production status from the current machine.

## Build and deployment

No compilation or bundling is required. Publish reviewed scripts/docs to GitHub `main`. Then run the installed starter with `-UpdateOnly` and verify its recorded revision against GitHub. The updater installs each selected file from a single immutable commit, including its own starter. Module additions therefore become available on the next checked launch.

Before declaring work finished, review the app/UI version and current-version text, relevant README sections, version history and support policy; run tests appropriate to the change; commit/push authorized changes; update the local installation; compare the remote commit and installed file/document hashes. The outer local overview must match this published overview. State any unverified live behavior explicitly. Functional releases receive an appropriate version bump; documentation-only edits do not automatically require another release number.

## Troubleshooting and recovery

- **Startup blocked:** check connectivity to GitHub, proxy/firewall and API rate limits, then retry. A failed online check deliberately does not start an older app silently.
- **PowerShell 7 missing:** install it from [Microsoft](https://aka.ms/powershell), then retry the same desktop link.
- **Module missing:** check the installed module file, last verified revision, registration and JSONL error log. Modules are loaded when the app starts; close and reopen an already running app after synchronization.
- **Locked destination:** close the process holding that file and retry. A failed update must not start the app; incomplete rollback reports its retained recovery directory.
- **No longer needed:** use the relevant Reset/Restore action before uninstalling if you want original system settings restored. Deleting the app does not undo registry, device, input or power-plan changes.
- **Downloaders fail:** verify destination permissions and current upstream availability. Their sources are independent of the GitHub app-update check.

## Security and limitations

The application runs elevated and includes security-impacting and experimental tweaks. Read the per-setting warnings, preserve backups and test controlled changes. `APPLIED` verifies stored configuration, not a measured FPS/latency improvement or reboot completion. External tool cards open publisher pages; they do not install tools. A prominent English warning panel above the list distinguishes third-party responsibility, external privacy/download conditions and statutory liability limits. Its gold border, warning icon and explicit heading remain visible in both themes. The report button opens GitHub Issues without submitting a report; use the private route in SECURITY.md for sensitive security details.

The update path trusts this project's GitHub repository over HTTPS and checks Git blob identity; it is not an independent signed-release verification system. Public GitHub availability and rate limits affect launch. GitHub tags/releases are separate from source-version text; updating `main` does not create a GitHub Release automatically. Screenshots are illustrative and are not regenerated with every release.

## Contributing and license

See [CONTRIBUTING.md](https://github.com/ReAlNoMo/WindowsAcolyte/blob/main/CONTRIBUTING.md), [CODE_OF_CONDUCT.md](https://github.com/ReAlNoMo/WindowsAcolyte/blob/main/CODE_OF_CONDUCT.md), [SECURITY.md](https://github.com/ReAlNoMo/WindowsAcolyte/blob/main/SECURITY.md) and the pull request template. The project uses the MIT license.
