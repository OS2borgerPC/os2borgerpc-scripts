#! /usr/bin/env bash

# Sets the default browser on a OS2borgerPC for the regular user
#
# Arguments:
# 1: Which browser to set as default.

set -ex

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

BROWSER="$(lower "$1")"

FILE="/etc/xdg/mimeapps.list"

# They can type in "chrome" but the desktop file is called google-chrome
# They can type in "edge" but the desktop file is called microsoft-edge
if [ "$BROWSER" = "chrome" ]; then
  BROWSER=google-chrome
elif [ "$BROWSER" = "edge" ]; then
  BROWSER=microsoft-edge
fi

# Handle snaps, which have names like firefox_firefox.desktop
if [ -d "/snap/$BROWSER" ]; then
  DESKTOP_FILE=${BROWSER}_$BROWSER.desktop
else
  DESKTOP_FILE=${BROWSER}.desktop
fi

# Make sure the file exists and has the correct header
if [ ! -f "$FILE" ]; then
  cat << EOF > $FILE
[Default Applications]
EOF
fi
# Cleanup the file to prevent duplicate lines
sed -i "\@text/html\|application/xhtml+xml\|x-scheme-handler/http\|x-scheme-handler/https@d" $FILE
# Now set the new default:
cat << EOF >> $FILE
application/xhtml+xml=$DESKTOP_FILE
text/html=$DESKTOP_FILE
x-scheme-handler/http=$DESKTOP_FILE
x-scheme-handler/https=$DESKTOP_FILE
EOF
