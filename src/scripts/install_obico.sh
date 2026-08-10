#!/bin/bash
# Installs moonraker-obico, which connects Klipper to Obico
# (https://www.obico.io) for AI-powered print failure detection and
# remote monitoring/webcam streaming from a phone app.
#
# This only installs the software and points it at the Obico Cloud by
# default (https://app.obico.io) - it deliberately does NOT link the
# printer to an account. Linking is inherently a per-user, per-account
# action (it associates this specific printer with someone's specific
# Obico account) and can't be meaningfully automated at image-build
# time. To link:
#   cd ~/moonraker-obico && ./scripts/link.sh -c ~/printer_data/config/moonraker-obico.cfg
# This prints a manual linking code and starts scanning the local
# network so the Obico app/website can discover the printer.
#
# To use a self-hosted Obico server instead of the cloud, edit the
# "url" under [server] in ~/printer_data/config/moonraker-obico.cfg
# before linking, or pass -S http://<server-ip>:<port> to install.sh.

set -e

function fix_janus_live_streaming()
{
    # Without this, Obico's dashboard falls back to periodic snapshot
    # polling instead of a real live video feed ("Real-time stream
    # unavailable, showing last captured image").
    #
    # moonraker-obico bundles precompiled Janus (the WebRTC server it
    # needs for live streaming) binaries under moonraker_obico/bin/
    # janus/precomplied/<board>.<os>.<version>.<bits>/, but only
    # recognizes "rpi" (Raspberry Pi) or "mks" (Makerbase) boards via
    # /sys/firmware/devicetree/base/model (see board_id() in
    # moonraker_obico/utils.py). The Sonic Pad's Allwinner board (model
    # string "sun50iw10") matches neither, so board_id() returns "NA",
    # no precompiled directory ever matches, and Janus never starts -
    # even though the bundled rpi.debian.12.64-bit binaries are just
    # plain aarch64 Debian 12 ELF binaries with no real Pi-specific
    # dependency, and run fine here. Symlinking the variant Sonic Pad
    # actually resolves to onto the closest real match fixes detection
    # without needing to touch moonraker-obico's own source.
    #
    # Separately, that Janus binary is also missing several shared
    # library dependencies that aren't part of this project's normal
    # package list (confirmed via ldd): libconfig9, libnice10,
    # libsrtp2-1, libusrsctp2. All ordinary Debian bookworm packages.
    local janus_precompiled_dir="${HOME}/moonraker-obico/moonraker_obico/bin/janus/precomplied"
    ln -sf rpi.debian.12.64-bit "${janus_precompiled_dir}/NA.debian.12.64-bit"
    sudo apt-get install --yes libconfig9 libnice10 libsrtp2-1 libusrsctp2
}

function install_obico()
{
    local obico_dir="${HOME}/moonraker-obico"
    if [ ! -d "${obico_dir}" ]; then
        git clone https://github.com/TheSpaghettiDetective/moonraker-obico.git "${obico_dir}"
    fi

    cd "${obico_dir}"
    ./install.sh -L \
        -H 127.0.0.1 \
        -p 7125 \
        -C "${HOME}/printer_data/config/moonraker.conf" \
        -l "${HOME}/printer_data/logs" \
        -S "https://app.obico.io"

    fix_janus_live_streaming
}
