#! /usr/bin/env sh

# Author: mfm@magenta.dk
# Credits: Vordingborg Kommune
#
# Arguments:
# 1: Use a boolean to decide whether to add or remove the button
# 2: The name the button should have on the desktop.
#    If you choose deletion, the contents of the name argument does not matter.

ACTIVATE=$1
NAME="$2"

OLD_DESKTOP_FILE=/home/.skjult/Skrivebord/Logout.desktop
DESKTOP_FILE=/home/.skjult/Skrivebord/logout.desktop

rm --force "$OLD_DESKTOP_FILE"

if [ "$ACTIVATE" = 'True' ]; then
	mkdir --parents "$(dirname $DESKTOP_FILE)"

	cat <<- EOF > $DESKTOP_FILE
		[Desktop Entry]
		Version=1.0
		Type=Application
		Name=$NAME
		Comment=Logout-funktion
		Icon=application-exit
		Exec=gnome-session-quit --logout --no-prompt
	EOF

else
	rm "$DESKTOP_FILE"
fi
