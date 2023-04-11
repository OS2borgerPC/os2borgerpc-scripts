#! /usr/bin/env sh

EVDEV_FILE=/usr/share/X11/xorg.conf.d/10-evdev.conf

if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en regulær OS2borgerPC-maskine."
  exit 1
fi

mkdir "$(dirname $EVDEV_FILE)"

cat << EOF > $EVDEV_FILE
Section "InputClass"
        Identifier "evdev touchscreen catchall"
        MatchIsTouchscreen "on"
        MatchDevicePath "/dev/input/event*"
        Driver "evdev"
        Option "InvertY" "true"
        Option "InvertX" "true"
EndSection
EOF
