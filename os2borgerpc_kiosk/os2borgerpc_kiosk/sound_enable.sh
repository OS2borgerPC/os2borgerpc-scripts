#! /usr/bin/env sh

set -x

# Activate sound in OS2BorgerPC Booking (Ubuntu Server)
# Reboot afterwards for it to take effect.
# Arguments:
#   1. What command to run: 0-1

ACTIVATE=$1

export DEBIAN_FRONTEND=noninteractive
FILE=/home/chrome/.xinitrc

if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en regulær OS2borgerPC-maskine."
  exit 1
fi

# Clean up after previous versions of this script
sed -in-place '/pactl/d' $FILE

if [ "$ACTIVATE" = "True" ]; then
    apt-get update --assume-yes
    apt-get install --assume-yes pulseaudio
else
  apt-get remove --assume-yes pulseaudio
fi
