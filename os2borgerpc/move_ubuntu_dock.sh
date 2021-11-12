#! /usr/bin/env sh

# Moves the Ubuntu dock system wide to an edge of your choosing
# If it doesn't take effect immediately try restarting.
#
# Arguments:
#   1: Where it should be located. Valid options are: top, left, right, bottom.
#
# Author: mfm@magenta.dk
# Credits: Gladsaxe Kommune

upper() {
    echo "$@" | tr '[:lower:]' '[:upper:]'
}

# gsettings equivalent: gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM
POSITION="$(upper "$1")"

if [ "$POSITION" = "TOP" ] || [ "$POSITION" = "LEFT" ] || [ "$POSITION" = "RIGHT" ] || [ "$POSITION" = "BOTTOM" ]; then
	cat <<- EOF > /etc/dconf/db/os2borgerpc.d/03-menu-position
		[org/gnome/shell/extensions/dash-to-dock]
		dock-position='$POSITION'
	EOF

	dconf update
else
  printf "Invalid value. Valid values are: top, left, right, bottom"
  exit 1
fi
