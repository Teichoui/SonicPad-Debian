#!/bin/bash
# Installs crowsnest, the webcam streamer Moonraker/Mainsail/Fluidd
# expect. Without this, /dev/video0 (or whatever USB webcam is plugged
# in) is detected by the kernel but nothing ever streams it - the
# Webcam panel just sits empty, and the /webcam/ nginx location set up
# in install_webui.sh has nothing to proxy to.
#
# This only installs the service; it doesn't require a camera to be
# physically attached at build time; same as Klipper not needing a
# real MCU plugged in to install. It'll pick up whatever camera is
# actually connected once running on real hardware.

set -e

function install_crowsnest()
{
    local crowsnest_dir="${HOME}/crowsnest"
    if [ ! -d "${crowsnest_dir}" ]; then
        git clone https://github.com/mainsail-crew/crowsnest.git "${crowsnest_dir}"
    fi

    cd "${crowsnest_dir}"
    export CROWSNEST_UNATTENDED=1
    export CROWSNEST_ADD_CROWSNEST_MOONRAKER=1
    export CROWSNEST_SKIP_REBOOT_PROMPT=1
    sudo -E bash tools/install.sh
}
