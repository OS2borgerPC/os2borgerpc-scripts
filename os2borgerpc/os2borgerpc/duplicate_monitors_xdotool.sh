#! /usr/bin/env sh

export DEBIAN_FRONTEND=noninteractive

FORCE_DUPLICATE_SCREENS="$1"

PKG_NAME="xdotool"
SKELETON_USER=".skjult"
AUTOSTART_DESKTOP_FILE="/home/$SKELETON_USER/.config/autostart/set_multiple_monitors_to_duplicate.desktop"
DUPLICATE_MONITORS_SCRIPT="/usr/share/os2borgerpc/bin/autostart_duplicate_monitors.sh"

set -x

mkdir --parents "$(dirname $AUTOSTART_DESKTOP_FILE)"

if [ "$FORCE_DUPLICATE_SCREENS" = "True" ]; then
  apt-get update
  apt-get install --assume-yes $PKG_NAME

  cat << EOF > $AUTOSTART_DESKTOP_FILE
[Desktop Entry]
Type=Application
Exec=$DUPLICATE_MONITORS_SCRIPT
EOF

  cat << EOF > $DUPLICATE_MONITORS_SCRIPT
#! /usr/bin/env sh

# A bit of delay to give the desktop a bit of time to load before trying to do the keybind combination
# Without it seemed to work less consistently
sleep 3
#xdotool keydown super && xdotool key p && sleep 3 && xdotool key --delay 100 p p && xdotool keyup super
# Strangely when you open the menu with the keybind, it starts on duplicate screens, even though "Extend screen" is the default.
xdotool keydown super key p && sleep 1 && xdotool key Left keyup super

# Equivalent ydotool command in case we want to switch to that when we switch to Wayland
# ydotool key 125:1 25:1 25:0 25:1 25:0 25:1 25:0 125:0
EOF

  chmod o+x $DUPLICATE_MONITORS_SCRIPT
else
  rm --force $AUTOSTART_DESKTOP_FILE
  # Leaving it installed in case other scripts use it...?
fi
