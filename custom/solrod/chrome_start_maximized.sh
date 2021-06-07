#! /usr/bin/env sh

# Chrome launch maximized by default
# Arguments:
# 1: 'false/falsk/no/nej' disables maximizing by default, anything else enables it.

# Author: mfm@magenta.dk

set -x

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"

USER="user"
DESKTOP_FILE_PATH=/usr/share/applications/google-chrome.desktop
# In case they've also added Chrome to their desktop
DESKTOP_FILE_PATH2=/home/$USER/Skrivebord/google-chrome.desktop

if [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] && \
   [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then
  # Don't add --start-maximized multiple times
  if ! grep -q -- '--start-maximized' $DESKTOP_FILE_PATH; then
    sed -i 's,\(Exec=/usr/bin/google-chrome-stable\)\(.*\),\1 --start-maximized\2,' $DESKTOP_FILE_PATH
    sed -i 's,\(Exec=/usr/bin/google-chrome-stable\)\(.*\),\1 --start-maximized\2,' $DESKTOP_FILE_PATH2
  fi
else
  sed -i 's/ --start-maximized//g' $DESKTOP_FILE_PATH
  sed -i 's/ --start-maximized//g' $DESKTOP_FILE_PATH2
fi
