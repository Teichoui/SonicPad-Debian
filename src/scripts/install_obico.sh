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
}
