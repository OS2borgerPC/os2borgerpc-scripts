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

# Determine the name of the user desktop directory. This is done via xdg-user-dir,
# which checks the /home/user/.config/user-dirs.dirs file. To ensure this file exists,
# we run xdg-user-dirs-update, which generates it based on the environment variable
# LANG. This variable is empty in lightdm so we first export it
# based on the value stored in /etc/default/locale
export "$(grep LANG= /etc/default/locale | tr -d '"')"
runuser -u user xdg-user-dirs-update
DESKTOP=$(basename "$(runuser -u user xdg-user-dir DESKTOP)")

SHADOW_DESKTOP="/home/.skjult/$DESKTOP"

mkdir --parents "$SHADOW_DESKTOP"

if [ "$ADD" = "True" ]; then
  # Note: "ln" doesn't care if the destination ($DIRECTORY) exists
  ln --symbolic --force "$DIRECTORY" "$SHADOW_DESKTOP/$SHORTCUT_NAME"
else
  rm "$SHADOW_DESKTOP/$SHORTCUT_NAME"
fi
