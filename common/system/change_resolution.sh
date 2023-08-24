#!/usr/bin/env bash

set -x

ACTIVATE=$1
WIDTH=$2
HEIGHT=$3

RESOLUTION_FILE="/etc/X11/xorg.conf.d/resolution.conf"

if [ "$ACTIVATE" = "True" ]; then
  # Make sure the folder exists
  mkdir --parents "$(dirname $RESOLUTION_FILE)"

  # Write the .conf-file
  cat <<EOF > $RESOLUTION_FILE
Section "Screen"
  Identifier "Screen0"
  Subsection "Display"
    Modes "${WIDTH}x${HEIGHT}"
  EndSubSection
EndSection
EOF
else
  rm --force $RESOLUTION_FILE
fi
echo "The valid resolutions are shown on the left in the list below:"
xrandr
