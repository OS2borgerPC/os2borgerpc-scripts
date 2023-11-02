#! /usr/bin/env sh

# Adds/Removes programs from the launcher (menu) in Ubuntu 20.04
# Author: mfm@magenta.dk
#
# Arguments:
# 1: Use a boolean, if left unchecked the script removes the given program shortcut.
# 2: The name of the program you want to add/remove.

ADD=$1
PROGRAM=$2

CONFIG="/etc/dconf/db/os2borgerpc.d/02-launcher-favorites"

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

if [ -f "/var/lib/snapd/desktop/applications/${PROGRAM}_$PROGRAM.desktop" ]; then
  PROGRAM="${PROGRAM}_$PROGRAM"
fi

if [ "$ADD" = "True" ]; then

  # Append the program specified above to the menu/launcher
  # Why ']? To not also match the first (title) line.
  sed --in-place "s/'\]/', '$PROGRAM.desktop'\]/" $CONFIG

else

  # Remove the program specified above from the menu/launcher
  # First handle the case where it's the first program in the list
  # Then handle the cases where it's anything except the first
  sed --in-place --expression "s/\['$PROGRAM.desktop', /\[/" --expression "s/, '$PROGRAM.desktop'//g" $CONFIG

fi

dconf update
