#! /usr/bin/env sh

set -ex

SHORTCUT_NAME="$1"

# Determine the name of the user desktop directory. This is done via xdg-user-dir,
# which checks the /home/user/.config/user-dirs.dirs file. To ensure this file exists,
# we run xdg-user-dirs-update, which generates it based on the environment variable
# LANG. This variable is empty in lightdm so we first export it
# based on the value stored in /etc/default/locale
export "$(grep LANG= /etc/default/locale | tr -d '"')"
runuser -u user xdg-user-dirs-update
DESKTOP=$(basename "$(runuser -u user xdg-user-dir DESKTOP)")

SHADOW_USER=".skjult"
SHADOW_DESKTOP="/home/$SHADOW_USER/$DESKTOP"
AUTOSTART_DIR="/home/$SHADOW_USER/.config/autostart"

mkdir --parents $AUTOSTART_DIR

cp "$SHADOW_DESKTOP/$SHORTCUT_NAME.desktop" $AUTOSTART_DIR/
