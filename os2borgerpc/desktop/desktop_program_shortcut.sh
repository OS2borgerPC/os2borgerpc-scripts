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

set -x

ADD="$1"
PROGRAM="$2"

SHADOW=".skjult"

# TODO?: Make it replace all desktop icons which are copies with symlinks?

mkdir --parents /home/$SHADOW/Skrivebord

if [ "$ADD" = 'True' ]; then
  if [ -f "/var/lib/snapd/desktop/applications/${PROGRAM}_$PROGRAM.desktop" ]; then
    DESKTOP_FILE=/var/lib/snapd/desktop/applications/${PROGRAM}_$PROGRAM.desktop
  else
    DESKTOP_FILE=/usr/share/applications/$PROGRAM.desktop
  fi

  # Remove it first as it may be a copy and not symlink (ln --force can't overwrite regular files)
  rm "/home/$SHADOW/Skrivebord/$PROGRAM.desktop"

  ln --symbolic --force "$DESKTOP_FILE" /home/$SHADOW/Skrivebord/
else
  if [ -f "/home/$SHADOW/Skrivebord/${PROGRAM}_$PROGRAM.desktop" ]; then
    PROGRAM=${PROGRAM}_$PROGRAM
  fi
  rm --force "/home/$SHADOW/Skrivebord/$PROGRAM.desktop"
fi
