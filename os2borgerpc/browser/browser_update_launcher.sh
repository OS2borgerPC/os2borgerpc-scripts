#!/usr/bin/env bash

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

TARGET_BROWSER=$1

DCONF_POLICY="/etc/dconf/db/os2borgerpc.d/02-launcher-favorites"

# This check is here so they can't end up in a situation where the default browser is set to something invalid, and its
# now impossible to fix it via this script because what's replaced is hardcoded
if [ "$TARGET_BROWSER" != "firefox" ] \
  && [ "$TARGET_BROWSER" != "google-chrome" ] \
  && [ "$TARGET_BROWSER" != "microsoft-edge" ] \
  && [ "$TARGET_BROWSER" != "chromium" ]; then
  echo "Requested browser - $TARGET_BROWSER - is not a valid option. See the script description for valid options."
  exit 1
fi

# In 22.04 Firefox is a snap, in 20.04 it's an apt package.
# Once everyone has upgraded, support for the latter can be removed
# Chromium is a snap in both 20.04 and 22.04
if [ -d "/snap/$TARGET_BROWSER" ]; then
  TARGET_BROWSER="${TARGET_BROWSER}_$TARGET_BROWSER"
fi

if [ -d "/snap/firefox" ]; then
  FIREFOX_REPLACEMENT="firefox_firefox"
else
  FIREFOX_REPLACEMENT="firefox"
fi

sed --in-place \
  --expression "s/$FIREFOX_REPLACEMENT/$TARGET_BROWSER/g" \
  --expression "s/google-chrome/$TARGET_BROWSER/g" \
  --expression "s/microsoft-edge/$TARGET_BROWSER/g" \
  --expression "s/chromium_chromium/$TARGET_BROWSER/g" \
  $DCONF_POLICY

dconf update
