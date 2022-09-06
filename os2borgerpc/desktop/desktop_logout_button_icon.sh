#! /usr/bin/env sh

# Arguments:
# 1: The name the shortcut should have on the desktop.
# 2: A boolean to decide whether to prompt before logging out or log out immediately
# 3: An optional icon to use for the shortcut. Ideally SVG, but PNG and JPG work as well.

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
	ICON="system-log-out"
else
	# HANDLE ICON HERE
	if ! echo "$ICON_UPLOAD" | grep --quiet '.png\|.svg\|.jpg\|.jpeg'; then
		printf "Error: Only .svg, .png, .jpg and .jpeg are supported as icon-formats."
		exit 1
	else
		ICON_BASE_PATH=/usr/local/share/icons
		ICON_NAME="$(basename "$ICON_UPLOAD")"
		mkdir --parents "$ICON_BASE_PATH"
		# Copy icon from the default destination to where it should actually be
		cp "$ICON_UPLOAD" $ICON_BASE_PATH
		# Two ways to reference an icons:
		# 1. As a full path to the icon including it's extension. This works for PNG, SVG, JPG
		# 2. As a name without path and extension, likely as long as it's within an icon cache path. This works for PNG, SVG - but not JPG!
		ICON=$ICON_BASE_PATH/$ICON_NAME

		update-icon-caches $ICON_BASE_PATH
	fi
fi

cat <<- EOF > $DESKTOP_FILE
	[Desktop Entry]
	Version=1.0
	Type=Application
	Name=$SHORTCUT_NAME
	Comment=Logud
	Icon=$ICON
	Exec=gnome-session-quit --logout $TO_PROMPT_OR_NOT
EOF
