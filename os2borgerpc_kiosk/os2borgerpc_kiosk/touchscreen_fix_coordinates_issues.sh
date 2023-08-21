#! /usr/bin/env sh

# The Xorg touch driver is called evdev. To find out what settings can be changed for evdev, see:
# $ man evdev

set -x

#if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
#  echo "Dette script er ikke designet til at blive anvendt på en regulær OS2borgerPC-maskine."
#  exit 1
#fi

ACTIVATE="$1"
INVERT="$2"
ORIENTATION="$3"

# Ubuntus builtin Xorgs configs are in /usr/share/X11/xorg.conf.d - but user overrides usually go in /etc.
# Both dirs are read by Xorg.
OS2BPC_EVDEV_FILE=/etc/X11/xorg.conf.d/90-os2bpc-evdev.conf

if [ -z "$ORIENTATION" ]; then
  ORIENTATION="normal"
fi

# To understand the necessary transformation matrix, perform the following thought experiment:
# Imagine the coordinate system that represents the intended operation of the screen,
# then determine how this must be rotated to match the coordinate system that would represent
# the operation of the screen if its orientation was normal. If the axes also need to be inverted,
# rotate by an extra 180 degrees. The necessary transformation matrix represents the total rotation
if [ "$INVERT" = "True" ] && [ "$ORIENTATION" = "normal" ]; then
  TEXT='Option "TransformationMatrix" "-1 0 1 0 -1 1 0 0 1"'
elif { [ "$INVERT" = "True" ] && [ "$ORIENTATION" = "left" ]; } || { [ "$INVERT" = "False" ] && [ "$ORIENTATION" = "right" ]; }; then
  TEXT='Option "TransformationMatrix" "0 1 0 -1 0 1 0 0 1"'
elif { [ "$INVERT" = "True" ] && [ "$ORIENTATION" = "right" ]; } || { [ "$INVERT" = "False" ] && [ "$ORIENTATION" = "left" ]; }; then
  TEXT='Option "TransformationMatrix" "0 -1 1 1 0 0 0 0 1"'
else
  TEXT=""
fi

mkdir --parents "$(dirname $OS2BPC_EVDEV_FILE)"

if [ "$ACTIVATE" = "True" ]; then

cat <<- EOF > $OS2BPC_EVDEV_FILE
Section "InputClass"
        Identifier "evdev touchscreen catchall"
        MatchIsTouchscreen "on"
        MatchDevicePath "/dev/input/event*"
        Driver "evdev"
        $TEXT
EndSection
EOF

echo "This is what the config file looks like after the change:"
cat $OS2BPC_EVDEV_FILE

else
  rm $OS2BPC_EVDEV_FILE
fi
