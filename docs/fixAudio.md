[FixAudio.md](https://github.com/user-attachments/files/32169309/FixAudio.md)


\# 🤖 JARVIS Telemetry Integration Module: Debian / Klipper Upgrade Core

====================================================================



\## 📋 1. INTRODUCTION \& PERFORMANCE BREAKTHROUGH

This module establishes a real-time, bi-directional audio notification bridge between a printer's Klipper engine and a Windows workstation using native Text-to-Speech (TTS). 



\### 🔊 Bypassing the Debian Audio Breakage

When updating your hardware to a clean Debian base and a stock Klipper deployment, a major systemic limitation occurs: \*\*Debian breaks the printer's native onboard speaker entirely, rendering it completely useless.\*\* Because the stock open-source Linux environment lacks the proprietary, closed-source audio drivers built into Creality's original factory firmware image, the physical machine loses all capability to produce sound natively. 



This hardware silence typically leaves users with no choice but to physically plug a small portable USB speaker with a built-in DAC into one of the USB host ports on the Sonic Pad to achieve localized machine sound again.



This software framework completely solves that limitation by offloading the entire audio processing layer directly to your Windows computer over an optimized network pipe. Instead of struggling to force a broken onboard speaker to talk or crowding your physical enclosure workspace with extra USB hardware accessories, your printer streams its data states directly to your workstation's raw hardware power. 



This solution doesn't just get your voice notifications back—\*\*it delivers audio quality that is vastly superior to the built-in speaker.\*\* Instead of listening to raspy, muffled, low-quality speaker sound coming from a buzzing printer control box, JARVIS speaks with flawless clarity directly through your PC's dedicated audio setup, studio monitors, or headphones!



\### Why the Architecture Evolved

In the original factory layout, the system utilized Creality’s customized firmware includes (`cx\_printer.cfg`, `timelapse.cfg`, and `cx\_gmcro.cfg`). These built-in streams carried intense data congestion and circular macro loops. When a hardware fault dropped an error box, this accidental software latency loop gave the router a brief head-start to leak custom strings over the network pipe before the motherboard completely locked down.



Following the upgrade to a clean Debian base and modern stock Klipper, all factory legacy includes were permanently deleted. This optimization brought system latency down to true real-time. Because stock, optimized Klipper code prioritizes physical safety above network text streaming protocols, it executes a hardware-level microcontroller unit (MCU) panic shutdown to freeze power the exact millisecond a sensor or BLTouch probe faults. This protects your toolhead nozzle and heated build plate from mechanical impact, but it severs network socket streams instantly—blocking raw G-code text responses from escaping the machine before a connection dropout hits your computer.



\---



\## 🗂️ 2. THE FIRMWARE FORK: HANDLING THE CREALITY CONFIG TEMPLATES



When you initially flash Debian onto a stock Creality Sonic Pad, \*\*the original factory configuration includes (`cx\_printer.cfg`, `timelapse.cfg`, and `cx\_gmcro.cfg`) will still exist inside your configuration environment folder.\*\* This creates a massive fork in how you must set up your system. You have two distinct choices: keep them or remove them. 



\### CHOICE A: Keep the Legacy Includes (Templates Present Setup)

If you have just upgraded to Debian but choose to leave `cx\_printer.cfg`, `timelapse.cfg`, and `cx\_gmcro.cfg` active at the top of your `printer.cfg` using `\[include]` lines, your telemetry runs over the standard live network stream.



\*   \*\*Why they act this way:\*\* These legacy files introduce mild system loop latency. When a BLTouch probe pin faults or a hardware exception occurs, this slight software lag acts as a buffer. It delays Klipper's hardware emergency brake just long enough to allow an outbound `alert:` or `!!` error string to fully escape your motherboard cache and stream over the router to your PC before the firmware locks down.

\*   \*\*How to go about it:\*\* Leave your configuration include lines untouched. Deploy \*\*Method A (Unified Firewall Engine - `script\_unified.ps1`)\*\* from your Windows interactive launcher menu. The script's firewall filter will natively scan your network logs, automatically stripping out regular coordinate noise while speaking your true orange and red alert boxes cleanly.



\### CHOICE B: Lose the Legacy Includes (Templates Removed Setup)

For maximum performance, you can choose to \*\*permanently delete and unlink\*\* `cx\_printer.cfg`, `timelapse.cfg`, and `cx\_gmcro.cfg` from your printer configurations.



\*   \*\*Why you should remove them:\*\* These factory files are heavily congested with bloated, circular tracking loops and duplicate macro definitions. Deleting them completely flushes this background noise out of your firmware, dropping your toolhead processing latency down to absolute zero and allowing stock Klipper safety commands to fire in true real-time.

\*   \*\*How to remove them:\*\* 

&#x20;   1. Open your Mainsail/Fluidd dashboard browser window and navigate to your configuration files.

&#x20;   2. Open your primary \*\*`printer.cfg`\*\* file.

&#x20;   3. Scroll to the top, locate the lines reading `\[include cx\_printer.cfg]`, `\[include timelapse.cfg]`, and `\[include cx\_gmcro.cfg]`, and completely delete them.

&#x20;   4. Click \*\*Save \& Restart\*\*. \*(Note: You can safely delete the actual physical files from your machine directory afterward to keep your folder pristine).\*

\*   \*\*Why it changes your tracking:\*\* The instant this latency is eliminated, stock Klipper triggers its safety shutdowns so fast that network chips lose power instantly. No G-code text responses can escape your printer before a connection dropout hits your computer.

\*   \*\*How to go about it:\*\* To bypass this hardware-level cutoff, you must deploy \*\*Method B (Twin Sentinel Engine - `script\_sentinel.ps1`)\*\* from your Windows launcher. This engine runs an independent background process that directly pings your Moonraker database API state. The split-second your printer drops offline due to a hard safety cut, your PC immediately catches the connection state loss and announces your hardware exception alert cleanly without needing the printer to send text.



\---



\## ⏳ 3. THE MASTER PAUSE BLUEPRINT: WHEN, WHERE, \& WHY

To maintain absolute data integrity across your workspace, specific pauses are hardcoded into both the printer firmware and the computer scripts. 



\### Pause Location A: The Printer Firmware (`G4 P2000` / `G4 P500`)

\*   \*\*Where:\*\* In your `CANCEL\_PRINT`, `G28` (Homing), and `BED\_MESH\_CALIBRATE` macros, directly following the `RESPOND` voice cue line.

\*   \*\*Why It Is Required:\*\* Raw network data streams take a few milliseconds to clear your motherboard cache, travel out of your device's local router card, cross your home network lines, and land in your computer's WebSocket buffer. If Klipper executes an immediate movement command or encounters a hardware halt immediately after writing a text string, it kills the processing clock cycles \[1.21]. Without adding an intentional \*\*`G4 P2000` (2-second pause)\*\* or \*\*`G4 P500` (half-second pause)\*\*, the printer will destroy or truncate the message package inside the router's local memory stack before it can ever escape to your PC speakers \[1.21]. The pause deliberately holds the printer's breath, ensuring your voice lines travel safely to your computer first \[1.21].



\### Pause Location B: The Windows Script Memory Lock (`TotalSeconds -gt 5`)

\*   \*\*Where:\*\* Inside Rule 2 of your computer script code configurations.

\*   \*\*Why It Is Required:\*\* Klipper streams terminal errors at microsecond rates. If a sensor fails, the background pipeline will occasionally spam the exact same error packet dozens of times in a single second. Without a script-side time-release pause, Windows will attempt to speak every single packet simultaneously, causing JARVIS to stutter, overlap words, loop sentences indefinitely, or crash his text-to-speech module. The script applies a \*\*5-second memory lock\*\*. It speaks the fault box \*\*exactly once\*\*, completely dropping all incoming duplicates until 5 seconds have passed and your ears have heard the full alert phrase cleanly.



\---



\## 🌐 4. HOW TO FIND \& CONFIGURE YOUR PRINTER IP ADDRESS

Before launching the automation, your computer script must know the exact digital destination of your printer backend on your home network. Follow these steps to map the address properly:



\### Step 1: Find the IP Address on Your Debian Interface

1\. Open your standard web browser and log into your \*\*Mainsail or Fluidd interface dashboard\*\*.

2\. Look at your browser's URL address bar. 

3\. The group of numbers listed right before the text sections is your printer's network assignment (for example: `192.168.1.29`). Note this down exactly.



\### Step 2: Update Your PowerShell Scripts

You must paste this number into \*\*both\*\* script files inside your repository folder so they point to the correct machine:

1\. Open your local `Jarvis\_Repository` folder on your computer.

2\. Right-click \*\*`script\_unified.ps1`\*\* and choose \*\*Edit\*\* (or Open with Notepad).

3\. Find \*\*Line 11\*\* near the top of the file: 

&#x20;  `$PrinterIP = "192.168.1.29"`

4\. Delete the default numbers inside the quotation marks and replace them with your exact network IP address. \*\*Keep the quotation marks intact!\*\* Save and close the file.

5\. Repeat this exact process for \*\*Line 11\*\* inside the \*\*`script\_sentinel.ps1`\*\* file. Save and close.



\---



\## 🔬 5. ACCURACY VALIDATION SCENARIOS

To confirm your configuration is running flawlessly without any numeric leakage, execute these validation diagnostics:





1. The Telemetry Test: Run an axis homing command (G28). JARVIS should announce the initialization, remain entirely silent during movements, and speak precisely when homing finishes successfully.



2\. The Mesh Calibration Test: Trigger a full bed leveling mesh scan sequence. Watch your local PowerShell window handle the data arrays while your PC speakers remain entirely quiet throughout the probing path.



3.The BLTouch Fault Test: Trigger a homing movement and deliberately block the sensor needle pin with your finger. The script firewall or sentinel network gateway will instantly intercept the hardware halt condition and state: "System error detected. probe triggered prior to movement" exactly once.



\## ⚙️ 6. OPTIONAL AUTOMATION: AUTOMATIC BACKGROUND LAUNCH (TASK SCHEDULER)



If you want JARVIS to start listening automatically the moment you turn on your Windows PC—without having to double-click a `.bat` file or leave a blue PowerShell window sitting open on your desktop taskbar—you can route it through the native Windows Task Scheduler to run invisibly in the background.



\### Step 1: Initialize Task Scheduler

1\. Press the \*\*Windows Key\*\* on your keyboard, type \*\*Task Scheduler\*\*, and press \*\*Enter\*\*.

2\. In the far-right panel under the \*Actions\* menu, click \*\*Create Task...\*\* (do not click \*Create Basic Task\*).



\### Step 2: Configure the General Parameters

1\. \*\*Name:\*\* Type a clear label like `JARVIS Printer Telemetry Gateway`.

2\. \*\*Security Options:\*\* Look at the bottom of the window and select the checkbox marked \*\*Run whether user is logged on or not\*\*. 

3\. \*\*Hidden Mode:\*\* Check the box marked \*\*Hidden\*\* right next to it. This permanently suppresses the blue console window from popping up on your screen.



\### Step 3: Map the Automatic System Trigger

1\. Click on the \*\*Triggers\*\* tab at the top of the window, then click \*\*New...\*\* at the bottom.

2\. In the \*Begin the task\* drop-down menu at the very top, change it from \*On a schedule\* to \*\*At startup\*\*.

3\. Under \*Advanced settings\*, check the box for \*\*Delay task for\*\* and set it to \*\*30 seconds\*\*. (This gives your PC's Wi-Fi network cards time to fully connect to your router before the script tries to find the printer). Click \*\*OK\*\*.



\### Step 4: Link Your Script Execution Path

1\. Click on the \*\*Actions\*\* tab at the top, then click \*\*New...\*\* at the bottom.

2\. Ensure the \*Action\* drop-down reads \*\*Start a program\*\*.

3\. In the \*\*Program/script\*\* input box, type exactly:

&#x20;  ```text

&#x20;  powershell.exe

&#x20;  ```

4\. In the \*\*Add arguments (optional)\*\* text box, paste the following single-line argument string (make sure to replace the path with your exact local folder location):

&#x20;  ```text

&#x20;  -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\\YourFolder\\Jarvis\_Repository\\script\_unified.ps1"

&#x20;  ```

5\. Click \*\*OK\*\* to save the action module.



\### Step 5: Finalize \& Set Power Safety Rules

1\. Click on the \*\*Conditions\*\* tab at the top of the window.

2\. \*\*AC Power Override:\*\* \*Uncheck\* the box that says \*Start the task only if the computer is on AC power\*. (This ensures JARVIS continues protecting your print jobs even if your workstation is running on a laptop battery profile).

3\. Click \*\*OK\*\* at the absolute bottom of the task wizard. 

4\. A Windows prompt will pop open asking for your Windows password to grant background security clearance. Type your account password and hit confirm.



JARVIS is now a permanent system daemon. The next time your computer boots up, your speakers will quietly say \*"Powering up vocal modules,"\* and he will sit invisibly inside your RAM cache, waiting to protect your upgraded Debian Klipper workspace!



\## 🗑️ 7. CLEANUP CORE: COMPLETELY WIPING FACTORY INCLUDES VIA THE BACKEND



If you opted for \*\*CHOICE B\*\* and want a truly pristine, unbloated stock Klipper node, you must permanently delete the physical files from the underlying Linux directory so Moonraker stops tracking them entirely. Follow these steps to purge them safely:



\### Step 1: Access the Debian Terminal (SSH)

1\. On your Windows PC, press the \*\*Windows Key\*\*, type \*\*cmd\*\*, and press \*\*Enter\*\* to open the Command Prompt.

2\. Type the following SSH command using your specific printer IP address and press Enter:

&#x20;  ```bash

&#x20;  ssh root@###.###.#.##

&#x20;  ```

3\. Type your root user system password when prompted (the default password for standard Debian Sonic Pad setups is usually `creality` or `makerbase`).



\### Step 2: Purge the Physical Include Files

1\. Navigate directly to your active printer configuration database folder by typing:

&#x20;  ```bash

&#x20;  cd /home/sonic/printer\_data/config

&#x20;  ```

&#x20;  \*(Note: Depending on your exact Debian upgrade installer script, your path might be `/root/printer\_data/config` or `/root/klipper\_config`. Use `ls` to verify your directory layout).\*

2\. Execute a definitive force-remove command to permanently delete all three Creality legacy files at once:

&#x20;  ```bash

&#x20;  rm -f cx\_printer.cfg timelapse.cfg cx\_gmcro.cfg

&#x20;  ```

3\. Verify the files are completely wiped out of the local storage directory by typing `ls`. The template names should no longer appear in the directory printout.



\### Step 3: Clean the Dashboard Cache and Force a Hard MCU Restart

1\. Switch back over to your browser window and load your \*\*Mainsail/Fluidd dashboard\*\*.

2\. Go to the \*\*Machine\*\* file manager tab on the left sidebar. Notice that the three files have vanished from your file browser list.

3\. Open your primary \*\*`printer.cfg`\*\* inside the browser text editor canvas. Look at the very top of your text and double-check to guarantee that any old lines reading `\[include cx\_printer.cfg]`, `\[include timelapse.cfg]`, or `\[include cx\_gmcro.cfg]` are entirely deleted.

4\. Move your mouse to the top right-hand corner of your browser screen, click the drop-down arrow next to the restart button, and select \*\*Hard Restart MCU\*\* (or type `FIRMWARE\_RESTART` into your web terminal console box).



Your motherboard firmware loop will initialize instantly on a pure, unmodified stock Klipper layer. All hidden circular factory latency queues are officially dismantled, and your processing latency drops to absolute zero!





\---



\#### 2️⃣ File Name: `printer.cfg`

```text

\[respond]

default\_type: echo



\[virtual\_sdcard]

path: /home/sonic/printer\_data/gcodes

on\_error\_gcode: CANCEL\_PRINT



\# --- OVERRIDDEN HOMING CORE (ANNOUNCES COMPLETED ROUTINE) ---



\[gcode\_macro G28]

rename\_existing: BASE\_G28

gcode:

&#x20;   # 1. Announce initialization

&#x20;   RESPOND TYPE=echo MSG="alert: Adjusting positional structural coordinates"

&#x20;   

&#x20;   # 2. Execute actual physical axis homing

&#x20;   BASE\_G28 {rawparams}

&#x20;   

&#x20;   # 3. Hold network sync and announce completion

&#x20;   G4 P500                                 ; 0.5-second network buffer clearance pause

&#x20;   RESPOND TYPE=echo MSG="alert: Positional structural homing completed"



\# --- OVERRIDDEN BED MESH CORE (ANNOUNCES COMPLETED ROUTINE) ---



\[gcode\_macro BED\_MESH\_CALIBRATE]

rename\_existing: BASE\_BED\_MESH\_CALIBRATE

gcode:

&#x20;   # 1. Announce initialization

&#x20;   RESPOND TYPE=echo MSG="alert: Structural surface scan initiated"

&#x20;   

&#x20;   # 2. Execute multi-point grid calculations

&#x20;   BASE\_BED\_MESH\_CALIBRATE {rawparams}

&#x20;   

&#x20;   # 3. Hold network sync and announce completion

&#x20;   G4 P500                                 ; 0.5-second network buffer clearance pause

&#x20;   RESPOND TYPE=echo MSG="alert: Structural surface scan completed. Matrix adjustments applied."



\# --- STANDARD PRINT MATRIX CONTROLS ---



\[gcode\_macro START\_PRINT]

description: Code executed immediately upon launching a print job

gcode:

&#x20;   RESPOND TYPE=echo MSG="alert: Manufacturing sequence initialized"



\[gcode\_macro END\_PRINT]

description: Safe teardown routine when a print finishes successfully

gcode:

&#x20;   RESPOND TYPE=echo MSG="alert: Manufacturing sequence completed successfully"

&#x20;   M104 S0                                 ; Turn off nozzle

&#x20;   M140 S0                                 ; Turn off bed

&#x20;   M107                                    ; Turn off fan

&#x20;   G91                                     ; Relative positioning

&#x20;   G1 Z10 F3000                            ; Lift nozzle 10mm

&#x20;   G90                                     ; Absolute positioning

&#x20;   G1 X0 Y220 F3000                        ; Present completed print



\[gcode\_macro CANCEL\_PRINT]

description: Cancels the current print job safely and announces status

rename\_existing: BASE\_CANCEL\_PRINT

gcode:

&#x20;   RESPOND TYPE=echo MSG="alert: Manufacturing sequence aborted"

&#x20;   G4 P2000                                ; 2-second buffer clearance pause before shutdown

&#x20;   SET\_IDLE\_TIMEOUT TIMEOUT={printer.configfile.settings.idle\_timeout.timeout}

&#x20;   CLEAR\_PAUSE

&#x20;   SDCARD\_RESET\_FILE

&#x20;   END\_PRINT

&#x20;   BASE\_CANCEL\_PRINT



\# --- FILAMENT PROFILE MANAGEMENT ---



\[gcode\_macro LOAD\_FILAMENT]

description: Automated filament feeding profile

gcode:

&#x20;   RESPOND TYPE=echo MSG="alert: Material replacement sequence active. Loading material."

&#x20;   M109 S220                               ; Heat extruder to safe loading temp

&#x20;   G91                                     ; Relative extrusion

&#x20;   G1 E50 F300                             ; Extrude 50mm

&#x20;   G90                                     ; Absolute mode

&#x20;   G4 P500

&#x20;   RESPOND TYPE=echo MSG="alert: Material loading sequence finalized."



\[gcode\_macro UNLOAD\_FILAMENT]

description: Automated filament extraction profile

gcode:

&#x20;   RESPOND TYPE=echo MSG="alert: Extracting active printing material. Please standby."

&#x20;   M109 S220                               ; Heat extruder to safe unloading temp

&#x20;   G91                                     ; Relative extrusion

&#x20;   G1 E-50 F300                            ; Retract 50mm

&#x20;   G90                                     ; Absolute mode

&#x20;   G4 P500

&#x20;   RESPOND TYPE=echo MSG="alert: Material removal finalized. Standby for spool replacement."



3️⃣ File Name: script\_unified.ps1 **for powershell**



Add-Type -AssemblyName System.Speech

$Voice = New-Object System.Speech.Synthesis.SpeechSynthesizer

$Voice.SelectVoiceByHints(\[System.Speech.Synthesis.VoiceGender]::Male)

$Voice.Rate = 1

$Voice.Volume = 100



\# INITIAL VALIDATION: Confirms script execution on boot

$Voice.Speak("Powering up vocal modules.")



\# ⚠️ CHANGE THIS to your exact Sonic Pad / Klipper Local IP Address

$PrinterIP = "###.###.#.##"

$LastSpoken = ""

$RecentPhrases = @{} # Time-cache memory shield to stop loops



\# INFINITE AUTO-RETRY LOOP: Constantly monitors background network frames

while ($true) {

&#x20;   $WS = $null

&#x20;   try {

&#x20;       Write-Host "Connecting to Sonic Pad router stream at $PrinterIP (Method A: Unified Firewall Engine)..." -ForegroundColor Cyan

&#x20;       $WS = New-Object System.Net.WebSockets.ClientWebSocket

&#x20;       

&#x20;       # HANDSHAKE HANDLER: Attaches the mandatory web origin so the printer trusts your PC natively

&#x20;       $WS.Options.SetRequestHeader("Origin", "http://$PrinterIP")

&#x20;       

&#x20;       $URI = New-Object System.Uri("ws://$PrinterIP/websocket")

&#x20;       $CT = \[System.Threading.CancellationToken]::None

&#x20;       

&#x20;       $Connect = $WS.ConnectAsync($URI, $CT)

&#x20;       $Timeout = 0

&#x20;       while (-not $Connect.IsCompleted -and $Timeout -lt 40) {

&#x20;           Start-Sleep -Milliseconds 100

&#x20;           $Timeout++

&#x20;       }

&#x20;       

&#x20;       if ($WS.State -eq \[System.Net.WebSockets.WebSocketState]::Open) {

&#x20;           $Voice.Speak("Systems online and fully operational.")

&#x20;           Write-Host "SUCCESS: JARVIS Unified Firewall Engine online!" -ForegroundColor Green

&#x20;           

&#x20;           while ($WS.State -eq \[System.Net.WebSockets.WebSocketState]::Open) {

&#x20;               $Buffer = New-Object Byte\[] 4096

&#x20;               $Segment = New-Object System.ArraySegment\[Byte] -ArgumentList @(,$Buffer)

&#x20;               $Result = $WS.ReceiveAsync($Segment, $CT)

&#x20;               while (-not $Result.IsCompleted) { Start-Sleep -Milliseconds 50 }

&#x20;               

&#x20;               $Message = \[System.Text.Encoding]::UTF8.GetString($Buffer, 0, $Result.Result.Count)

&#x20;               

&#x20;               # --- GATE 1: YOUR ORIGINAL MACRO SCANNER (FOR "ALERT:") ---

&#x20;               if ($Message -match '"notify\_gcode\_response".\*?"params":\\s\*\\\[\\s\*"\[^"]\*alert:(?<phrase>\[^"]+)"') {

&#x20;                   $RawMatchedText = $Matches\['phrase'].ToLower()

&#x20;                   $CleanedText = $RawMatchedText.Replace("echo:", "").Replace("//", "").Replace("sir.", "").Replace("sir", "").Trim()

&#x20;                   

&#x20;                   if ($CleanedText -ne $LastSpoken) {

&#x20;                       $LastSpoken = $CleanedText

&#x20;                       Write-Host "Speaking Macro: $CleanedText" -ForegroundColor Yellow

&#x20;                       $Voice.Speak($CleanedText)

&#x20;                   }

&#x20;               }

&#x20;               # --- GATE 2: STRICT COGNITIVE FAULT FILTER (BLOCKS CHATTER, MATCHES GENUINE ERRORS) ---

&#x20;               elseif ($Message -match '"notify\_gcode\_response".\*?"params":\\s\*\\\[\\s\*"!!\\s\*(?<phrase>\[^"]+)"') {

&#x20;                   $RawError = $Matches\['phrase'].ToLower().Replace("echo:", "").Trim()

&#x20;                   

&#x20;                   # 🛡️ EXCLUSION GATE: Instantly drops numbers, calibration logs, and mesh height data dumps

&#x20;                   if ($RawError -match "probe:\\s\*at" -or $RawError -match "bed will contact" -or $RawError -match "points" -or $RawError -match "mesh") {

&#x20;                       # Ignore entirely and drop packet

&#x20;                   }

&#x20;                   else {

&#x20;                       # 🎯 VALIDATION GATE: Only proceed if the text explicitly matches real error keywords

&#x20;                       if ($RawError -match "triggered" -or $RawError -match "fail" -or $RawError -match "error" -or $RawError -match "stop" -or $RawError -match "shutdown" -or $RawError -match "missed" -or $RawError -match "must home") {

&#x20;                           

&#x20;                           # 🛡️ COORDINATE STRIPPER: Instantly cuts off unhomed coordinate numbers and bracket arrays

&#x20;                           if ($RawError -match "must home axis first") {

&#x20;                               $RawError = "must home axis first"

&#x20;                           }

&#x20;                           if ($RawError -match "(probe triggered prior to movement)") {

&#x20;                               $RawError = "probe triggered prior to movement"

&#x20;                           }



&#x20;                           # Clean expired entries from tracking dictionary

&#x20;                           $Now = Get-Date

&#x20;                           $ExpiredKeys = @()

&#x20;                           foreach ($key in $RecentPhrases.Keys) {

&#x20;                               if (($Now - $RecentPhrases\[$key]).TotalSeconds -gt 5) { $ExpiredKeys += $key }

&#x20;                           }

&#x20;                           foreach ($key in $ExpiredKeys) { $RecentPhrases.Remove($key) }



&#x20;                           # Voice genuine red alerts exactly once

&#x20;                           if ($RawError -notmatch "ready" -and -not $RecentPhrases.ContainsKey($RawError)) {

&#x20;                               $RecentPhrases\[$RawError] = $Now

&#x20;                               $LastSpoken = $RawError

&#x20;                               Write-Host "CRITICAL SYSTEM BOX INTERCEPTED: $RawError" -ForegroundColor Red

&#x20;                               $Voice.Speak("System error detected. " + $RawError)

&#x20;                           }

&#x20;                       }

&#x20;                   }

&#x20;               }

&#x20;           }

&#x20;       } else {

&#x20;           Write-Host "Could not reach pad. Retrying in 5 seconds..." -ForegroundColor Yellow

&#x20;       }

&#x20;   } catch {

&#x20;       # --- EMERGENCY PROTECTION GATEWAY (CATCHES RELIABLE NET DROP ON HARD CRASH) ---

&#x20;       if ($LastSpoken -ne "hardware exception") {

&#x20;           $LastSpoken = "hardware exception"

&#x20;           Write-Host "HARD SHUTDOWN NETWORK CUT CAUGHT: $\_" -ForegroundColor Red

&#x20;           $Voice.Speak("System error detected.")

&#x20;       }

&#x20;   }

&#x20;   if ($WS -ne $null) { try { $WS.Dispose() } catch {} }

&#x20;   Start-Sleep -Seconds 5

}



4️⃣ File Name: script\_sentinel.ps1 **for powershell**



Add-Type -AssemblyName System.Speech

$Voice = New-Object System.Speech.Synthesis.SpeechSynthesizer

$Voice.SelectVoiceByHints(\[System.Speech.Synthesis.VoiceGender]::Male)

$Voice.Rate = 1

$Voice.Volume = 100



\# INITIAL VALIDATION: Confirms script execution on boot

$Voice.Speak("Powering up vocal modules.")



\# ⚠️ CHANGE THIS to your exact Sonic Pad / Klipper Local IP Address

$PrinterIP = "###.###.#.##"

$LastSpoken = ""

$LastState = "ready"



\# INFINITE AUTO-RETRY LOOP: Constantly monitors background network frames

while ($true) {

&#x20;   $WS = $null

&#x20;   try {

&#x20;       Write-Host "Connecting to Sonic Pad router stream at $PrinterIP (Method B: Isolated Twin Sentinel)..." -ForegroundColor Cyan

&#x20;       $WS = New-Object System.Net.WebSockets.ClientWebSocket

&#x20;       $WS.Options.SetRequestHeader("Origin", "http://$PrinterIP")

&#x20;       

&#x20;       $URI = New-Object System.Uri("ws://$PrinterIP/websocket")

&#x20;       $CT = \[System.Threading.CancellationToken]::None

&#x20;       

&#x20;       $Connect = $WS.ConnectAsync($URI, $CT)

&#x20;       $Timeout = 0

&#x20;       while (-not $Connect.IsCompleted -and $Timeout -lt 40) {

&#x20;           Start-Sleep -Milliseconds 100

&#x20;           $Timeout++

&#x20;       }

&#x20;       

&#x20;       if ($WS.State -eq \[System.Net.WebSockets.WebSocketState]::Open) {

&#x20;           $Voice.Speak("Systems online and fully operational.")

&#x20;           Write-Host "SUCCESS: JARVIS Sentinel Engine online!" -ForegroundColor Green

&#x20;           

&#x20;           while ($WS.State -eq \[System.Net.WebSockets.WebSocketState]::Open) {

&#x20;               $Buffer = New-Object Byte\[] 4096

&#x20;               $Segment = New-Object System.ArraySegment\[Byte] -ArgumentList @(,$Buffer)

&#x20;               $Result = $WS.ReceiveAsync($Segment, $CT)

&#x20;               while (-not $Result.IsCompleted) { Start-Sleep -Milliseconds 50 }

&#x20;               

&#x20;               $Message = \[System.Text.Encoding]::UTF8.GetString($Buffer, 0, $Result.Result.Count)

&#x20;               

&#x20;               # --- PROCESS STANDARD TELEMETRY MACROS ---

&#x20;               if ($Message -match '"notify\_gcode\_response".\*?"params":\\s\*\\\[\\s\*"\[^"]\*alert:(?<phrase>\[^"]+)"') {

&#x20;                   $RawMatchedText = $Matches\['phrase'].ToLower()

&#x20;                   $CleanedText = $RawMatchedText.Replace("echo:", "").Replace("//", "").Replace("sir.", "").Replace("sir", "").Trim()

&#x20;                   

&#x20;                   if ($CleanedText -ne $LastSpoken) {

&#x20;                       $LastSpoken = $CleanedText

&#x20;                       Write-Host "Speaking Macro: $CleanedText" -ForegroundColor Yellow

&#x20;                       $Voice.Speak($CleanedText)

&#x20;                   }

&#x20;               }



&#x20;               # --- PROCESS INDEPENDENT BACKGROUND STATE MONITORING ---

&#x20;               try {

&#x20;                   $Response = Invoke-RestMethod -Uri "http://$PrinterIP/printer/info" -Method Get -TimeoutSec 1

&#x20;                   $CurrentState = $Response.result.state

&#x20;                   

&#x20;                   if (($CurrentState -eq "shutdown" -or $CurrentState -eq "error") -and $LastState -eq "ready") {

&#x20;                       $LastState = $CurrentState

&#x20;                       Write-Host "CRITICAL MOONRAKER STATE CAPTURED: $CurrentState" -ForegroundColor Red

&#x20;                       $Voice.Speak("Alert. Critical hardware exception detected. System standing down.")

&#x20;                   }

&#x20;                   if ($CurrentState -eq "ready" -and $LastState -ne "ready") {

&#x20;                       $LastState = "ready"

&#x20;                   }

&#x20;               } catch {

&#x20;                   # Fail silently to prevent console logging loops during hardware power cuts

&#x20;               }

&#x20;           }

&#x20;       } else {

&#x20;           Write-Host "Could not reach pad. Retrying in 5 seconds..." -ForegroundColor Yellow

&#x20;       }

&#x20;   } catch {

&#x20;       if ($LastSpoken -ne "hardware exception") {

&#x20;           $LastSpoken = "hardware exception"

&#x20;           Write-Host "CRITICAL SHUTDOWN DETECTED VIA DISCONNECT" -ForegroundColor Red

&#x20;           $Voice.Speak("System error detected.")

&#x20;       }

&#x20;   }

&#x20;   

&#x20;   if ($WS -ne $null) {

&#x20;       try { $WS.Dispose() } catch {}

&#x20;   }

&#x20;   Start-Sleep -Seconds 5

}



5️⃣ File Name: launch\_jarvis.bat



@echo off

TITLE JARVIS Integrated Repository Workspace Engine

CLS

echo ====================================================================

echo             JARVIS SYSTEM INTEGRATION RUNTIME PORTAL

echo ====================================================================

echo.

echo  Deploy Method A: Unified Engine (Firewall Shield Enabled)

echo  Deploy Method B: Twin Sentinel Engine (Direct Database Monitor)

echo.

echo ====================================================================

set /p choice="Select operational configuration layer \[1-2]: "



if "%choice%"=="1" (

&#x20;   echo Launching Unified Firewall Layer...

&#x20;   PowerShell.exe -ExecutionPolicy Bypass -File "%\~dp0script\_unified.ps1"

)

if "%choice%"=="2" (

&#x20;   echo Launching Isolated Twin Sentinel Layer...

&#x20;   PowerShell.exe -ExecutionPolicy Bypass -File "%\~dp0script\_sentinel.ps1"

)

pause



