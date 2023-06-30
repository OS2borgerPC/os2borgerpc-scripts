#! /usr/bin/env sh

# The Xorg touch driver is called evdev. To find out what settings can be changed for evdev, see:
# $ man evdev

set -x

if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en regulær OS2borgerPC-maskine."
  exit 1
fi

ACTIVATE="$1"
INVERT="$2"
SWAP="$3"

# Ubuntus builtin Xorgs configs are in /usr/share/X11/xorg.conf.d - but user overrides usually go in /etc.
# Both dirs are read by Xorg.
OS2BPC_EVDEV_FILE=/etc/X11/xorg.conf.d/90-os2bpc-evdev.conf

if [ "$INVERT" = "True" ]; then
  # The indentation is kinda weird in this variable, but it makes it match up in the output file (8 spaces in front)
  INVERT_TEXT='Option "InvertY" "true"
        Option "InvertX" "true"'
fi

if [ "$SWAP" = "True" ]; then
  SWAP_TEXT='Option "SwapAxes" "true"'
fi

mkdir --parents "$(dirname $OS2BPC_EVDEV_FILE)"

if [ "$ACTIVATE" = "True" ]; then

cat <<- EOF > $OS2BPC_EVDEV_FILE
Section "InputClass"
        Identifier "evdev touchscreen catchall"
        MatchIsTouchscreen "on"
        MatchDevicePath "/dev/input/event*"
        Driver "evdev"
        $INVERT_TEXT
        $SWAP_TEXT
EndSection
EOF

echo "This is what the config file looks like after the change:"
cat $OS2BPC_EVDEV_FILE

else
  rm $OS2BPC_EVDEV_FILE
fi
