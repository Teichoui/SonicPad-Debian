#!/bin/bash
# Info-Zip's `zip -s` split, recombined via `-s 0 --out`, was the
# original approach here - dropped after real testing (both locally
# and in CI) proved it corrupts the archive whenever a single entry's
# compressed data spans multiple split volumes, which it always does
# for an image this size. Confirmed independently by both `unzip -t`
# ("invalid compressed data to inflate" / "possible zip bomb") and
# Python's zipfile ("Overlapped entries"), and by comparing checksums
# of the recombined output against the original - they didn't match.
# This has nothing to do with the 4GB ZIP64 threshold (reproduced on a
# throwaway 600MB file too); it's a genuine bug in Info-Zip's
# split-to-single conversion. 7z's native multi-volume archives
# (`-v500m`) don't have this problem - verified the same way, with
# matching checksums after a `7z a -v.../7z x` round trip.

set -e

OUT_DIR=./out
BASE_NAME=debian_r818_sonic_lcd_uart0
ARCHIVE_NAME=$OUT_DIR/$BASE_NAME.7z
FINAL_IMG=$OUT_DIR/$BASE_NAME.img
MB_BLOCK=500m

7z a -v$MB_BLOCK "$ARCHIVE_NAME" "$FINAL_IMG"
