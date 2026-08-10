# Installing the Nebula Camera on the Creality Sonic Pad

Many users have reported problems getting the **Nebula camera** working on the Sonic Pad.  
This guide explains a simple and reliable setup using **KIAUH** + **Crowsnest**, and shows how to edit the config from both **Fluidd** and **Mainsail**.

---

## 1. Install Crowsnest using KIAUH

1. SSH into the Sonic Pad.
2. Run:

       ~/kiauh/kiauh.sh

3. In the KIAUH menu:
   - Go to **Install**
   - Select **Crowsnest**

After installation, the remaining steps are done from the web UI (Fluidd or Mainsail).

---

## 2. Edit `crowsnest.conf`

### Where to edit the file

**Fluidd:**

- Left sidebar → **Configuration**
- Click **crowsnest.conf**

**Mainsail:**

- Left sidebar → **Machine**
- Click **Configs**
- Click **crowsnest.conf**

### Example configuration

    [crowsnest]
    log_path: /home/sonic/printer_data/logs/crowsnest.log
    log_level: debug
    delete_log: true
    no_proxy: false

    [cam 1]
    mode: ustreamer
    port: 8080
    device: /dev/video0
    resolution: 1280x720
    max_fps: 30
    custom_flags: --format=YUYV

Save the file.

---

## 3. Restart the Sonic Pad

After saving `crowsnest.conf`, **restart the Sonic Pad**.  
Crowsnest does not reload the config on its own in this environment.

A full reboot is required:

- Use the Sonic Pad UI’s restart option  
**or**
- SSH and run:

      sudo reboot

After the system restarts, open the web UI again and check the webcam panel.

---

## 4. Using the hardware ID (optional)

Linux exposes stable device paths under `/dev/v4l/by-id/`.  
Some users prefer using these because they do not change if device numbering shifts.

### 4.1 Find the hardware ID (SSH)

Run:

    ls /dev/v4l/by-id/

Example:

    usb-UnionImage_Co._Ltd_CCX2F3298_1234567890-video-index0

### 4.2 Use this path in `crowsnest.conf`

Replace the device line:

    device: /dev/v4l/by-id/usb-UnionImage_Co._Ltd_CCX2F3298_1234567890-video-index0

Full example:

    [crowsnest]
    log_path: /home/sonic/printer_data/logs/crowsnest.log
    log_level: debug
    delete_log: true
    no_proxy: false

    [cam 1]
    mode: ustreamer
    port: 8080
    device: /dev/v4l/by-id/usb-UnionImage_Co._Ltd_CCX2F3298_1234567890-video-index0
    resolution: 1280x720
    max_fps: 30
    custom_flags: --format=YUYV

Restart the Sonic Pad again afterward.

---

## 5. Note about the Sonic Pad’s Debian environment

The Sonic Pad ships with a **custom Debian image** that uses a **modified Linux kernel**.  
This kernel is closely tied to Creality’s drivers, hardware support, and the software environment on the Pad.

Because of that:

- The included kernel is older than what many newer webcams expect
- Certain camera features or formats may not work the same as on modern systems
- Upgrading to a newer Debian release or a different kernel version can break the interaction between the kernel drivers and the Sonic Pad software

This is why some webcams behave inconsistently, even when correctly configured.

---

## 6. Summary

- Install **Crowsnest** using **KIAUH**
- Edit `crowsnest.conf` in Fluidd or Mainsail
- Start with `/dev/video0`
- Optionally switch to the `/dev/v4l/by-id/...` path
- Always **restart the Sonic Pad** after changing Crowsnest settings
- Be aware that the Sonic Pad uses a **custom older kernel**, and upgrading Debian can break compatibility
