#! /usr/bin/env sh

# Places a shortcut on the Desktop to any directory on the file system
#
# Parameters:
#   1: Whether to add or remove the shortcut
#   2: The path to the directory you want a shortcut to
#   3: The name of the shortcut on the Desktop

set -ex

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

ADD="$1"
DIRECTORY="$2"
SHORTCUT_NAME="$3"

SHADOW_DESKTOP="/home/.skjult/Skrivebord"

mkdir --parents $SHADOW_DESKTOP

if [ "$ADD" = "True" ]; then
  # Note: "ln" doesn't care if the destination ($DIRECTORY) exists
  ln --symbolic --force "$DIRECTORY" "$SHADOW_DESKTOP/$SHORTCUT_NAME"
else
  rm "$SHADOW_DESKTOP/$SHORTCUT_NAME"
fi
