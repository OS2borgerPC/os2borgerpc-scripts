#! /usr/bin/env sh

# Chrome launch maximized, fullscreen or kiosk by default
# Applies to both the general .desktop file,
# the .desktop file that may have been added to the desktop
# and the .desktop file that may be used to autostart chrome.
#
# Arguments:
# 1:
#   0: Disable all three (default for Chrome)
#   1: Maximized
#   2: Full screen
#   3: Kiosk
#
#
# Takes effect after logout / restart.
#
# Author: mfm@magenta.dk

set -x

SETTING="$1"

USER=".skjult"
DESKTOP_FILE_1=/usr/share/applications/google-chrome.desktop
# In case they've also added Chrome to their desktop
DESKTOP_FILE_2=/home/$USER/Skrivebord/google-chrome.desktop
# In case they've run chrome_autostart.sh.
# The name is no mistake, that one is not called google-chrome.desktop
DESKTOP_FILE_3=/home/$USER/.config/autostart/google-chrome.desktop
DESKTOP_FILE_4=/home/$USER/.local/share/applications/google-chrome.desktop
FILES="$DESKTOP_FILE_1 $DESKTOP_FILE_2 $DESKTOP_FILE_3 $DESKTOP_FILE_4"

# Takes a parameter to add to Chrome and a list of .desktop files to add it to
add_to_desktop_files() {
  PARAMETER="$1"
  shift # Now remove the parameter so we can loop over what remains: The files
  for FILE in "$@"; do
    # Only continue if the particular file exists
    if [ -f "$FILE" ]; then
      # Don't add the parameter multiple times
      if ! grep -q -- "$PARAMETER" "$FILE"; then
        sed -i "s,\(Exec=/usr/bin/google-chrome-stable\)\(.*\),\1 $PARAMETER\2," "$FILE"
      fi
    fi
  done
}

# Takes a parameter to remove and a list of .desktop files to remove it from
remove_from_desktop_files() {
  PARAMETER="$1"
  shift # Now remove the parameter so we can loop over what remains: The files
  for FILE in "$@"; do
    # Only continue if the particular file exists
    if [ -f "$FILE" ]; then
      sed -i "s/ $PARAMETER//g" "$FILE"
    fi
  done
}

case "$SETTING" in
  0) # Disable all three
    # shellcheck disable=SC2086 # We want to split the files back into separate arguments
    remove_from_desktop_files "--start-maximized" $FILES
    # shellcheck disable=SC2086
    remove_from_desktop_files "--start-fullscreen" $FILES
    # shellcheck disable=SC2086
    remove_from_desktop_files "--kiosk" $FILES
    ;;
  1) # MAXIMIZE
    # shellcheck disable=SC2086
    add_to_desktop_files "--start-maximized" $FILES
    # shellcheck disable=SC2086
    remove_from_desktop_files "--start-fullscreen" $FILES
    # shellcheck disable=SC2086
    remove_from_desktop_files "--kiosk" $FILES
    ;;
  2) # FULLSCREEN
    # shellcheck disable=SC2086
    remove_from_desktop_files "--start-maximized" $FILES
    # shellcheck disable=SC2086
    add_to_desktop_files "--start-fullscreen" $FILES
    # shellcheck disable=SC2086
    remove_from_desktop_files "--kiosk" $FILES
    ;;
  3) # KIOSK
    # shellcheck disable=SC2086
    remove_from_desktop_files "--start-maximized" $FILES
    # shellcheck disable=SC2086
    remove_from_desktop_files "--start-fullscreen" $FILES
    # shellcheck disable=SC2086
    add_to_desktop_files "--kiosk" $FILES
    ;;
  *)
    printf "%s
    " "Ugyldigt parameter: Det skal v??re enten 0 (alle sl??et fra), 1 (maksimeret), 2 (fuld sk??rm) eller 3 (kiosk)."
    exit 1
    ;;
esac
