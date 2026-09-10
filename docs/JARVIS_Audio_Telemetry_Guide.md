# 🚀 The Master Guide: Real-Time Klipper Audio Telemetry Matrix

## 📋 The Problem
Most modern web browsers and operating systems have strict security sandboxes. They **block uninvited network scripts, forbid background audio autoplay without manual clicks**, and **terminate insecure background local IP WebSocket connections (`ws://`)**. 

Furthermore, running scripts on computer startup usually fails because the script executes before the PC's Wi-Fi card fully finishes authenticating with the home router network. 

## 🛠️ The Ultimate Solution
Instead of fighting browser extensions or manual console copy-pasting, the most stable, zero-maintenance approach is to move the vocal engine **completely out of the browser** and run it as a native, loop-protected, hidden **Windows PowerShell daemon** hooked directly into the printer's over-the-air API connection.

---

### Step 1: Configure Your Klipper Macro Overrides (`printer.cfg`)
To broadcast audio triggers over your home router network cleanly, you must instruct Klipper to push uniform logging hooks out of its standard console stream. 

Paste this macro block directly into your `printer.cfg`. It automatically intercepts heating, homing, and mesh calibrations to announce milestones with your precise 2-second voice timing pauses without needing to change your slicer settings:

```text
# ==========================================
# 1. SYSTEM INITIALIZATION & BOOT
# ==========================================
[delayed_gcode AUDIO_BOOT_JARVIS]
initial_duration: 2.0
gcode:
    RESPOND TYPE=echo MSG="ALERT: Systems online and fully operational"

# ==========================================
# 2. HEATING SEQUENCES
# ==========================================
[gcode_macro M190]
rename_existing: M190.1
gcode:
    RESPOND TYPE=echo MSG="ALERT: Bed heating initiated"
    M190.1 {rawparams}
    RESPOND TYPE=echo MSG="ALERT: Bed temperature stabilized"
    G4 P2000                                ; 2-second voice pause

[gcode_macro M109]
rename_existing: M109.1
gcode:
    RESPOND TYPE=echo MSG="ALERT: Nozzle heating initiated"
    M109.1 {rawparams}
    RESPOND TYPE=echo MSG="ALERT: Nozzle temperature stabilized"
    G4 P2000                                ; 2-second voice pause

# ==========================================
# 3. BED LEVELING & CALIBRATION
# ==========================================
[gcode_macro BED_MESH_CALIBRATE]
rename_existing: BED_MESH_CALIBRATE_BASE
gcode:
    RESPOND TYPE=echo MSG="ALERT: Structural surface scan initiated"
    G4 P2000                                ; Pause so voice finishes before motors hum
    BED_MESH_CALIBRATE_BASE {rawparams}
    RESPOND TYPE=echo MSG="ALERT: Surface mapping complete"
    G4 P2000                                ; 2-second voice pause

# ==========================================
# 4. FILAMENT MANAGEMENT
# ==========================================
[gcode_macro LOAD_FILAMENT]
gcode:
    RESPOND TYPE=echo MSG="ALERT: Filament intake engaged"
    G4 P2000                                ; 2-second voice pause
    # Add your existing load movement G-code here

[gcode_macro UNLOAD_FILAMENT]
gcode:
    RESPOND TYPE=echo MSG="ALERT: Filament extraction engaged"
    G4 P2000                                ; 2-second voice pause
    # Add your existing unload movement G-code here

[gcode_macro AUDIO_FILAMENT_RUNOUT]
gcode:
    RESPOND TYPE=echo MSG="ALERT: Emergency: Filament supply disrupted"

# ==========================================
# 5. PRINT MANAGEMENT
# ==========================================
[gcode_macro AUDIO_PRINT_START]
gcode:
    RESPOND TYPE=echo MSG="ALERT: Manufacturing sequence deployed"
    G4 P2000                                ; 2-second voice pause

[gcode_macro AUDIO_PRINT_FINISHED]
gcode:
    RESPOND TYPE=echo MSG="ALERT: Objective complete. System standing down"
```

---

### Step 2: Build the Core PowerShell Matrix (`jarvis_cockpit.ps1`)
This script opens a native network pipe over your home router, authorizes itself by attaching a valid `Origin` web header to bypass security proxies, uses a text scanner to pull telemetry milestones, and features a **Memory Shield** to ensure each phrase plays exactly once without looping.

1. Open **Notepad** on your PC.
2. Paste the following script inside:

```powershell
Add-Type -AssemblyName System.Speech
$Voice = New-Object System.Speech.Synthesis.SpeechSynthesizer
$Voice.SelectVoiceByHints([System.Speech.Synthesis.VoiceGender]::Male)
$Voice.Rate = 1
$Voice.Volume = 100

# INITIAL VALIDATION: Confirms script execution on boot
$Voice.Speak("Powering up vocal modules.")

# ⚠️ CHANGE THIS to your exact Sonic Pad / Klipper Local IP Address
$PrinterIP = "192.168.1.29"
$LastSpoken = ""

# INFINITE AUTO-RETRY LOOP: Constantly monitors background network frames
while ($true) {
    $WS = $null
    try {
        Write-Host "Connecting to Sonic Pad router stream at $PrinterIP..." -ForegroundColor Cyan
        $WS = New-Object System.Net.WebSockets.ClientWebSocket
        
        # HANDSHAKE HANDLER: Attaches the mandatory web origin so the printer trusts your PC natively
        $WS.Options.SetRequestHeader("Origin", "http://$PrinterIP")
        
        $URI = New-Object System.Uri("ws://$PrinterIP/websocket")
        $CT = [System.Threading.CancellationToken]::None
        
        $Connect = $WS.ConnectAsync($URI, $CT)
        $Timeout = 0
        while (-not $Connect.IsCompleted -and $Timeout -lt 40) {
            Start-Sleep -Milliseconds 100
            $Timeout++
        }
        
        if ($WS.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
            $Voice.Speak("Systems online and fully operational, sir.")
            Write-Host "SUCCESS: JARVIS is connected and listening!" -ForegroundColor Green
            
            while ($WS.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
                $Buffer = New-Object Byte[] 4096
                $Segment = New-Object System.ArraySegment[Byte] -ArgumentList @(,$Buffer)
                $Result = $WS.ReceiveAsync($Segment, $CT)
                while (-not $Result.IsCompleted) { Start-Sleep -Milliseconds 50 }
                
                $Message = [System.Text.Encoding]::UTF8.GetString($Buffer, 0, $Result.Result.Count)
                
                # AGGRESSIVE TEXT SCANNER: Intercepts raw JSON frames and parses target strings
                if ($Message -match '"notify_gcode_response".*?"params":\s*\[\s*"[^"]*alert:(?<phrase>[^"]+)"') {
                    $RawMatchedText = $Matches['phrase'].ToLower()
                    $CleanedText = $RawMatchedText.Replace("echo:", "").Replace("//", "").Replace("sir.", "").Trim() + ", sir."
                    
                    # MEMORY SHIELD: Prevents the background network buffer from double-repeating lines
                    if ($CleanedText -ne $LastSpoken) {
                        $LastSpoken = $CleanedText
                        Write-Host "Speaking: $CleanedText" -ForegroundColor Yellow
                        $Voice.Speak($CleanedText)
                    }
                }
            }
        } else {
            Write-Host "Could not reach pad. Retrying in 5 seconds..." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Network error occurred: $_" -ForegroundColor Red
    }
    
    # Safe cleanup of network containers before recycling loop
    if ($WS -ne $null) {
        try { $WS.Dispose() } catch {}
    }
    Start-Sleep -Seconds 5
}
```
3. Save this file inside your **`Documents`** folder as exactly **`jarvis_cockpit.ps1`**.

---

### Step 3: Create the Unrestricted Bypass Launcher (`Launch_JARVIS.bat`)
Windows strictly blocks execution of custom background `.ps1` code profiles out of safety rules. We bypass this roadblock natively by routing it through an administrative batch wrapper file configured in **`Hidden`** mode so your desktop stays perfectly clean.

1. Open a blank **Notepad** window.
2. Paste this execution rule code structure inside:

```text
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%USERPROFILE%\Documents\jarvis_cockpit.ps1"

:: --- FUTURE BACKUP / DEBUGGING LINES BELOW ---
:: To see the blue text window console log again in the future, add a "::" to the line above, and remove "::" from the lines below:
:: powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -File "%USERPROFILE%\Documents\jarvis_cockpit.ps1"
:: pause
```
3. Save this file directly inside your **`Documents`** folder as exactly **`Launch_JARVIS.bat`**.

---

### Step 4: Automate to Windows Boot (Task Scheduler)
To ensure the voice engine is fully hands-free without ever clicking manual icons or desktop shortcuts, lock it directly into Windows System Core:

1. Press your Windows Key, search for **Task Scheduler**, and open it.
2. On the right-side options panel, click **Create Basic Task...**
3. **Name:** Set to `🚀 JARVIS Launch` and click Next.
4. **Trigger:** Change to **When I log on**. Click Next.
5. **Action:** Choose **Start a program** and click Next.
6. **Program/Script:** Click Browse, navigate to your *Documents* folder, and select your **`Launch_JARVIS.bat`** file. Click Next, then click Finish.
7. **Lock Admin Rights:** Locate your newly created task in the center list, **right-click** it, and select **Properties**. At the very bottom of the *General* tab, check the box for **"Run with highest privileges"**.
8. **Network Freedom:** Flip to the **Conditions** tab at the top. Under the *Network* section at the very bottom, **uncheck** the network block rule and change the dropdown back to **Any connection**. Click OK.
