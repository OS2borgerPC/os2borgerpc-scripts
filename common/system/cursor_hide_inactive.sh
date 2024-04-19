#!/bin/sh
#
# Description: This script is used to hide the mouse cursor when it is inactive, both in kiosk and borgerpc.
# The default time for the cursor to be hidden is 5 seconds.
# It takes one parameter that can be True / False
#
# The borgerpc does not need a service to start the unclutter,
# it is an option set in the /etc/default/unclutter configuration file, look at the man page for more options.
#
# Note: The unclutter package has "unclutter-startup" as "recommends", which handles starting unclutter at
# startup via /etc/X11/Xsession.d/

set -x

ACTIVATE=$1

export DEBIAN_FRONTEND=noninteractive
PROGRAM="unclutter-xfixes"
FILE="/home/chrome/.xinitrc"

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
    IS_KIOSK="True"
fi

# Stop and remove the program
if [ "$ACTIVATE" = "False" ]; then

  if [ -n "$IS_KIOSK" ]; then
    sed --in-place "/$PROGRAM/d" $FILE
  fi

  pkill unclutter
  apt-get --assume-yes remove $PROGRAM
  exit 0
fi

# Install the program
apt-get update --assume-yes
apt-get install --assume-yes $PROGRAM

if [ -n "$IS_KIOSK" ]; then
    # 3 i means: Insert on line 3
    sed --in-place "3 i $PROGRAM &" $FILE
else
    if [ -n "$(users)" ]; then
      unclutter &
    fi
fi
