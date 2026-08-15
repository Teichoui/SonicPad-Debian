#!/bin/bash

set -e

# shellcheck disable=SC2034 # consumed by install_klipper.sh/install_klipperscreen.sh/install_moonraker.sh, sourced below into this same shell
INSTALLER_DIR="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
# shellcheck disable=SC2034 # consumed by install_klipper.sh/install_moonraker.sh, sourced below into this same shell
SYSTEMD="/etc/systemd/system"
USER=$(whoami)

echo "Adding hostname to hosts"
sudo -- sh -c "echo '127.0.1.1 SonicPad' >> /etc/hosts"

source ./install_klipper.sh
source ./install_moonraker.sh
source ./install_klipperscreen.sh
source ./install_webui.sh
source ./install_crowsnest.sh

echo "Installing Klipper"
install_klipper

echo "Installing Moonraker"
install_moonraker

echo "Installing Klipperscreen"
install_klipperscreen

echo "Installing web UI (Mainsail, optionally Fluidd)"
install_webui

echo "Installing crowsnest (webcam streamer)"
install_crowsnest

# moonraker-obico (AI print failure detection) is NOT installed here -
# it's opt-in, same as Fluidd, but pulled from the device itself rather
# than baked into the image: KIAUH (see docs/README.md) already has a
# moonraker-obico extension. base_rootfs/usr/local/bin/fix_obico_janus_
# streaming.sh ships on every image regardless, so that path works
# correctly once a user installs it - see that script for why.
sudo chmod +x /usr/local/bin/fix_obico_janus_streaming.sh

echo "Enabling depmod service"
sudo chmod +x /usr/local/bin/depmod_enable.sh
sudo systemctl enable depmod_boot

echo "Enabling expandfs"
sudo chmod +x /usr/local/bin/expandfs_enable.sh
sudo systemctl enable expandfs

echo "Enabling per-device WiFi MAC regeneration"
sudo chmod +x /usr/local/bin/regen_wifi_mac.sh
sudo systemctl enable regen_wifi_mac

echo "Enabling LED EMMC"
sudo chmod +x /usr/local/bin/ledmmc_enable.sh
sudo systemctl enable ledmmc

echo "Enabling USB Host"
sudo chmod +x /usr/local/bin/usbhost_enable.sh
sudo systemctl enable usbhost

echo "Enabling screen timeout script"
sudo chmod +x /usr/local/bin/display-sleep.sh
sudo systemctl enable display-sleep.service 

# echo "Running depmod"
# sudo depmod 4.9.191

echo "Fixing networking..."
sudo -- sh -c "echo 'ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev' > /etc/wpa_supplicant/wpa_supplicant.conf"
sudo usermod -aG netdev $USER

echo "Compiling brightness..."
sudo chown -R $USER /home/$USER/scripts
cd /home/$USER/scripts/resources/brightness
gcc -o brightness brightness.c
sudo mv brightness /bin/brightness

echo "Cleaning up cache"
sudo apt clean
sudo rm -rf /var/cache/apt/
sudo rm -rf ~/.cache

sudo update-ca-certificates
sudo c_rehash
