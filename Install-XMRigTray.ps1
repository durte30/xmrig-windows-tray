# Self-elevate to Administrator if not already running as Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Auto-detect CPU threads and build smart default presets (25%, 50%, 75%, 100%)
$CpuInfo = Get-CimInstance Win32_Processor | Select-Object -First 1
$TotalThreads = [int]$CpuInfo.NumberOfLogicalProcessors
if ($TotalThreads -lt 4) { $TotalThreads = 4 }

$Presets = @(
    [math]::Max(1, [math]::Floor($TotalThreads * 0.25)),
    [math]::Max(2, [math]::Floor($TotalThreads * 0.50)),
    [math]::Max(3, [math]::Floor($TotalThreads * 0.75)),
    $TotalThreads
) | Select-Object -Unique
$DefaultPresetStr = ($Presets -join ", ")

# Build Installer GUI Form
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "XMRig Tray & Thread Switcher Installer"
$Form.Size = New-Object System.Drawing.Size(500, 370)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $false

$FontBold = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$FontReg  = New-Object System.Drawing.Font("Segoe UI", 9)

$LblFolder = New-Object System.Windows.Forms.Label
$LblFolder.Text = "1. Select Folder Containing xmrig.exe:"
$LblFolder.Font = $FontBold
$LblFolder.Location = New-Object System.Drawing.Point(20, 20)
$LblFolder.AutoSize = $true
$Form.Controls.Add($LblFolder)

$TxtFolder = New-Object System.Windows.Forms.TextBox
$TxtFolder.Font = $FontReg
$TxtFolder.Location = New-Object System.Drawing.Point(20, 45)
$TxtFolder.Size = New-Object System.Drawing.Size(360, 24)
if (Test-Path "C:\XMR\Xmrig\xmrig.exe") { $TxtFolder.Text = "C:\XMR\Xmrig" }
$Form.Controls.Add($TxtFolder)

$BtnBrowse = New-Object System.Windows.Forms.Button
$BtnBrowse.Text = "Browse..."
$BtnBrowse.Font = $FontReg
$BtnBrowse.Location = New-Object System.Drawing.Point(390, 44)
$BtnBrowse.Size = New-Object System.Drawing.Size(75, 25)
$BtnBrowse.Add_Click({
    $Browser = New-Object System.Windows.Forms.FolderBrowserDialog
    $Browser.Description = "Select the folder containing xmrig.exe"
    if ($Browser.ShowDialog() -eq "OK") { $TxtFolder.Text = $Browser.SelectedPath }
})
$Form.Controls.Add($BtnBrowse)

$LblCpu = New-Object System.Windows.Forms.Label
$LblCpu.Text = "2. Detected CPU: $($CpuInfo.Name.Trim()) ($TotalThreads Logical Threads)"
$LblCpu.Font = $FontBold
$LblCpu.Location = New-Object System.Drawing.Point(20, 90)
$LblCpu.AutoSize = $true
$Form.Controls.Add($LblCpu)

$LblThreads = New-Object System.Windows.Forms.Label
$LblThreads.Text = "3. Tray Menu Thread Profiles (comma-separated, max $TotalThreads):"
$LblThreads.Font = $FontBold
$LblThreads.Location = New-Object System.Drawing.Point(20, 130)
$LblThreads.AutoSize = $true
$Form.Controls.Add($LblThreads)

$TxtThreads = New-Object System.Windows.Forms.TextBox
$TxtThreads.Font = $FontReg
$TxtThreads.Location = New-Object System.Drawing.Point(20, 155)
$TxtThreads.Size = New-Object System.Drawing.Size(445, 24)
$TxtThreads.Text = $DefaultPresetStr
$Form.Controls.Add($TxtThreads)

$ChkDefender = New-Object System.Windows.Forms.CheckBox
$ChkDefender.Text = "Add Windows Defender folder exclusion (recommended)"
$ChkDefender.Font = $FontReg
$ChkDefender.Checked = $true
$ChkDefender.Location = New-Object System.Drawing.Point(20, 195)
$ChkDefender.AutoSize = $true
$Form.Controls.Add($ChkDefender)

$ChkShortcut = New-Object System.Windows.Forms.CheckBox
$ChkShortcut.Text = "Create 'Toggle XMRig' Desktop shortcut (right-click it to Pin to Taskbar)"
$ChkShortcut.Font = $FontReg
$ChkShortcut.Checked = $true
$ChkShortcut.Location = New-Object System.Drawing.Point(20, 222)
$ChkShortcut.AutoSize = $true
$Form.Controls.Add($ChkShortcut)

$ChkStartup = New-Object System.Windows.Forms.CheckBox
$ChkStartup.Text = "Start XMRig + Tray Icon automatically when I log into Windows"
$ChkStartup.Font = $FontReg
$ChkStartup.Checked = $false
$ChkStartup.Location = New-Object System.Drawing.Point(20, 249)
$ChkStartup.AutoSize = $true
$Form.Controls.Add($ChkStartup)

$BtnInstall = New-Object System.Windows.Forms.Button
$BtnInstall.Text = "Install XMRig Tray"
$BtnInstall.Font = $FontBold
$BtnInstall.Location = New-Object System.Drawing.Point(160, 288)
$BtnInstall.Size = New-Object System.Drawing.Size(160, 32)
$Form.Controls.Add($BtnInstall)
function Show-InputBox {
    param([string]$Title, [string]$Prompt, [string]$DefaultValue = "")
    $InputForm = New-Object System.Windows.Forms.Form
    $InputForm.Text = $Title
    $InputForm.Size = New-Object System.Drawing.Size(460, 175)
    $InputForm.StartPosition = "CenterParent"
    $InputForm.FormBorderStyle = "FixedDialog"
    $InputForm.MaximizeBox = $false
    $InputForm.MinimizeBox = $false

    $Lbl = New-Object System.Windows.Forms.Label
    $Lbl.Text = $Prompt
    $Lbl.Location = New-Object System.Drawing.Point(15, 15)
    $Lbl.Size = New-Object System.Drawing.Size(415, 35)
    $InputForm.Controls.Add($Lbl)

    $Txt = New-Object System.Windows.Forms.TextBox
    $Txt.Text = $DefaultValue
    $Txt.Location = New-Object System.Drawing.Point(15, 55)
    $Txt.Size = New-Object System.Drawing.Size(415, 24)
    $InputForm.Controls.Add($Txt)

    $BtnOk = New-Object System.Windows.Forms.Button
    $BtnOk.Text = "OK"
    $BtnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $BtnOk.Location = New-Object System.Drawing.Point(270, 95)
    $InputForm.Controls.Add($BtnOk)

    $BtnCancel = New-Object System.Windows.Forms.Button
    $BtnCancel.Text = "Cancel"
    $BtnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $BtnCancel.Location = New-Object System.Drawing.Point(355, 95)
    $InputForm.Controls.Add($BtnCancel)

    $InputForm.AcceptButton = $BtnOk
    $InputForm.CancelButton = $BtnCancel

    if ($InputForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return $Txt.Text.Trim() }
    return $null
}

$BtnInstall.Add_Click({
    $Dir = $TxtFolder.Text.Trim().TrimEnd('\')
    $ExePath = Join-Path $Dir "xmrig.exe"
    $CfgPath = Join-Path $Dir "config.json"

    if (-not (Test-Path $ExePath)) {
        [System.Windows.Forms.MessageBox]::Show("Could not find xmrig.exe in:`n$Dir", "Missing xmrig.exe", "OK", "Error")
        return
    }

    $ThreadList = @()
    foreach ($Part in ($TxtThreads.Text -split ',')) {
        $Trimmed = $Part.Trim()
        if ($Trimmed -match '^\d+$') {
            $Num = [int]$Trimmed
            if ($Num -ge 1 -and $Num -le $TotalThreads) { $ThreadList += $Num }
        }
    }
    $ThreadList = $ThreadList | Sort-Object -Unique
    if ($ThreadList.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please enter at least one valid thread count between 1 and $TotalThreads.", "Invalid Thread Counts", "OK", "Error")
        return
    }

    try {
        if (-not (Test-Path $CfgPath)) {
            $PoolUrl = Show-InputBox -Title "New XMRig Config (1/2)" -Prompt "No config.json found! Enter your P2Pool / Pool URL (e.g., 127.0.0.1:3333):" -DefaultValue "127.0.0.1:3333"
            if ([string]::IsNullOrWhiteSpace($PoolUrl)) { return }

            $WalletAddr = Show-InputBox -Title "New XMRig Config (2/2)" -Prompt "Enter your Monero Wallet Address (or Worker Name if mining to local P2Pool):" -DefaultValue "x"
            if ([string]::IsNullOrWhiteSpace($WalletAddr)) { return }

            $NewConfig = [ordered]@{
                "autosave" = $false
                "log-file" = "xmrig.log"
                "cpu" = [ordered]@{ "enabled" = $true; "huge-pages" = $true; "huge-pages-jit" = $false; "rx" = @(0..($ThreadList[-1] - 1)) }
                "randomx" = [ordered]@{ "wrmsr" = $true; "rdmsr" = $true }
                "http" = [ordered]@{ "enabled" = $true; "host" = "127.0.0.1"; "port" = 8080; "access-token" = $null; "restricted" = $true }
                "pools" = @( [ordered]@{ "url" = $PoolUrl; "user" = $WalletAddr; "pass" = "x"; "keepalive" = $true; "tls" = $false } )
            }
            [System.IO.File]::WriteAllText($CfgPath, ($NewConfig | ConvertTo-Json -Depth 10))
        } else {
            $RawLines = Get-Content $CfgPath | Where-Object { $_ -notmatch '^\s*//' }
            $JsonObj = ($RawLines -join "`n") | ConvertFrom-Json
            $JsonObj.autosave = $false
            if ($null -eq $JsonObj.'log-file') {
                $JsonObj | Add-Member -MemberType NoteProperty -Name "log-file" -Value "xmrig.log"
            } elseif ([string]::IsNullOrWhiteSpace($JsonObj.'log-file')) {
                $JsonObj.'log-file' = "xmrig.log"
            }
            if (-not $JsonObj.cpu) {
                $JsonObj | Add-Member -MemberType NoteProperty -Name "cpu" -Value ([PSCustomObject]@{ rx = @(0..($ThreadList[-1] - 1)) })
            }
            [System.IO.File]::WriteAllText($CfgPath, ($JsonObj | ConvertTo-Json -Depth 10))
        }

        if ($ChkDefender.Checked) { Add-MpPreference -ExclusionPath $Dir -ErrorAction SilentlyContinue }

        $Action = New-ScheduledTaskAction -Execute $ExePath -Argument "-B" -WorkingDirectory $Dir
        $Principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
        $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0
        Register-ScheduledTask -TaskName "StartXMRig" -Action $Action -Principal $Principal -Settings $Settings -Force | Out-Null

        $StopAction = New-ScheduledTaskAction -Execute "taskkill.exe" -Argument "/IM xmrig.exe /F"
        Register-ScheduledTask -TaskName "StopXMRig" -Action $StopAction -Principal $Principal -Settings $Settings -Force | Out-Null

        $BatPath = Join-Path $Dir "ToggleXMRig.bat"
        $BatLines = @(
            '@echo off'
            'tasklist /FI "IMAGENAME eq xmrig.exe" | find /I "xmrig.exe" >NUL'
            'if %ERRORLEVEL%==0 ('
            '    schtasks.exe /run /tn "StopXMRig" >NUL'
            '    powershell.exe -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like ''*XMRigTray.ps1*'' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }" >NUL 2>&1'
            '    echo =========================================='
            '    echo   XMRig has been STOPPED.'
            '    echo =========================================='
            ') else ('
            '    schtasks.exe /run /tn "StartXMRig" >NUL'
            '    start "" powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0XMRigTray.ps1"'
            '    echo =========================================='
            '    echo   XMRig has been STARTED.'
            '    echo =========================================='
            ')'
            'ping -n 4 127.0.0.1 >NUL'
        )
        [System.IO.File]::WriteAllText($BatPath, ($BatLines -join "`r`n"))
        $ArrayLiteral = "@(" + ($ThreadList -join ", ") + ")"
        $Ps1Template = @'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$CreatedNew = $false
$Mutex = New-Object System.Threading.Mutex($true, "Global\XMRigTraySingleInstanceMutex", [ref]$CreatedNew)
if (-not $CreatedNew) { exit }
Start-Sleep -Seconds 2

$XmrigDir = $PSScriptRoot
$XmrigExe = Join-Path $XmrigDir "xmrig.exe"
$ConfigPath = Join-Path $XmrigDir "config.json"
$LogPath = Join-Path $XmrigDir "xmrig.log"
$ThreadProfiles = __THREAD_PROFILES__
$MenuItems = @{}

function Get-ActiveThreadCount {
    try {
        $RawLines = Get-Content $ConfigPath | Where-Object { $_ -notmatch '^\s*//' }
        $JsonObj = ($RawLines -join "`n") | ConvertFrom-Json
        if ($JsonObj.cpu.rx -is [array]) { return $JsonObj.cpu.rx.Count }
    } catch {}
    return 0
}

function Update-MenuState {
    param([int]$ActiveCount)
    foreach ($Count in $ThreadProfiles) {
        $Item = $MenuItems[$Count]
        if ($Count -eq $ActiveCount) {
            $Item.Checked = $true
            $Item.Text = "$Count Threads"
        } else {
            $Item.Checked = $false
            $Item.Text = "Switch to $Count Threads"
        }
    }
    if ($ActiveCount -gt 0) { $TrayIcon.Text = "XMRig Running ($ActiveCount Threads)" }
}

function Set-XmrigThreads {
    param([int]$ThreadCount)
    schtasks.exe /run /tn "StopXMRig" | Out-Null
    $WaitCount = 0
    while ((Get-Process -Name "xmrig" -ErrorAction SilentlyContinue) -and ($WaitCount -lt 20)) {
        Start-Sleep -Milliseconds 250
        $WaitCount++
    }
    $RawLines = Get-Content $ConfigPath | Where-Object { $_ -notmatch '^\s*//' }
    $JsonObj = ($RawLines -join "`n") | ConvertFrom-Json
    $JsonObj.cpu.rx = @(0..($ThreadCount - 1))
    [System.IO.File]::WriteAllText($ConfigPath, ($JsonObj | ConvertTo-Json -Depth 10))
    schtasks.exe /run /tn "StartXMRig" | Out-Null
    Update-MenuState -ActiveCount $ThreadCount
    $TrayIcon.ShowBalloonTip(2000, "XMRig Thread Switch", "Switched to $ThreadCount threads.", [System.Windows.Forms.ToolTipIcon]::Info)
}

$TrayIcon = New-Object System.Windows.Forms.NotifyIcon
$TrayIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($XmrigExe)
$TrayIcon.Text = "XMRig Running"
$TrayIcon.Visible = $true

$ContextMenu = New-Object System.Windows.Forms.ContextMenuStrip

$ItemLog = $ContextMenu.Items.Add("View Live Log")
$ItemLog.Add_Click({
    if (-not (Test-Path $LogPath)) {
        [System.Windows.Forms.MessageBox]::Show("Log file not found yet at:`n$LogPath`n`nRestart XMRig once so it initializes xmrig.log.", "Log Not Found", "OK", "Information")
        return
    }
    $Cmd = "`$Host.UI.RawUI.WindowTitle = 'XMRig Live Log (Close window anytime - miner keeps running)'; Get-Content -Path '$LogPath' -Tail 40 -Wait"
    Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $Cmd
})
$ContextMenu.Items.Add("-") | Out-Null

foreach ($Count in $ThreadProfiles) {
    $NewItem = $ContextMenu.Items.Add("Switch to $Count Threads")
    $NewItem.Tag = $Count
    $NewItem.Add_Click({
        param($sender, $e)
        Set-XmrigThreads -ThreadCount ([int]$sender.Tag)
    })
    $MenuItems[$Count] = $NewItem
}

$ContextMenu.Items.Add("-") | Out-Null
$ItemStop = $ContextMenu.Items.Add("Stop XMRig")
$ItemStop.Add_Click({
    schtasks.exe /run /tn "StopXMRig" | Out-Null
    $TrayIcon.Visible = $false
    $TrayIcon.Dispose()
    [System.Windows.Forms.Application]::Exit()
})

$TrayIcon.ContextMenuStrip = $ContextMenu
Update-MenuState -ActiveCount (Get-ActiveThreadCount)

$AppContext = New-Object System.Windows.Forms.ApplicationContext
$Timer = New-Object System.Windows.Forms.Timer
$Timer.Interval = 3000
$Timer.Add_Tick({
    if (-not (Get-Process -Name "xmrig" -ErrorAction SilentlyContinue)) {
        $TrayIcon.Visible = $false
        $TrayIcon.Dispose()
        $Timer.Stop()
        $AppContext.ExitThread()
    }
})
$Timer.Start()
[System.Windows.Forms.Application]::Run($AppContext)
'@
        $Ps1Content = $Ps1Template.Replace('__THREAD_PROFILES__', $ArrayLiteral)
        [System.IO.File]::WriteAllText((Join-Path $Dir "XMRigTray.ps1"), $Ps1Content)

        if ($ChkShortcut.Checked) {
            $WshShell = New-Object -ComObject WScript.Shell
            $DesktopPath = [Environment]::GetFolderPath("Desktop")
            $Shortcut = $WshShell.CreateShortcut((Join-Path $DesktopPath "Toggle XMRig.lnk"))
            $Shortcut.TargetPath = "powershell.exe"
            $Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"& '$BatPath'; exit`""
            $Shortcut.WorkingDirectory = $Dir
            $Shortcut.IconLocation = "$ExePath,0"
            $Shortcut.Save()
        }

        if ($ChkStartup.Checked) {
            $LogonAction = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c start /min `"`" `"$BatPath`"" -WorkingDirectory $Dir
            $LogonTrigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
            $LogonPrincipal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
            Register-ScheduledTask -TaskName "StartXMRigOnLogon" -Action $LogonAction -Trigger $LogonTrigger -Principal $LogonPrincipal -Settings $Settings -Force | Out-Null
        } else {
            Unregister-ScheduledTask -TaskName "StartXMRigOnLogon" -Confirm:$false -ErrorAction SilentlyContinue
        }

        [System.Windows.Forms.MessageBox]::Show("XMRig Tray installed successfully!`n`n- Use 'Toggle XMRig' on your Desktop (or Pin to Taskbar) to start/stop.`n- Right-click the XMRig tray icon while running to view logs or switch threads.", "Installation Complete", "OK", "Information")
        $Form.Close()
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Installation error:`n$($_.Exception.Message)", "Error", "OK", "Error")
    }
})

[void]$Form.ShowDialog()
