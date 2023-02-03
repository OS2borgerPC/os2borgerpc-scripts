#! /usr/bin/env sh

# Adds/Removes programs from the desktop in Ubuntu 20.04
# Author: mfm@magenta.dk
#
# Note that this script currently assumes danish locale, where the 'Desktop' directory
# is instead named 'Skrivebord'.
#
# Arguments:
# 1: Use a boolean to decide whether to add or remove the program shortcut
# 2: This argument should specify the name of a program (.desktop-file)
#    under /usr/share/applications/ or /var/lib/snapd/desktop/applications/
#    This parameter IS case-sensitive as some applications have
#    capitalized characters in their filename.

ADD="$1"
PROGRAM="$2"

SHADOW_DESKTOP="/home/.skjult/Skrivebord"
SNAP_DESKTOP_FILE_PATH="/var/lib/snapd/desktop/applications"
APT_DESKTOP_FILE_PATH="/usr/share/applications"

# TODO?: Make it replace all desktop icons which are copies with symlinks?

mkdir --parents $SHADOW_DESKTOP

if [ "$ADD" = 'True' ]; then
  if [ -f "$SNAP_DESKTOP_FILE_PATH/${PROGRAM}_$PROGRAM.desktop" ]; then
    DESKTOP_FILE=$SNAP_DESKTOP_FILE_PATH/${PROGRAM}_$PROGRAM.desktop
  else
    DESKTOP_FILE=$APT_DESKTOP_FILE_PATH/$PROGRAM.desktop
  fi

  # Remove it first as it may be a copy and not symlink (ln --force can't overwrite regular files)
  rm "$SHADOW_DESKTOP/$PROGRAM.desktop"

  ln --symbolic --force "$DESKTOP_FILE" $SHADOW_DESKTOP/
else
  if [ -f "$SHADOW_DESKTOP/${PROGRAM}_$PROGRAM.desktop" ]; then
    PROGRAM=${PROGRAM}_$PROGRAM
  fi
  rm --force "$SHADOW_DESKTOP/$PROGRAM.desktop"
fi
