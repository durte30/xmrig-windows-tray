# XMRig Windows Tray & Live Thread Switcher

A lightweight, zero-UAC system tray controller and GUI installer for **XMRig** on Windows.

Designed for miners who want clean, native Windows control over XMRig without keeping a heavy wrapper open—and without dealing with User Account Control (UAC) popups every time they start, stop, or adjust CPU thread usage.

---

## ✨ Features

* **One-Click GUI Installer (`Install.bat`)**: Automatically detects your CPU model and logical thread count, pre-filling smart 25%, 50%, 75%, and 100% thread presets (fully customizable during setup).
* **Zero-UAC Admin Execution**: Registers elevated Windows Task Scheduler tasks (`StartXMRig` and `StopXMRig`) so XMRig always launches silently (`-B`) with Administrator privileges for **MSR mod** and **Huge Pages**—with zero UAC prompts.
* **Live Thread Switching**: Right-click the XMRig icon in your Windows System Tray (Notification Area) to switch thread counts on the fly (e.g., drop to 4 or 8 threads while gaming or working, then jump back to 16 threads when idle).
* **Live Log Viewer**: Click **View Live Log** at the top of the tray menu to open a real-time console stream (`xmrig.log`). Closing the log window leaves XMRig running quietly in the background.
* **Taskbar / Start Menu Toggle**: Creates a **Toggle XMRig** Desktop shortcut (complete with the XMRig icon) that can be pinned directly to your Windows Taskbar for one-click start/stop control.
* **Plug-and-Play for GUPAX Switchers**: Already have a tuned `config.json`? The installer preserves your settings. Starting fresh without a `config.json`? The installer prompts for your pool URL and wallet/worker name and generates a pre-tuned `config.json` automatically.
* **Optional Start on Login**: Includes a one-click option to launch XMRig and the system tray icon automatically whenever you sign into Windows.

<img width="356" height="204" alt="XMR_TrayIcon_Hover" src="https://github.com/user-attachments/assets/a7126812-6a7f-4f8f-ac8b-f13c496b7ad0" />

<img width="475" height="305" alt="XMR_TrayIcon_RightClick" src="https://github.com/user-attachments/assets/21f49d0d-fb09-4eaf-9443-23686fd960ec" />

---

## 📋 Prerequisites

* **Windows 10 or Windows 11** (uses built-in PowerShell and Windows Forms—no third-party runtimes or dependencies required).
* **XMRig for Windows** (`xmrig.exe`), downloaded from the official [XMRig Releases](https://github.com) page.

---

## 🚀 Quick Start / Installation

1. Download or clone this repository and place **`Install.bat`** and **`Install-XMRigTray.ps1`** in the same folder.
2. Double-click **`Install.bat`** and click **Yes** on the single Administrator prompt.
3. In the installer window:
   * **Folder**: Browse to the folder containing your `xmrig.exe`.
   * **Thread Profiles**: Keep the auto-detected presets or enter your own comma-separated thread counts (e.g., `4, 8, 12, 16`).
   * **Options**: Choose whether to add a Windows Defender folder exclusion, create a Desktop toggle shortcut, or auto-start on Windows login.
4. Click **Install XMRig Tray**.

> **Note:** If your XMRig folder does not contain a `config.json` yet, the installer will ask for your **Pool URL** (e.g., `127.0.0.1:3333`) and **Monero Wallet Address / Worker Name**, then generate a ready-to-mine `config.json` automatically.

<img width="543" height="425" alt="XMR_TrayIcon_Installer" src="https://github.com/user-attachments/assets/5adf9444-706a-4564-a618-7db3b7c6890e" />

---

## 🖥️ Usage

### Starting & Stopping XMRig
* Double-click the **Toggle XMRig** shortcut on your Desktop (or right-click it → **Pin to taskbar** for single-click access).
* If XMRig is stopped, it starts XMRig silently in the background and spawns the orange XMRig icon in your System Tray.
* If XMRig is already running, clicking the toggle stops it cleanly and closes the tray icon.

### System Tray Right-Click Menu
While XMRig is running, right-click the **XMRig icon** in your Windows System Tray (Notification Area) to:
* **View Live Log**: Opens a live-updating terminal window showing XMRig's hashrate, accepted shares, and status.
* **Switch to X Threads**: Updates `"rx"` thread affinity in `config.json` and restarts XMRig cleanly with the selected thread count. A checkmark (`✓`) indicates the currently active thread profile.
* **Stop XMRig**: Stops the miner and removes the tray icon.

<img width="1253" height="869" alt="XMR_TrayIcon_Log" src="https://github.com/user-attachments/assets/18791f3d-c212-43a3-ad37-b594327fa0f5" />

---

## ⚙️ How It Works Under the Hood

* **`StartXMRig` & `StopXMRig` Scheduled Tasks**: Running `xmrig.exe` with `RunLevel Highest` via Task Scheduler grants hardware MSR and Huge Pages access without triggering UAC dialogs on every launch.
* **BOM-Free UTF-8 JSON Handling**: PowerShell's default UTF-8 encoding includes a Byte Order Mark (BOM) that breaks XMRig's JSON parser. `XMRigTray.ps1` uses `[System.IO.File]::WriteAllText()` to write clean, standard UTF-8 without a BOM and sets `"autosave": false` so your custom thread profiles are never overwritten.
* **Auto-Cleanup**: A lightweight background timer checks every 3 seconds if `xmrig.exe` is still active; if XMRig is stopped externally, the tray icon cleans itself up automatically.

---

## 🧹 Uninstalling

To remove the tray controller and scheduled tasks:
1. Stop XMRig via the tray icon or **Toggle XMRig** shortcut.
2. Delete `ToggleXMRig.bat`, `XMRigTray.ps1`, and `xmrig.log` from your XMRig folder (plus the Desktop shortcut if created).
3. Open **PowerShell as Administrator** and run:
   ```powershell
   Unregister-ScheduledTask -TaskName "StartXMRig" -Confirm:\$false -ErrorAction SilentlyContinue
   Unregister-ScheduledTask -TaskName "StopXMRig" -Confirm:\$false -ErrorAction SilentlyContinue
   Unregister-ScheduledTask -TaskName "StartXMRigOnLogon" -Confirm:\$false -ErrorAction SilentlyContinue
