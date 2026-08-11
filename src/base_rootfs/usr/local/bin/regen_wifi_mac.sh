#!/bin/bash
# The xr819/xr829 WiFi chip's MAC address is read from this file rather
# than an on-chip EEPROM. It ships baked into the image with the same
# fixed value on every device built from it, causing every flashed Sonic
# Pad to have an identical WiFi MAC - a real conflict on any network with
# more than one. Runs once on first boot (before the wifi kernel modules
# load, via systemd-modules-load.service ordering) to replace it with a
# random, valid, locally-administered unicast MAC unique to this device,
# then disables itself so it never runs again.

set -e

MAC_FILE=/etc/wifi/xr_wifi.conf

read -r b1 b2 b3 b4 b5 b6 < <(od -An -tu1 -N6 /dev/urandom)
# Locally-administered (bit 1 of the first byte set) + unicast (bit 0
# clear), so it can never collide with a real vendor-assigned MAC.
b1=$(( (b1 & 0xFE) | 0x02 ))
printf '%02X:%02X:%02X:%02X:%02X:%02X\n' "$b1" "$b2" "$b3" "$b4" "$b5" "$b6" > "$MAC_FILE"

systemctl disable regen_wifi_mac
