#!/usr/bin/env sh

set -x

# Set some required variables to be able to run xrandr from root
USER=chrome
export DISPLAY=:0
export XAUTHORITY=/home/$USER/.Xauthority

if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en regulær OS2borgerPC-maskine."
  exit 1
fi

echo "DEBUG: Print some info from xrandr before attempting to turn on monitors:"
xrandr

ALL_MONITORS=$(xrandr | grep ' connected' | cut --delimiter ' ' --fields 1)
FIRST_MONITOR=$(echo "$ALL_MONITORS" | head -n 1)
OTHER_MONITORS=$(echo "$ALL_MONITORS" | tail -n +2)
echo "$OTHER_MONITORS" | xargs -I {} xrandr --output {} --same-as "$FIRST_MONITOR"

echo "DEBUG: Print some info from xrandr after attempting to turn on monitors:"
xrandr
