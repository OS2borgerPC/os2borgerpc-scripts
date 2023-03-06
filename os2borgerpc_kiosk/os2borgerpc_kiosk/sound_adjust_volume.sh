#! /usr/bin/env sh

# Set the desired sink to the desired volume.
#
# Arguments:
#   1: The sink to adjust the volume for
#   2: The desired volume percentage, excluding the percent sign, ie. just an integer.
#
# Author: mfm@magenta.dk

SINK=$1  # AKA audio device
REQUESTED_VOLUME_PERCENTAGE=$2

OUR_USER=chrome
FILE=/home/$OUR_USER/.xinitrc

if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en regulær OS2borgerPC-maskine."
  exit 1
fi

# Remove previous volume line for that sink
sed --in-place "/pactl set-sink-volume $SINK/d" $FILE
# Add a new one with the new volume setting
sed --in-place "/pactl set-sink-mute/a\pactl set-sink-volume $SINK $REQUESTED_VOLUME_PERCENTAGE%" $FILE
