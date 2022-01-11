#! /usr/bin/env sh

# Sets the default browser on a OS2borgerPC for the regular user
#
# Arguments:
# 1: Which browser to set as default.
#    Options are: 'firefox' or 'chrome'

set -ex

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

BROWSER="$(lower "$1")"

FILE="/usr/share/applications/defaults.list"

if [ "$BROWSER" = "firefox" ]; then
  DESKTOP_FILE=firefox.desktop
elif [ "$BROWSER" = "chrome" ]; then
  DESKTOP_FILE=google-chrome.desktop
else
  printf "%s\n" "Ugyldigt input. Gyldige valgmuligheder er 'firefox' eller 'chrome'."
  exit 1
fi

# We cleanup the defaults.list as sometimes it seems to be populated with multiple lines for the same type, which messes things up!
sed -i "\@text/html\|application/xhtml+xml\|application/xml\|x-scheme-handler/http\|x-scheme-handler/https@d" $FILE

# Now set the new default:
cat <<- EOF >> $FILE
	application/xhtml+xml=$DESKTOP_FILE
	text/html=$DESKTOP_FILE
	application/xml=$DESKTOP_FILE
	x-scheme-handler/http=$DESKTOP_FILE
	x-scheme-handler/https=$DESKTOP_FILE
EOF