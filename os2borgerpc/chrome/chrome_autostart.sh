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

AUTOSTART_ENABLE=$1

DESKTOP_SYMLINK="/home/.skjult/.config/autostart/google-chrome.desktop"
DESKTOP_FILE="/usr/share/applications/google-chrome.desktop"

if [ "$AUTOSTART_ENABLE" = "True" ]; then
  printf "%s\n" "Adding Chrome to autostart"
  rm --force $DESKTOP_SYMLINK # First delete the old file if it exists, which may be a regular file or a symlink
  mkdir --parents /home/.skjult/.config/autostart
  ln -s  "$DESKTOP_FILE" "$DESKTOP_SYMLINK"
else
  printf  "%s\n" "Removing Chrome from autostart"
  rm "$DESKTOP_SYMLINK"
fi
