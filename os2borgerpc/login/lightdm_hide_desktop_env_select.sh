#!/usr/bin/env bash

set -x

# The options shown by the button to select desktop environment are determined
# by the .desktop-files in /usr/share/xsessions or /usr/share/wayland-sessions
# depending on whether xorg or wayland is being used. If we hide all but one
# .desktop-file, the button is automatically hidden because there is only
# one option.
# The two standard .desktop-files in both folders run the exact same commands
# so it doesn't matter which file we hide.

ACTIVATE=$1

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "This script has not been designed to be run on a Kiosk-machine. Exiting."
  exit 1
fi

XORG_FILE="/usr/share/xsessions/ubuntu-xorg.desktop"
XORG_HIDDEN_FILE="/usr/share/xsessions/hidden/ubuntu-xorg.desktop"
WAYLAND_FILE="/usr/share/wayland-sessions/ubuntu-wayland.desktop"
WAYLAND_HIDDEN_FILE="/usr/share/wayland-sessions/hidden/ubuntu-wayland.desktop"

mkdir --parents "$(dirname "$XORG_HIDDEN_FILE")" "$(dirname "$WAYLAND_HIDDEN_FILE")"

if [ "$ACTIVATE" = "True" ]; then
  if [ -f "$XORG_FILE" ]; then
    dpkg-divert --rename --divert "$XORG_HIDDEN_FILE" --add "$XORG_FILE"
  fi
  if [ -f "$WAYLAND_FILE" ]; then
    dpkg-divert --rename --divert "$WAYLAND_HIDDEN_FILE" --add "$WAYLAND_FILE"
  fi
else
  if [ -f "$XORG_HIDDEN_FILE" ]; then
    dpkg-divert --rename --remove "$XORG_FILE"
  fi
  if [ -f "$WAYLAND_HIDDEN_FILE" ]; then
    dpkg-divert --rename --remove "$WAYLAND_FILE"
  fi
fi
