#!/bin/sh
# Wrapper script to run DLNA Player with proper locale for media_kit
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec env LC_NUMERIC=C LC_ALL=C "$SCRIPT_DIR/build/linux/x64/release/bundle/dlna_player.bin" "$@"
