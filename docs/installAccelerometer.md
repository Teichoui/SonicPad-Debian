# Install Accelerometer

```bash
# Update package index
sudo apt update
# Install Dependencies
sudo apt install binutils-arm-none-eabi libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib gcc-arm-none-eabi python3-numpy python3-matplotlib libatlas-base-dev
# Install numpy to our Klipper python virtual env
~/klippy-env/bin/pip install -v numpy
```
> ❗ These packages take a lot space. I recommend using a different host to build a firmware for your printer ❗

> ❗ If `import matplotlib` fails afterwards with `RuntimeError: Could not find matplotlibrc file; your Matplotlib install is broken`, this almost always means the install above left packages in an unpacked-but-not-configured state (`dpkg -l | grep '^iU'` will show a long list, likely including several of the packages you just installed). Run `sudo dpkg --configure -a` to finish configuring everything, then retry - no need to reinstall matplotlib itself. ❗

```bash
# Install Klipper MCU service to Systemd
sudo cp ~/klipper/scripts/klipper-mcu.service /etc/systemd/system/
sudo systemctl enable klipper-mcu.service
systemctl daemon-reload
```

Build and flash `klipper-mcu` (the "Linux process" MCU target - this runs as its own service on the Sonic Pad itself and talks to the accelerometer over SPI, separate from the printer's own MCU connection):

```bash
cd ~/klipper
make clean
echo 'CONFIG_MACH_LINUX=y' > .config
make olddefconfig
make
sudo ./scripts/flash-linux.sh out/
```

> The original instructions here used `make menuconfig`, an interactive terminal menu where you'd select "Linux process" by hand. That doesn't work over most SSH clients/scripts (no real TUI), so the commands above write the same choice directly to `.config` and let `make olddefconfig` fill in the rest non-interactively - functionally identical result, just doesn't require an interactive terminal. If you *are* at a real interactive terminal and prefer the menu, `make menuconfig` still works; just select "Linux process" as the Micro-controller Architecture.

Verify it's running before moving on:

```bash
systemctl is-active klipper-mcu   # should print "active"
ls -la /tmp/klipper_host_mcu      # should exist
```

Add the following to the `printer.cfg`
```
[mcu rpi]
serial: /tmp/klipper_host_mcu

[adxl345]
cs_pin: rpi:None
spi_speed: 2000000
spi_bus: spidev2.0

[resonance_tester]
accel_chip: adxl345
accel_per_hz: 70
probe_points:
      117.5,117.5,10
```
> Use whatever probe points are appropriate for your bed size

You can now use the accelerometer to measure resonance. If you run into errors when not using the accelerometer, comment out the lines above and uncomment when a measurement is needed.

## Running the calibration

The accelerometer needs to be moved between two mounting points across two separate runs, since on a bed-slinger printer (like the stock Ender 3 S1) the toolhead moves for X/Z but the bed itself moves for Y:

1) Mount the accelerometer on the **toolhead** (as rigidly as possible - it needs to move exactly with the nozzle, no wobble), home the printer (`G28`), then run:
   ```
   SHAPER_CALIBRATE AXIS=X
   ```
2) Move the accelerometer to the **bed** (taped down or clipped near center), home again, then run:
   ```
   SHAPER_CALIBRATE AXIS=Y
   ```
3) Once both are done, run `SAVE_CONFIG` to persist the results (`shaper_type_x/y`, `shaper_freq_x/y`) into `printer.cfg` and restart Klipper.

Each `SHAPER_CALIBRATE` run does a real frequency sweep on the hardware and can take a minute or two - this is expected, not a hang.

> ❗ If you're on a build from before the [monotonic clock resolution fix](/README.md) landed, `TEST_RESONANCES`/`SHAPER_CALIBRATE` may hang or fail outright partway through the sweep. That's a real kernel-level bug on this device unrelated to the accelerometer itself - see the README's troubleshooting section. Confirmed fixed on a build with that patch: a full `SHAPER_CALIBRATE AXIS=X` run completed cleanly end to end (411,000 raw accelerometer samples recorded, no hang). ❗

-----

# Troubleshooting:

Some users have reported the following error while trying to flash klipper-mcu (this was specific to the old interactive `make menuconfig` step, which the instructions above no longer use, but is left here in case you hit it running `make menuconfig` directly):

```
sonic@SonicPad:~/klipper$ make menuconfig #
Loaded configuration '/home/sonic/klipper/.config'
Traceback (most recent call last):
  File "/home/sonic/klipper/lib/kconfiglib/menuconfig.py", line 3281, in <module>
    _main()
  File "/home/sonic/klipper/lib/kconfiglib/menuconfig.py", line 661, in _main
    menuconfig(standard_kconfig(__doc__))
  File "/home/sonic/klipper/lib/kconfiglib/menuconfig.py", line 705, in menuconfig
    locale.setlocale(locale.LC_ALL, "")
  File "/usr/lib/python3.9/locale.py", line 610, in setlocale
    return _setlocale(category, locale)
locale.Error: unsupported locale setting
make: *** [Makefile:116: menuconfig] Error 1
```

To remedy, run the following commands and select "en_US UTF8"

```
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
sudo dpkg-reconfigure locales
```
