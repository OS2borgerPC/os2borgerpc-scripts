#! /usr/bin/env sh
#
# Toggles kiosk and/or incognito mode for OS2borgerPC Kiosk Chromium
# Why incognito?: If kiosk is disabled the browser will begin to remember
# cookies after restart. If you don't want that you can enable incognito.
#
# Arguments:
# 1: ACTIVATE_KIOSK: 'True' enables maximizing by default, 'False' disables it.
# 2: ACTIVATE_INKOG: 'True' enables incognito by default. 'False' disables it.
#
# Author: mfm@magenta.dk

set -ex

USER='chrome'
ACTIVATE_KIOSK=$1
ACTIVATE_INCOG=$2

FILE=/usr/share/os2borgerpc/bin/start_chromium.sh

if [ "$ACTIVATE_KIOSK" = 'True' ]; then
  # Don't add --kiosk multiple times
  if ! grep -q -- '--kiosk' $FILE; then
    sed -i 's/KIOSK=""/KIOSK="--kiosk"/' $FILE
  fi
else
  sed -i 's/--kiosk//g' $FILE
fi

if [ "$ACTIVATE_INCOG" = 'True' ]; then
  # Don't add --incognito multiple times
  if ! grep -q -- '--incognito' $FILE; then
    sed -i 's/INCOGNITO=""/INCOGNITO="--incognito"/' $FILE
  fi
else
  sed -i 's/--incognito//g' $FILE
fi
