#!/usr/bin/env sh

set -x

ACTIVATE=$1
WIDTH=$2
HEIGHT=$3

RESOLUTION_FILE="/etc/X11/xorg.conf.d/resolution.conf"

run_xrandr() {
  if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
    USR="chrome"
  else
    USR="user"
  fi

  export DISPLAY=:0
  export XAUTHORITY=/home/$USR/.Xauthority
  echo "The valid resolutions are shown on the left in the list below:"
  xrandr
}

if [ "$2" != "" ] && [ "$ACTIVATE" = "True" ]; then
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
elif [ "$ACTIVATE" = "True" ]; then
  run_xrandr && exit
else
  rm --force $RESOLUTION_FILE
fi
