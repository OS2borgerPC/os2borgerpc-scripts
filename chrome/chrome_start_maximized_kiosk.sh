#! /usr/bin/env sh

# Chrome launch maximized or kiosk by default
#
# Arguments:
# 1: 'false/falsk/no/nej' disables maximizing by default, anything else enables it.
# 2: 'false/falsk/no/nej' disables kiosk by default, anything else enables it.
#
# Takes effect after logout / restart.
#
# Author: mfm@magenta.dk

set -x

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

MAXIMIZE="$(lower "$1")"
KIOSK="$(lower "$2")"

USER=".skjult"
DESKTOP_FILE_PATH=/usr/share/applications/google-chrome.desktop
# In case they've also added Chrome to their desktop
DESKTOP_FILE_PATH2=/home/$USER/Skrivebord/google-chrome.desktop

# MAXIMIZE
if [ "$MAXIMIZE" != 'false' ] && [ "$MAXIMIZE" != 'falsk' ] && \
   [ "$MAXIMIZE" != 'no' ] && [ "$MAXIMIZE" != 'nej' ]; then
  # Don't add --start-maximized multiple times
  if ! grep -q -- '--start-maximized' $DESKTOP_FILE_PATH; then
    sed -i 's,\(Exec=/usr/bin/google-chrome-stable\)\(.*\),\1 --start-maximized\2,' $DESKTOP_FILE_PATH
    sed -i 's,\(Exec=/usr/bin/google-chrome-stable\)\(.*\),\1 --start-maximized\2,' $DESKTOP_FILE_PATH2
  fi
else
  sed -i 's/ --start-maximized//g' $DESKTOP_FILE_PATH
  sed -i 's/ --start-maximized//g' $DESKTOP_FILE_PATH2
  true
fi

# KIOSK
if [ "$KIOSK" != 'false' ] && [ "$KIOSK" != 'falsk' ] && \
   [ "$KIOSK" != 'no' ] && [ "$KIOSK" != 'nej' ]; then
  # Don't add --kiosk multiple times
  if ! grep -q -- '--kiosk' $DESKTOP_FILE_PATH; then
    sed -i 's,\(Exec=/usr/bin/google-chrome-stable\)\(.*\),\1 --kiosk\2,' $DESKTOP_FILE_PATH
    sed -i 's,\(Exec=/usr/bin/google-chrome-stable\)\(.*\),\1 --kiosk\2,' $DESKTOP_FILE_PATH2
  fi
else
  sed -i 's/ --kiosk//g' $DESKTOP_FILE_PATH
  sed -i 's/ --kiosk//g' $DESKTOP_FILE_PATH2
  true
fi
