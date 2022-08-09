#! /usr/bin/env sh

# Arguments:
# 1: The name the buttons should have on the desktop.
# 2: Use a boolean to decide whether to prompt before logging out
# 3: The icon to use for the button. Ideally SVG, but PNG works as well.

set -x

SHORTCUT_NAME="$1"
PROMPT=$2
ICON_UPLOAD="$3"

DESKTOP_FILE=/home/.skjult/Skrivebord/Logout.desktop
mkdir --parents "$(dirname $DESKTOP_FILE)"

TO_PROMPT_OR_NOT=--no-prompt

if [ "$PROMPT" = "True" ]; then
	# If they DO want the prompt
	unset TO_PROMPT_OR_NOT
fi

if [ -z "$ICON_UPLOAD" ]; then
	ICON_NAME="system-log-out"
else
	# HANDLE ICON HERE
	if ! echo "$ICON_UPLOAD" | grep --quiet '.png\|.svg'; then
    printf "Error: Only .svg and .png, are supported as icon-formats."
		exit 1
	else
		ICON_BASE_PATH=/usr/local/share/icons
		mkdir --parents "$ICON_BASE_PATH"
		# Copy icon from the default destination to where it should actually be
		cp "$ICON_UPLOAD" $ICON_BASE_PATH
		# A .desktop file apparently expects an icon without an extension
		ICON_NAME="$(basename "$ICON_UPLOAD" | sed -e 's/\.[^.]*$//')"

		update-icon-caches $ICON_BASE_PATH
	fi
fi

cat <<- EOF > $DESKTOP_FILE
	[Desktop Entry]
	Version=1.0
	Type=Application
	Name=$SHORTCUT_NAME
	Comment=Logud
	Icon=$ICON_NAME
	Exec=gnome-session-quit --logout $TO_PROMPT_OR_NOT
EOF
