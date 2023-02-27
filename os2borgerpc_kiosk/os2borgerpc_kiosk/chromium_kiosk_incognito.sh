#! /usr/bin/env sh
#
# Toggles kiosk and/or incognito mode for OS2borgerPC Kiosk Chromium
# Why incognito?: If kiosk is disabled the browser will begin to remember
# cookies after restart. If you don't want that you can enable incognito.
#
# Arguments:
# 1: KIOSK: 'True' enables maximizing by default, 'False' disables it.
# 2: INCOG: 'True' enables incognito by default. 'False' disables it.
#
# Author: mfm@magenta.dk

set -ex

KIOSK=$1
INCOG=$2

LAUNCH_FILE="/usr/share/os2borgerpc/bin/start_chromium.sh"
POLICY_FILE="/var/snap/chromium/current/policies/managed/os2borgerpc-defaults.json"
POLICY_NAME_INCOG="IncognitoModeAvailability"

# For removal or idempotency when adding
# TODO: If kiosk becomes settable via a Policy, use that instead!
sed --in-place 's/--kiosk//g' $LAUNCH_FILE

if [ "$KIOSK" = 'True' ]; then
  sed --in-place 's/KIOSK=""/KIOSK="--kiosk"/' $LAUNCH_FILE
fi

# For removal or idempotency when adding
sed --in-place "/$POLICY_NAME_INCOG/d" $POLICY_FILE

if [ "$INCOG" = 'True' ]; then
  # Insert this policy on line 2
  sed --in-place "2i\"$POLICY_NAME_INCOG\": 2," $POLICY_FILE
fi
