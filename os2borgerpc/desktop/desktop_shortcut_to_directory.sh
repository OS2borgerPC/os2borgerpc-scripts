#! /usr/bin/env sh

# Places a shortcut on the Desktop to any directory on the file system
#
# Parameters:
#   1: The path to the directory you want a shortcut to
#   2: The name of the shortcut on the Desktop

set -ex

DIRECTORY="$1"
SHORTCUT_NAME="$2"

SHADOW_DESKTOP="/home/.skjult/Skrivebord"

mkdir --parents $SHADOW_DESKTOP

# Note: "ln" doesn't care if the destination ($DIRECTORY) exists
ln --symbolic --force "$DIRECTORY" "$SHADOW_DESKTOP/$SHORTCUT_NAME"
