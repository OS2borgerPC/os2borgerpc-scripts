#! /usr/bin/env sh

# Lists programs available, programs on the desktop or in the launcher
# Author: mfm@magenta.dk
#
# Arguments
# 1: Default is to print programs available/installed. Write 'skrivebord' to list
#    programs already on the desktop, or "menu" to list programs in the launcher.

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

find_desktop_files_path() {
  PTH_LOCAL=$1
  # - shellcheck says find handles non-alphanumeric file names better than ls
  find "$PTH_LOCAL" -maxdepth 1 | grep --fixed-strings .desktop | xargs basename --suffix .desktop
}

LOCATION="$(lower "$1")"

SHADOW_DESKTOP=/home/.skjult/Skrivebord
SNAP_DESKTOP_FILE_PATH="/var/lib/snapd/desktop/applications"
APT_DESKTOP_FILE_PATH="/usr/share/applications"

if [ "$LOCATION" = "menu" ]; then
  # Print only the last line only and format it a bit more nicely
  tail -n 1 /etc/dconf/db/os2borgerpc.d/02-launcher-favorites | sed "s/favorite-apps=\[\|'\|\]\ \|.desktop//g" | tr ',' '\n'
  exit
elif [ "$LOCATION" = "skrivebord" ]; then
  PTH="$SHADOW_DESKTOP/"
else
  PTH=$APT_DESKTOP_FILE_PATH/
  find_desktop_files_path $SNAP_DESKTOP_FILE_PATH
fi

find_desktop_files_path "$PTH"
