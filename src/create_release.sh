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
# First fix: switched to 7z, not split at all - the compressed archive
# came out to ~808MB in a real CI run against a 3.0GB source image,
# comfortably under GitHub's 2GB single-asset limit. Splitting only
# ever existed because the image itself used to be far larger (~4.1GB,
# before the hard-link preservation fix) and that assumption was never
# rechecked.
#
# Second fix (this one): switched from 7z back to plain zip. The
# corruption bug lived specifically in Info-Zip's `-s`/`-s 0 --out`
# split-to-single conversion code path - a normal, unsplit `zip`
# archive doesn't go anywhere near that path. Verified with the same
# create/extract/checksum-compare test used to find the original bug:
# a plain `zip` (no -s) round trip on the same test file produced
# matching checksums, no corruption. Since splitting isn't needed at
# the current size anyway, there's no reason to carry the 7z
# dependency (needs p7zip-full installed, and most users don't have a
# 7z-capable tool on hand) when zip is natively supported by Windows
# Explorer, macOS Archive Utility, and virtually every Linux desktop
# out of the box. If the compressed size ever creeps close to 2GB
# again, `7z a -v500m` (verified working for multi-volume - see PR
# #24's history) is the way back to splitting; plain zip has no
# built-in split mode worth trusting after what happened here.
#
# -j (junk paths) keeps the entry's stored name as just the base
# filename regardless of the caller's cwd, matching what the .sha256
# checksum file next to it is generated with (see release.yml) - both
# need to agree on the same portable name for `sha256sum -c` to work
# for a real user who has both files in one folder.

set -e

OUT_DIR=./out
BASE_NAME=debian_r818_sonic_lcd_uart0
ZIP_NAME=$OUT_DIR/$BASE_NAME.zip
FINAL_IMG=$OUT_DIR/$BASE_NAME.img

zip -j "$ZIP_NAME" "$FINAL_IMG"
