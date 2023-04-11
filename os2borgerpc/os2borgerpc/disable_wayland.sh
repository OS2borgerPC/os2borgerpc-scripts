#! /usr/bin/env sh

# Disables Wayland in BorgerPC's Login / Display Manager
# Author: mfm@magenta.dk

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

DIR="/etc/lightdm/lightdm.conf.d"

mkdir --parents $DIR 

cat <<- EOF > $DIR/10-disable-wayland.conf
	# No /usr/share/wayland-sessions please
	[LightDM]
	sessions-directory=/usr/share/xsessions:/usr/share/lightdm/sessions
EOF
