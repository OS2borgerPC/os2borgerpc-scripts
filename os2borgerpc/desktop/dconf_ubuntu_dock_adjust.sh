#! /usr/bin/env sh

# Moves the Ubuntu dock system wide to an edge of your choosing, and possibly the app launcher to the start of the menu instead of the end (default)
# If it doesn't take effect immediately, try restarting.
#
# Arguments:
#   1: Where the dock/menu should be located. Valid options are: top, left, right, bottom.
#   2: Where the app launcher should be located in the menu. Valid options are: true (top), false (bottom - which is default)
#
# Author: mfm@magenta.dk
# Credits: Gladsaxe Kommune

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "This script is not designed to be run on a Kiosk machine."
  exit 1
fi

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

# gsettings equivalent: gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM
POSITION="$1"
APPS_LAUNCHER_AT_TOP="$(lower "$2")" # Expects True/False, case insensitively

POLICY_FILE_NAME="03-menu-position"

cat <<- EOF > /etc/dconf/db/os2borgerpc.d/$POLICY_FILE_NAME
  [org/gnome/shell/extensions/dash-to-dock]
  dock-position='$POSITION'
  show-apps-at-top=$APPS_LAUNCHER_AT_TOP
EOF

cat <<- EOF > /etc/dconf/db/os2borgerpc.d/locks/$POLICY_FILE_NAME
  /org/gnome/shell/extensions/dash-to-dock/dock-position
  /org/gnome/shell/extensions/dash-to-dock/show-apps-at-top
EOF

dconf update
