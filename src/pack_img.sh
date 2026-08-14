#!/bin/bash

set -e

SHELLTRAP=
source spinner.sh

# ---------------------------------------
KERNEL_ARCHIIVE=./archives/kernel_tools.tar.gz
PREBUILT_KERNEL=./prebuilt_kernel
TEMP_DIR=./temp
TOOLS_DIR=$PREBUILT_KERNEL/tools
ROOTFS_IMG=$PREBUILT_KERNEL/images/rootfs.img
ROOTFS_DIR=./rootfs
EXT4_IMG=$TEMP_DIR/rootfs.ext4
MOUNT_POINT=$TEMP_DIR/mount-point
OUT_DIR="./out"
IMAGE_NAME=tina_r818-sonic_lcd_uart0.img
OUT_IMAGE_NAME=debian_r818_sonic_lcd_uart0.img
OG_USER=${SUDO_USER:-$(whoami)}
# ---------------------------------------

# ---------------- IMG config------------
# This is scratch space for the copy step below, not the final shipped
# image size - "Resizing img" further down runs `resize2fs -M`, which
# shrinks the filesystem back down to just fit the actual content
# before packing. So a generous IMG_SIZE here costs nothing on the
# real device, it just needs to be big enough to hold the rootfs
# during the copy.
#
# 4GB (the old value) was too small: a real CI build now includes
# Klipper+Moonraker+KlipperScreen+crowsnest+moonraker-obico+Mainsail/
# Fluidd, which measured ~5.5-6.3GB installed on a live device (verified
# via `du -sh` over SSH, 2026-08-13) - the copy step was failing
# partway through with "No space left on device". Bumped with headroom.
IMG_SIZE=8000000000
#IMG_SIZE=2684354560
BLOCKS=4096
INODES_RATIO=16384
INODES=$(($IMG_SIZE / $INODES_RATIO))
#----------------------------------------

echo "Rootfs content size: $(du -sh $ROOTFS_DIR 2>/dev/null | cut -f1) (must fit within IMG_SIZE=$IMG_SIZE bytes during the copy step below)"

start_spinner "Extracting kernel tools"
{
    rm -rf $PREBUILT_KERNEL
    mkdir -p $PREBUILT_KERNEL
    tar -xzf $KERNEL_ARCHIIVE -C $PREBUILT_KERNEL
} &> $SHELLTRAP

start_spinner "Creating ext4 partition"
{
    mkdir -p $TEMP_DIR
    rm -f $EXT4_IMG
    $TOOLS_DIR/make_ext4fs -l $IMG_SIZE -b $BLOCKS -i $INODES -m 0 $EXT4_IMG #The "dragon" doesnt like images made without their stupid tool
    rm -f $ROOTFS_IMG
    dd if=$EXT4_IMG of=$ROOTFS_IMG bs=128k conv=sync
    rm -f $EXT4_IMG
} &> $SHELLTRAP
stop_spinner

echo "Done creating ext4 partition"

echo "=== Hard-link stats in source rootfs (diagnosing image size) ==="
hardlinked_files=$(find $ROOTFS_DIR -type f -links +1 2>/dev/null | wc -l)
echo "Files with more than 1 hard link: $hardlinked_files"
if [ "$hardlinked_files" -gt 0 ]; then
    apparent_extra=$(find $ROOTFS_DIR -type f -links +1 -printf '%s\n' 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    echo "Combined size of those files (each additional link duplicates this if not preserved): ${apparent_extra} bytes"
fi

start_spinner "Copying partitions"
{
    mkdir -p $MOUNT_POINT
    mount -o loop $ROOTFS_IMG $MOUNT_POINT
    # cp -rfp does NOT preserve hard links (-p only covers mode/
    # ownership/timestamps) - a real Debian install hard-links many
    # files (docs, locale data, etc), so without -a/--preserve=links
    # each additional link gets copied as an independent full file,
    # inflating the final image well beyond the source's actual
    # (hard-link-deduplicated) du -sh size. -a is a superset of -rfp
    # that also preserves links/symlinks.
    cp -a $ROOTFS_DIR/* $MOUNT_POINT
    umount $MOUNT_POINT
    rm -r $MOUNT_POINT
} &> $SHELLTRAP
stop_spinner

echo "Done copying rootfs"

start_spinner "Fixing img"
{
    set +e
    tune2fs -O^resize_inode $ROOTFS_IMG
    e2fsck -yf $ROOTFS_IMG
    fsck.ext4 $ROOTFS_IMG
    set -e
} &> $SHELLTRAP
stop_spinner

echo "Done fixing img"

start_spinner "Resizing img"
{
    resize2fs -M $ROOTFS_IMG
} &> $SHELLTRAP
stop_spinner

echo "Done Resizing img"
echo "=== ext4 stats after resize2fs -M (diagnosing why the final image is larger than the actual rootfs content) ==="
dumpe2fs -h $ROOTFS_IMG 2>&1 || true
ls -la $ROOTFS_IMG

start_spinner "Packing image"
{
    cd $PREBUILT_KERNEL
    ./tools/dragon image.cfg sys_partition_for_dragon.fex
} &> $SHELLTRAP
stop_spinner

echo "Done Packing image"

start_spinner "Moving our final image"
{
    cd ../
    mkdir -p $OUT_DIR
    rm -f $OUT_DIR/$IMAGE_NAME
    mv $PREBUILT_KERNEL/$IMAGE_NAME $OUT_DIR/$OUT_IMAGE_NAME
    chown $OG_USER $OUT_DIR/$OUT_IMAGE_NAME
} &> $SHELLTRAP
stop_spinner

echo "Done moving our final image"
