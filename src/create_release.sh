#!/bin/bash
# Info-Zip's `zip -s` split, recombined via `-s 0 --out`, was the
# original approach here - dropped after real testing (both locally
# and in CI) proved it corrupts the archive whenever a single entry's
# compressed data spans multiple split volumes, which it always does
# for an image this size. Confirmed independently by both `unzip -t`
# ("invalid compressed data to inflate" / "possible zip bomb") and
# Python's zipfile ("Overlapped entries"), and by comparing checksums
# of the recombined output against the original - they didn't match.
#
# Switched to 7z, and NOT splitting it at all: the compressed archive
# came out to ~808MB in a real CI run (524288000 + 323552441 bytes,
# two .7z.NNN volumes at the old 500m split size) against a 3.0GB
# source image - comfortably under GitHub's 2GB single-asset limit
# (2147483648 bytes), with enough headroom to absorb real growth
# before this needs revisiting. Splitting only existed historically
# because the image itself used to be far larger (~4.1GB, before the
# hard-link preservation fix) and that assumption was never
# rechecked. One file is simpler for users and removes the entire
# multi-volume-reassembly bug class this file's history is about. If
# the compressed size ever creeps close to 2GB again, `7z a -v500m`
# (still correct - verified via matching checksums after a full
# split/rejoin round trip) is the way back to multi-volume.

set -e

OUT_DIR=./out
BASE_NAME=debian_r818_sonic_lcd_uart0
ARCHIVE_NAME=$OUT_DIR/$BASE_NAME.7z
FINAL_IMG=$OUT_DIR/$BASE_NAME.img

7z a "$ARCHIVE_NAME" "$FINAL_IMG"
