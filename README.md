<p align="center">
  <a href="https://github.com/Teichoui/SonicPad-Debian/" title="SonicPad Logo">
    <img src="https://github.com/Jpe230/SonicPad-Debian/assets/6202305/ce559b28-9835-4447-809d-594a5bb70847" width="200px" alt="SonicPad Logo"/>
  </a>
</p>
<h1 align="center">🌟 SonicPad Debian 🌟</h1>
<p align="center">Port of Debian for the SonicPad (Allwinner R818)</p>

<h2 align="center">🌐 Links 🌐</h2>
<p align="center">
    <a href="https://github.com/Teichoui/SonicPad-Debian/releases" title="Releases">📂 Releases</a>
    ·
    <a href="https://github.com/Teichoui/SonicPad-Debian/issues/new/choose" title="Report Bug/Request Feature">🐛 Got an issue</a>
    .
    <a href="https://github.com/Teichoui/SonicPad-Debian/pulls" title="PR">🚀 Contribute a new feature </a>
</p>

## 🚀 Features

Ready to go Debian 12 Bookworm Image for the SonicPad! Allows you to install the latest, unmodified, versions of software within the Klipper ecosystem.

The following packages are pre-installed:

- **Klipper: https://www.klipper3d.org/**
- **Moonraker: https://moonraker.readthedocs.io/**
- **KlipperScreen: https://klipperscreen.readthedocs.io/**

## 🎚️ Prerequisites

- USB-A Male to USB-A Male Cable
- A Windows/Linux/macOS device to flash the SonicPad

## 🛠️ Installation Steps

1. Download the latest [release image](https://github.com/Teichoui/SonicPad-Debian/releases)

2. Flash the Sonic Pad

>Please refer to [`docs/flashing.md`](docs/flashing.md) for detailed instructions. 

3. Using KlipperScreen, configure your WIFI network and get the IP of the Pad

4. SSH into the pad

```bash
ssh sonic@<your ip>
```

> ℹ️ The default login password is: `pad` 

5. (Optional) Configure SonicPad-Debian
> Documentation for further configuration options can be found in the [`docs/` directory](docs/). 

> This is where documentation for accelerometer support, timezones, KIAUH, Fluidd, Crowsnest, and others is found. 


6. Configure Klipper! 😁

**🎇 You are Ready to Go!**

## ❗ Available Commands

The prebuilt includes a CLI to control the brightness, to see its usage please run:

```Bash
sudo brightness -h
```

## 📂 Directory Structure

> [`src`](https://github.com/Teichoui/SonicPad-Debian/blob/main/src "src"): Scripts necessary to build a rootfs.

> [`src/prebuilt_kernel`](https://github.com/Teichoui/SonicPad-Debian/blob/main/src/prebuilt_kernel "src/prebuilt"): Prebuilt Kernel and tools necessary to pack the final image

> [`src/base_rootfs`](https://github.com/Teichoui/SonicPad-Debian/blob/main/src/base_rootfs "src/base_rootfs"): Files that are needed to be copied to the built rootfs 

> [`src/scripts`](https://github.com/Teichoui/SonicPad-Debian/blob/main/src/scripts "src/scripts"): Scripts to install Klipper, Moonraker, KlipperScreen

❗Want to build your own rootfs? Please see the [DIY Section](https://github.com/Teichoui/SonicPad-Debian/blob/main/DIY.md)

## 🎊 Future Updates

- [x] ~~Idle timeout: Creality has a script to turn off the display after 2 min of inactivity~~ (Dont forget to change the screen timeout in KlipperScreen)

- [x] ~~Replace the rootfs inside Tina SDK to avoid hacking the compiled img~~

- [x] ~~Create a prebuilt images ready to be flash~~

- [x] ~~Create a script to auto-mount a USB flashdrive to load `wpa_supplicant.conf`~~ Not needed

## 🪲 Known bugs

- Incorrect Interface shown in KlipperScreen

- Current IP doesn't show in KlipperScreen

## 👀 Disclaimers

⚠️ It should be noted that the SonicPad-Debian firmware, unlike the stock firmware, uses a read/write filesystem. This means that, just like your computer at home, removing the power unexpectedly can damage your files. **Do not use the button on the side of the SonicPad to turn it off.** You must gracefully shutdown using a GUI or by issuing the `shutdown` or `restart` commands ⚠️

## 🤝 Support

- Contributions are most welcome!

I'm not responsible for bricked devices, failed prints, etc. This is merely a place where I can share a personal project with the rest of the world.

- YOU are choosing to make these modifications, by no means I'm forcing you to replace the OS of your pad.
- The prebuilt image is provided "as-is"-- meaning, I don't plan to give it long-term support and bugs or errors aren't my responsibility.

**Please take in mind that this will certainly void your warranty and is not endorsed by Creality in any way.**


## 🪙 Credits

- The scripts used for installing Klipper are based on the great work of [KIAUH](https://github.com/th33xitus/kiauh)

- The CLI tool for controlling the brightness is taken from [Creality's repo](https://github.com/CrealityTech/sonic_pad_os)

- Klipper: https://www.klipper3d.org/

- Moonraker: https://moonraker.readthedocs.io/ 

- KlipperScreen: https://klipperscreen.readthedocs.io/




## 🛠️ Building main (arm64 / Bookworm) on WSL2 / Ubuntu 22.04

The `main` branch now targets **Debian 12 Bookworm, arm64 (64-bit)** instead of the old bullseye/armhf release. If you're building it yourself via [DIY.md](DIY.md) on WSL2/Ubuntu 22.04, you'll likely hit two real bugs — both fixed by doing the following **before** running `./build.sh`:

### 1. `dragon` fails with "No such file or directory" (it's actually there)

`prebuilt_kernel/tools/dragon` is a **32-bit x86** ELF binary. Ubuntu 22.04 x86_64 doesn't have 32-bit library support enabled by default, so the 32-bit dynamic linker it needs doesn't exist — the kernel reports this as "No such file or directory" even though the file is present. Fix:

```bash
dpkg --add-architecture i386
apt-get update
apt-get install -y libc6:i386 libstdc++6:i386 zlib1g:i386
```

### 2. Build silently produces a broken/undersized image (or fails with `Illegal option --` / `cannot open <command>`)

This is caused by `qemu-user-static`'s default binfmt_misc registration missing flags the second-stage chroot install needs. Symptoms vary depending on exactly what's missing:
- **Missing Credentials (`C`) flag**: privileged operations inside the chroot (like `sudo`) silently fail, producing a rootfs that looks complete but is missing large chunks (Klipper/Moonraker/KlipperScreen never get installed, final image ends up far smaller than it should be).
- **Missing Preserve-argv0 (`P`) flag**: argument passing to emulated binaries breaks entirely — e.g. `sh -c 'command'` gets misinterpreted as `sh <file named "command">`, producing errors like `-c: 0: cannot open <command>: No such file` or `Illegal option --`.

Check the current registration:

```bash
cat /proc/sys/fs/binfmt_misc/qemu-aarch64
```

If `flags:` isn't at least `PCF`, re-register it:

```bash
printf ':qemu-aarch64:M::\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/libexec/qemu-binfmt/aarch64-binfmt-P:PCF\n' > /tmp/regfix.txt
echo -1 > /proc/sys/fs/binfmt_misc/qemu-aarch64 2>/dev/null
cat /tmp/regfix.txt > /proc/sys/fs/binfmt_misc/register
```

`update-binfmts --disable qemu-aarch64 && update-binfmts --enable qemu-aarch64` does **not** reliably fix this even though its config file claims credentials support — the manual re-registration above is required. If your rootfs was already built under a broken registration, delete `src/rootfs`, `src/out`, and `src/temp` and rebuild from scratch after fixing this.

### 3. Runtime: Moonraker's Update Manager shows everything as "Invalid" / websocket randomly drops with "broken pipe"

This isn't a build bug, but a real bug in the device's own kernel that anyone running this image will hit. The Sonic Pad's kernel reports `clock_getres(CLOCK_MONOTONIC)` as **~547 seconds** instead of nanosecond/microsecond scale:

```bash
python3 -c "import time; print(time.get_clock_info('monotonic'))"
# resolution=547.554232048   <- should be a tiny fraction of a second
```

Python's `asyncio` reads this once at event loop creation and uses it to decide which scheduled timers are due (`base_events.py`: `end_time = self.time() + self._clock_resolution`). With a 547-second resolution, *any* timer due within the next ~9 minutes — `asyncio.wait_for()` timeouts, Tornado's websocket ping/pong deadlines, etc. — is treated as already expired and fires instantly instead of at its real deadline. Reproduced standalone with zero application code:

```python
import asyncio, time
async def m():
    loop = asyncio.get_running_loop()
    fired = []
    loop.call_later(20, lambda: fired.append("fired early!"))
    asyncio.ensure_future(asyncio.sleep(0.05))  # creating any concurrent Task triggers it
    await asyncio.sleep(4)
    print(fired)  # prints ['fired early!'] after ~1ms, not empty after 4s
asyncio.run(m())
```

This is the true root cause behind the `tornado==6.4.2` pin in `install_moonraker.sh` (the pin is a coincidental workaround, not a real fix) and behind Moonraker's Update Manager showing Klipper/Moonraker/KlipperScreen as permanently "Invalid" with `"No git repo detected at configured path"` — the `git status` subprocess calls used to check repo state were "timing out" in under a millisecond every single time.

The real fix (already baked into `install_moonraker.sh` via `install_clock_resolution_fix`) overrides the resolution Python reports for the monotonic clock, injected as a `PYTHONPATH` sitecustomize.py outside Moonraker's own git tree so it survives future `git pull` updates. If you're on an image built before this fix landed, you can apply it manually:

```bash
mkdir -p ~/printer_data/pyfix
cat > ~/printer_data/pyfix/sitecustomize.py <<'EOF'
import time
_orig_get_clock_info = time.get_clock_info
def _get_clock_info(name):
    info = _orig_get_clock_info(name)
    if name == "monotonic" and info.resolution > 0.001:
        import types
        info = types.SimpleNamespace(implementation=info.implementation,
            monotonic=info.monotonic, adjustable=info.adjustable, resolution=1e-6)
    return info
time.get_clock_info = _get_clock_info
EOF
echo 'PYTHONPATH=/home/'"$USER"'/printer_data/pyfix' | sudo tee -a ~/printer_data/systemd/moonraker.env
sudo systemctl restart moonraker
```
