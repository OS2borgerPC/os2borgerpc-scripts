#! /usr/bin/env sh

set -ex

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "This script has not been designed to be run on a Kiosk-machine. Exiting."
  exit 1
fi

WAYLAND_FORCE="$1"

DISABLE_WAYLAND_FILE="/etc/lightdm/lightdm.conf.d/10-disable-wayland.conf"
DISABLE_XORG_FILE="/etc/lightdm/lightdm.conf.d/10-disable-xorg.conf"
LIGHTDM_CONF="/etc/lightdm/lightdm.conf"

if [ "$WAYLAND_FORCE" = "True" ]; then
  rm $DISABLE_WAYLAND_FILE

  # Remove the option to launch Xorg from LightDM
  cat << EOF > $DISABLE_XORG_FILE
# No /usr/share/xsessions please
[LightDM]
sessions-directory=/usr/share/wayland-sessions:/usr/share/lightdm/sessions
EOF

  # Stop launching Xorg-specific display-setup-script
  sed --in-place "\@/usr/share/os2borgerpc/bin/xset.sh@d" $LIGHTDM_CONF

else
  rm $DISABLE_XORG_FILE

  # Remove the option to launch Wayland from LightDM
  cat << EOF > $DISABLE_WAYLAND_FILE
# No /usr/share/wayland-sessions please
[LightDM]
sessions-directory=/usr/share/xsessions:/usr/share/lightdm/sessions
EOF

  # Start launching Xorg-specific display-setup-script, if it isn't already there
  if ! grep --quiet "/usr/share/os2borgerpc/bin/xset.sh" $LIGHTDM_CONF; then
    echo "display-setup-script=/usr/share/os2borgerpc/bin/xset.sh" >> $LIGHTDM_CONF
  fi
fi
