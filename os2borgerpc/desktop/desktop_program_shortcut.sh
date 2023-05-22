#! /usr/bin/env sh

# Adds/Removes programs from the desktop in Ubuntu 20.04
# Author: mfm@magenta.dk
#
# This script has been updated to automatically detect the name of
# the 'Desktop' directory in the chosen locale.
#
# Arguments:
# 1: Use a boolean to decide whether to add or remove the program shortcut
# 2: This argument should specify the name of a program (.desktop-file)
#    under /usr/share/applications/ or /var/lib/snapd/desktop/applications/
#    This parameter IS case-sensitive as some applications have
#    capitalized characters in their filename.

ADD="$1"
PROGRAM="$2"

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

# Determine the name of the user desktop directory. This is done via xdg-user-dir,
# which checks the /home/user/.config/user-dirs.dirs file. To ensure this file exists,
# we run xdg-user-dirs-update, which generates it based on the environment variable
# LANG. This variable is empty in lightdm so we first export it
# based on the value stored in /etc/default/locale
export "$(grep LANG= /etc/default/locale | tr -d '"')"
runuser -u user xdg-user-dirs-update
DESKTOP=$(basename "$(runuser -u user xdg-user-dir DESKTOP)")

SHADOW_DESKTOP="/home/.skjult/$DESKTOP"
SNAP_DESKTOP_FILE_PATH="/var/lib/snapd/desktop/applications"
APT_DESKTOP_FILE_PATH="/usr/share/applications"

# TODO?: Make it replace all desktop icons which are copies with symlinks?

mkdir --parents "$SHADOW_DESKTOP"

if [ "$ADD" = 'True' ]; then
  if [ -f "$SNAP_DESKTOP_FILE_PATH/${PROGRAM}_$PROGRAM.desktop" ]; then
    DESKTOP_FILE=$SNAP_DESKTOP_FILE_PATH/${PROGRAM}_$PROGRAM.desktop
  else
    DESKTOP_FILE=$APT_DESKTOP_FILE_PATH/$PROGRAM.desktop
  fi

  # Remove it first as it may be a copy and not symlink (ln --force can't overwrite regular files)
  rm --force "$SHADOW_DESKTOP/$PROGRAM.desktop"

  ln --symbolic --force "$DESKTOP_FILE" "$SHADOW_DESKTOP"/
else
  if [ -f "$SHADOW_DESKTOP/${PROGRAM}_$PROGRAM.desktop" ]; then
    PROGRAM=${PROGRAM}_$PROGRAM
  fi
  rm --force "$SHADOW_DESKTOP/$PROGRAM.desktop"
fi
