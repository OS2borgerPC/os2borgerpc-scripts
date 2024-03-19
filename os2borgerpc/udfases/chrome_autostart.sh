#!/usr/bin/env sh

# SYNOPSIS
#    chrome_autostart - args[True/False)]
#
# DESCRIPTION
#    This script sets Google Chrome to autostart
#
# IMPLEMENTATION
#    copyright       Copyright 2019, Magenta Aps"
#    license         GNU General Public License

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

AUTOSTART_ENABLE=$1

DESKTOP_SYMLINK="/home/.skjult/.config/autostart/google-chrome.desktop"
DESKTOP_FILE="/usr/share/applications/google-chrome.desktop"
OLD_AUTOSTART_FILE="/home/.skjult/.config/autostart/chrome.desktop"

if [ "$AUTOSTART_ENABLE" = "True" ]; then
  printf "%s\n" "Adding Chrome to autostart"
  rm --force $DESKTOP_SYMLINK $OLD_AUTOSTART_FILE # First delete the old file if it exists, which may be a regular file or a symlink
  mkdir --parents /home/.skjult/.config/autostart
  ln -s  "$DESKTOP_FILE" "$DESKTOP_SYMLINK"
else
  printf  "%s\n" "Removing Chrome from autostart"
  rm "$DESKTOP_SYMLINK"
fi
