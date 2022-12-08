#! /usr/bin/env sh

EVDEV_FILE=/usr/share/X11/xorg.conf.d/10-evdev.conf

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
