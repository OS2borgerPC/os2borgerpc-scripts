#! /usr/bin/env sh

# Adds/Removes programs from the launcher (menu) in Ubuntu 20.04
# Author: mfm@magenta.dk
#
# Arguments:
# 1: Use a boolean, if left unchecked the script removes the given program shortcut.
# 2: The name of the program you want to add/remove.

ADD=$1
PROGRAM=$2

if [ -f "/var/lib/snapd/desktop/applications/${PROGRAM}_$PROGRAM.desktop" ]; then
  PROGRAM="${PROGRAM}_$PROGRAM"
fi

if [ "$ADD" = "True" ]; then

  # Append the program specified above to the menu/launcher
  # Why ']? To not also match the first (title) line.
  sed -i "s/'\]/', '$PROGRAM.desktop'\]/" /etc/dconf/db/os2borgerpc.d/02-launcher-favorites

else

  # Remove the program specified above from the menu/launcher
  sed -i "s/, '$PROGRAM.desktop'//" /etc/dconf/db/os2borgerpc.d/02-launcher-favorites

fi

dconf update
