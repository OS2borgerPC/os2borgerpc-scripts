#! /usr/bin/env sh

# Chrome launch maximized, fullscreen or kiosk by default
# Applies to both the general .desktop file,
# the .desktop file that may have been added to the desktop
# and the .desktop file that may be used to autostart chrome.
#
# Arguments:
# 1:
#   Disable
#   Maximized
#   Fullscreen
#   Kiosk
#
# Takes effect after logout / restart.
#
# Author: mfm@magenta.dk

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

SETTING="$1"

SKEL=".skjult"
USER="user"
CHROME_ORIGINAL_FILE=/usr/share/applications/google-chrome.desktop
CHROME_DESKTOP_FILE_1=/home/$SKEL/.local/share/applications/google-chrome.desktop
# In case they've also added Chrome to their desktop
# Determine the name of the user desktop directory. This is done via xdg-user-dir,
# which checks the /home/user/.config/user-dirs.dirs file. To ensure this file exists,
# we run xdg-user-dirs-update, which generates it based on the environment variable
# LANG. This variable is empty in lightdm so we first export it
# based on the value stored in /etc/default/locale
export "$(grep LANG= /etc/default/locale | tr -d '"')"
runuser -u user xdg-user-dirs-update
DESKTOP=$(basename "$(runuser -u user xdg-user-dir DESKTOP)")
# TODO: Remove CHROME_DESKTOP_FILE_2 and CHROME_DESKTOP_FILE_3 logic as they're now symlinks to CHROME_DESKTOP_FILE_1
CHROME_DESKTOP_FILE_2=/home/$SKEL/$DESKTOP/google-chrome.desktop
CHROME_DESKTOP_FILE_3=/home/$SKEL/.config/autostart/google-chrome.desktop

# NOTE: We also update the original file hoping for the change to take effect without a restart. Subsequent system
# updates may overwrite the global .desktop file and that's no issue.
CHROMIUM_ORIGINAL_FILE=/var/lib/snapd/desktop/applications/chromium_chromium.desktop
CHROMIUM_SKEL_DESKTOP_FILE=/home/$SKEL/.local/share/applications/chromium_chromium.desktop

FILES="$CHROME_DESKTOP_FILE_1 $CHROME_DESKTOP_FILE_2 $CHROME_DESKTOP_FILE_3 $CHROMIUM_SKEL_DESKTOP_FILE $CHROMIUM_ORIGINAL_FILE"

# Ensure that the local copy exists
mkdir --parents "$(dirname "$CHROMIUM_SKEL_DESKTOP_FILE")" "$(dirname "$CHROMIUM_USER_DESKTOP_FILE")"
if [ -f $CHROME_ORIGINAL_FILE ] && [ ! -f "$CHROME_DESKTOP_FILE_1" ]; then
  cp "$CHROME_ORIGINAL_FILE" "$CHROME_DESKTOP_FILE_1"
fi
if [ -f $CHROMIUM_ORIGINAL_FILE ] && [ ! -f "$CHROMIUM_DESKTOP_FILE" ]; then
  cp "$CHROMIUM_ORIGINAL_FILE" "$CHROMIUM_SKEL_DESKTOP_FILE"
fi

# Takes a parameter to add to the Exec lines of the desktop files passed as the subsequent arguments
# The chromium Snap desktop file is quite differently formatted compared to a its non-Snap Exec line. Example:
# Exec=env BAMF_DESKTOP_FILE_HINT=/var/lib/snapd/desktop/applications/chromium_chromium.desktop /snap/bin/chromium --temp-profile
add_to_desktop_files() {
  PARAMETER="$1"
  shift # Now remove the parameter so we can loop over what remains: The files
  for FILE in "$@"; do
    # Only continue if the particular file exists
    if [ -f "$FILE" ]; then
      # Don't add the parameter multiple times
      if ! grep --quiet -- "$PARAMETER" "$FILE"; then
        if [ "$FILE" = $CHROMIUM_SKEL_DESKTOP_FILE ] || [ "$FILE" = $CHROMIUM_ORIGINAL_FILE ]; then
          sed --in-place "s,\(.*/snap/bin/chromium\)\(.*\),\1 $PARAMETER\2," "$FILE"
        else
          sed --in-place "s,\(Exec=\S*\)\(.*\),\1 $PARAMETER\2," "$FILE"
        fi
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
      sed --in-place "s/ $PARAMETER//g" "$FILE"
    fi
  done
}

# Old versions of Chrome autostart had this .desktop-file-name instead
OLD_DESKTOP_FILE="/home/.skjult/.config/autostart/chrome.desktop"
if [ -f $OLD_DESKTOP_FILE ]; then
  echo "Genkør venligst Chrome - Autostart tilføj/fjern"
  exit 1
fi

# Removes the old settings
# shellcheck disable=SC2086
remove_from_desktop_files "--start-maximized" $FILES
# shellcheck disable=SC2086
remove_from_desktop_files "--start-fullscreen" $FILES
# shellcheck disable=SC2086
remove_from_desktop_files "--kiosk" $FILES

# Setting the new setting, disable is handled above
if [ "$SETTING" = "maximized" ] || [ "$SETTING" = "fullscreen" ]; then
  # shellcheck disable=SC2086
  add_to_desktop_files "--start-$SETTING" $FILES
elif [ "$SETTING" = "kiosk" ]; then
  # shellcheck disable=SC2086
  add_to_desktop_files "--$SETTING" $FILES
fi

echo "For the changes to Chromium to take effect waiting a few seconds should be enough."
echo "For the changes to Chrome to take effect, you must logout and login again."
