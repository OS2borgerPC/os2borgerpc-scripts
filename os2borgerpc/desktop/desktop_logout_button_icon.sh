#! /usr/bin/env sh

# Author: mfm@magenta.dk
#
# Arguments:
# 1: The name the buttons should have on the desktop.
# 2: Use a boolean to decide whether to prompt before logging out
# 3: The icon to use for the button. Ideally SVG, but PNG works as well.


set -x

NAME="$1"
PROMPT=$2
ICON_UPLOAD=$3

FILE_PATH=/home/.skjult/Skrivebord/Logout.desktop
mkdir --parents "$(dirname $FILE_PATH)"

TO_PROMPT_OR_NOT=--no-prompt

if [ "$PROMPT" = "True" ]; then
	# If they DO want the prompt
	unset TO_PROMPT_OR_NOT
fi

# HANDLE ICON HERE
if ! echo "$ICON_UPLOAD" | grep --quiet '.png\|.svg\|.jpg'; then
	printf "Fejl: Kun .svg, .png og .jpg understøttes som ikon-formater."
	exit 1
else
	ICON_BASE_PATH=/usr/local/share/icons/
	mkdir --parents "$ICON_BASE_PATH"
	# Copy icon from the default destination to where it should actually be
	cp "$ICON_UPLOAD" $ICON_BASE_PATH
	# A .desktop file apparently expects an icon without an extension
	ICON_NAME="$(basename "$ICON_UPLOAD" | sed -e 's/.png|.svg|.jpg//')"

	update-icon-caches $ICON_BASE_PATH
fi

cat <<- EOF > $FILE_PATH
	[Desktop Entry]
	Version=1.0
	Type=Application
	Name=$NAME
	Comment=Logud
	Icon=$ICON_BASE_PATH$ICON_NAME
	Exec=gnome-session-quit --logout $TO_PROMPT_OR_NOT
EOF
