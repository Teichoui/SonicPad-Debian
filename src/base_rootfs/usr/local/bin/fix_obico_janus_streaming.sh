#!/bin/bash
# Run this AFTER installing moonraker-obico (e.g. via KIAUH - see
# docs/README.md) to fix live video streaming on the Sonic Pad.
#
# Without this, Obico's dashboard falls back to periodic snapshot
# polling instead of a real live video feed ("Real-time stream
# unavailable, showing last captured image").
#
# moonraker-obico bundles precompiled Janus (the WebRTC server it
# needs for live streaming) binaries under moonraker_obico/bin/janus/
# precomplied/<board>.<os>.<version>.<bits>/, but only recognizes "rpi"
# (Raspberry Pi) or "mks" (Makerbase) boards via /sys/firmware/
# devicetree/base/model (see board_id() in moonraker_obico/utils.py).
# The Sonic Pad's Allwinner board (model string "sun50iw10") matches
# neither, so board_id() returns "NA", no precompiled directory ever
# matches, and Janus never starts - even though the bundled
# rpi.debian.12.64-bit binaries are just plain aarch64 Debian 12 ELF
# binaries with no real Pi-specific dependency, and run fine here.
# Symlinking the variant Sonic Pad actually resolves to onto the
# closest real match fixes detection without needing to touch
# moonraker-obico's own source.
#
# Separately, that Janus binary is also missing several shared library
# dependencies that aren't part of this project's normal package list
# (confirmed via ldd): libconfig9, libnice10, libsrtp2-1, libusrsctp2.
# All ordinary Debian bookworm packages.

set -e

obico_dir="${HOME}/moonraker-obico"
if [ ! -d "${obico_dir}" ]; then
    echo "${obico_dir} not found - install moonraker-obico first (e.g. via KIAUH: ~/kiauh/kiauh.sh)."
    exit 1
fi

janus_precompiled_dir="${obico_dir}/moonraker_obico/bin/janus/precomplied"
janus_source="${janus_precompiled_dir}/rpi.debian.12.64-bit"
janus_link="${janus_precompiled_dir}/NA.debian.12.64-bit"

if [ ! -d "${janus_source}" ]; then
    echo "${janus_source} not found - moonraker-obico's bundled Janus layout may have changed since this script was written. Not safe to continue."
    exit 1
fi

ln -sf rpi.debian.12.64-bit "${janus_link}"

if [ ! -e "${janus_link}/bin/janus" ] || [ ! -d "${janus_link}/lib" ]; then
    echo "${janus_link} does not resolve to a usable Janus install (missing bin/janus or lib/) - moonraker-obico's bundled layout may have changed since this script was written."
    exit 1
fi

sudo apt-get install --yes libconfig9 libnice10 libsrtp2-1 libusrsctp2

echo "Done - restart moonraker-obico to pick this up: sudo systemctl restart moonraker-obico"
