#! /usr/bin/env sh

# Creates a customly named shortcut on the desktop for the normal user, which
# opens the URL given as an argument in the default browser.
#
# After the script has run log out or restart the computer for the changes to
# take effect.
#
# Dev note: If wanting to globally change the icon used look into
# shellscripts.png and application-x-shellscript.png
# within /usr/share/icons/Yaru/
#
# Arguments:
# 1: ACTIVATE: Use a boolean to decide whether to add or not. A checked box will
# add the shortcut and an unchecked will remove it
# 2: URL: The URL to visit when clicked
# 3: NAME: The name the shortcut should have - it needs to be a valid filename!
#
# Author: mfm@magenta.dk

set -x

ACTIVATE=$1
URL=$2
NAME=$3

SHADOW=".skjult"
FILE="/home/$SHADOW/Skrivebord/$NAME"

if [ "$ACTIVATE" = 'True' ]; then

	mkdir --parents /home/$SHADOW/Skrivebord

	cat <<- EOF > "$FILE"
		#! /usr/bin/env sh
		xdg-open "$URL"
	EOF

	chmod +x "$FILE"
else
	rm "$FILE"
fi
