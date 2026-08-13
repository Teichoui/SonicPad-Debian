#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

SHELLTRAP=
source spinner.sh
source .config

# Validate directories
if [ -z "$ROOTFS_DIR" ]
then
    echo "\$ROOTFS_DIR is empty"
    exit;
fi
if [ -z "$BASEFS_DIR" ]
then
    echo "\$BASEFS_DIR is empty"
    exit;
fi
if [ -z "$ROOT_PASSWORD" ]
then
    echo "\$ROOT_PASSWORD is empty - refusing to chpasswd root with a blank password"
    exit 1
fi

echo "--------CONFIG---------"
echo "L_USERNAME: $L_USERNAME"
echo "DEB_DISTRO: $DEB_DISTRO"
echo "DEB_URL   : $DEB_URL"
echo "ROOTFS_DIR: $ROOTFS_DIR"
echo "BASEFS_DIR: $BASEFS_DIR"
echo "-----------------------"

# 0) Clear rootfs folder
if [ -d "$ROOTFS_DIR" ]
then
	if [ "$(ls -A "$ROOTFS_DIR")" ]; then
        echo "The dir: $ROOTFS_DIR is not empty, this script will delete it."
        read -p "Do you want to proceed? (y/n) " yn
        case "$yn" in
            [yY] ) echo ok, we will proceed;;
            [nN] ) echo exiting...;
                exit;;
            * ) echo invalid response;
                exit 1;;
        esac
	fi
fi

start_spinner "Removing old rootfs"
rm -rf "$ROOTFS_DIR"
stop_spinner

# 1) Create a basic rootfs
start_spinner "Creating a basic rootfs"
{
    apt-get update
    apt-get install qemu-user-static -y
    apt-get install debootstrap -y # Install only debootstrap, pi doesnt need it
    debootstrap --no-check-gpg --foreign --verbose --arch=arm64 "$DEB_DISTRO" "$ROOTFS_DIR" "$DEB_URL"
    sed -i "s/$DEB_DISTRO main/$DEB_DISTRO main contrib/" "$ROOTFS_DIR/etc/apt/sources.list"
    cp /usr/bin/qemu-arm-static "$ROOTFS_DIR/usr/bin/"
    chmod +x "$ROOTFS_DIR/usr/bin/qemu-arm-static"
} &> "$SHELLTRAP"
stop_spinner

echo "Done creating bare rootfs"

# 2) Run second stage bootstrao on rootfs
start_spinner "Running second stage"
{
    LC_ALL=C LANGUAGE=C LANG=C chroot "$ROOTFS_DIR" /debootstrap/debootstrap --second-stage --verbose
} &> "$SHELLTRAP"
stop_spinner

echo "Done running second stage"

# Bind-mount /proc, /sys, /dev into the chroot. Without this, anything
# relying on /proc/self/fd inside the chroot silently breaks - this is
# what "E: Can not write log (Is /dev/pts mounted?) - posix_openpt"
# has been warning about (harmlessly) in every apt call below, and
# what makes crowsnest's install script hard-fail later with
# "/dev/fd/63: No such file or directory" (it uses bash process
# substitution, `<(...)`, which needs /proc/self/fd to resolve
# /dev/fd/N). Standard practice for any real chroot build.
cleanup_chroot_mounts() {
    umount -l "$ROOTFS_DIR/dev/pts" 2>/dev/null || true
    umount -l "$ROOTFS_DIR/dev" 2>/dev/null || true
    umount -l "$ROOTFS_DIR/proc" 2>/dev/null || true
    umount -l "$ROOTFS_DIR/sys" 2>/dev/null || true
}
trap cleanup_chroot_mounts EXIT
mount --bind /dev "$ROOTFS_DIR/dev"
mount -t devpts devpts "$ROOTFS_DIR/dev/pts"
mount -t proc proc "$ROOTFS_DIR/proc"
mount -t sysfs sysfs "$ROOTFS_DIR/sys"

# # 3) Installing packages
start_spinner "Installing packages"
{
    LC_ALL=C LANGUAGE=C LANG=C chroot "$ROOTFS_DIR" apt update
    LC_ALL=C LANGUAGE=C LANG=C chroot "$ROOTFS_DIR" apt install git net-tools build-essential locales openssh-server wget libssl-dev sudo network-manager systemd-timesyncd u-boot-tools -y
} &> "$SHELLTRAP"
stop_spinner

echo "Done installing packages"

# 4) Copy our base filesystem
start_spinner "Copying base rootfs"
{
    cp -r "$BASEFS_DIR"/etc/* "$ROOTFS_DIR/etc/"
    cp -r "$BASEFS_DIR"/usr/local/bin/* "$ROOTFS_DIR/usr/local/bin/"
    cp -r "$BASEFS_DIR/lib/firmware/" "$ROOTFS_DIR/lib/"
    cp -r "$BASEFS_DIR/lib/modules/" "$ROOTFS_DIR/lib/"
} &> "$SHELLTRAP"
stop_spinner

echo "Done creating copying base rootfs"

# 5) Create default user
start_spinner "Creating default user"
{
    LC_ALL=C LANGUAGE=C LANG=C chroot "$ROOTFS_DIR" adduser --gecos "" --disabled-password "$L_USERNAME"
    LC_ALL=C LANGUAGE=C LANG=C chroot "$ROOTFS_DIR" chpasswd <<<"$L_USERNAME:$L_PASSWORD"
    LC_ALL=C LANGUAGE=C LANG=C chroot "$ROOTFS_DIR" /bin/bash -c "usermod -aG sudo $L_USERNAME"
    # docs/README.md documents root:$ROOT_PASSWORD as a working default
    # login, but nothing ever actually set root's password - debootstrap
    # leaves the root account locked (no valid password) by default, so
    # that documented login never worked. This is what issue #2 ("Wrong
    # Root Password") was actually reporting.
    LC_ALL=C LANGUAGE=C LANG=C chroot "$ROOTFS_DIR" chpasswd <<<"root:$ROOT_PASSWORD"
} &> "$SHELLTRAP"
stop_spinner

echo "Done creating rootfs"

start_spinner "Installing Klipper, Moonraker, KlipperScreen"
{
    cp -r scripts "$ROOTFS_DIR/home/$L_USERNAME/"
    chmod +x "$ROOTFS_DIR/home/$L_USERNAME"/scripts/*.sh
    LC_ALL=C LANGUAGE=C LANG=C chroot "$ROOTFS_DIR" /bin/bash -c "echo '$L_USERNAME ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
    LC_ALL=C LANGUAGE=C LANG=C chroot "$ROOTFS_DIR" /bin/su -c "cd /home/$L_USERNAME/scripts && ./install_services.sh" - "$L_USERNAME"
    LC_ALL=C LANGUAGE=C LANG=C chroot "$ROOTFS_DIR" /bin/bash -c "sed -i '$ d' /etc/sudoers"
    LC_ALL=C LANGUAGE=C LANG=C chroot "$ROOTFS_DIR" /bin/bash -c "rm -rf /home/$L_USERNAME/scripts"
    LC_ALL=C LANGUAGE=C LANG=C chroot "$ROOTFS_DIR" /bin/bash -c "echo '$L_USERNAME ALL = NOPASSWD:/bin/brightness' >> /etc/sudoers"
} &> "$SHELLTRAP"
stop_spinner

echo "Done installing services"
