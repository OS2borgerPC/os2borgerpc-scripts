#! /usr/bin/env sh

# Sets the default browser on a OS2borgerPC for the regular user
#
# Arguments:
# 1: Which browser to set as default.

set -ex

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

BROWSER="$(lower "$1")"

FILE="/usr/share/applications/defaults.list"

# They can type in "chrome" but the desktop file is called google-chrome
if [ "$BROWSER" = "chrome" ]; then
  BROWSER=google-chrome
fi

# Handle snaps, which have names like firefox_firefox.desktop
if [ -d "/snap/$BROWSER" ]; then
	DESKTOP_FILE=${BROWSER}_$BROWSER.desktop
else
	DESKTOP_FILE=${BROWSER}.desktop
fi

# We cleanup the defaults.list as sometimes it seems to be populated
# with multiple lines for the same MIME type, which messes things up!
sed -i "\@text/html\|application/xhtml+xml\|application/xml\|x-scheme-handler/http\|x-scheme-handler/https@d" $FILE

# Now set the new default:
cat <<- EOF >> $FILE
	application/xhtml+xml=$DESKTOP_FILE
	text/html=$DESKTOP_FILE
	application/xml=$DESKTOP_FILE
	x-scheme-handler/http=$DESKTOP_FILE
	x-scheme-handler/https=$DESKTOP_FILE
EOF