#! /usr/bin/env sh

# Places a shortcut on the Desktop to any directory on the file system
#
# Parameters:
#   1: The path to the directory you want a shortcut to
#   2: The name of the shortcut on the Desktop

set -ex

DIRECTORY="$1"
SHORTCUT_NAME="$2"

ln -s  "$DIRECTORY" "/home/.skjult/Skrivebord/$SHORTCUT_NAME"
ln -s  "$DIRECTORY" "/home/user/Skrivebord/$SHORTCUT_NAME"
