#! /usr/bin/env sh

set -ex

SHORTCUT_NAME="$1"

SHADOW_USER=".skjult"
SHADOW_DESKTOP="/home/$SHADOW_USER/Skrivebord"
AUTOSTART_DIR="/home/$SHADOW_USER/.config/autostart"

mkdir --parents $AUTOSTART_DIR

cp "$SHADOW_DESKTOP/$SHORTCUT_NAME.desktop" $AUTOSTART_DIR/
