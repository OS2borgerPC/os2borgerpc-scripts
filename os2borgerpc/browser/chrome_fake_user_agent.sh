#!/usr/bin/env bash

set -x

ACTIVATE=$1

SHADOW=".skjult"

export "$(grep LANG= /etc/default/locale | tr -d '"')"
runuser -u user xdg-user-dirs-update
DESKTOP=$(basename "$(runuser -u user xdg-user-dir DESKTOP)")

USER_AGENT="Mozilla\/5.0 (Windows NT 10.0\; Win64\; x64) AppleWebKit\/537.36 (KHTML\, like Gecko) Chrome\/119.0.0.0 Safari\/537.36"
DESKTOP_FILE_1="/usr/share/applications/google-chrome.desktop"
DESKTOP_FILE_2="/home/$SHADOW/$DESKTOP/google-chrome.desktop"
DESKTOP_FILE_3="/home/$SHADOW/.config/autostart/google-chrome.desktop"
FILES="$DESKTOP_FILE_1 $DESKTOP_FILE_2 $DESKTOP_FILE_3"

# Takes a parameter to add to Chrome and a list of .desktop files to add it to
add_to_desktop_files() {
  PARAMETER="$1"
  shift # Now remove the parameter so we can loop over what remains: The files
  for FILE in "$@"; do
    # Only continue if the particular file exists
    if [ -f "$FILE" ]; then
      # Don't add the parameter multiple times
      if ! grep --quiet -- "$PARAMETER" "$FILE"; then
        sed --in-place "s,\(Exec=\S*\)\(.*\),\1 $PARAMETER\2," "$FILE"
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

if [ "$ACTIVATE" = "True" ]; then
  # shellcheck disable=SC2086 # We want to split the files back into separate arguments
  add_to_desktop_files "--user-agent='$USER_AGENT'" $FILES
else
  # shellcheck disable=SC2086 # We want to split the files back into separate arguments
  remove_from_desktop_files "--user-agent='$USER_AGENT'" $FILES
fi
