#! /usr/bin/env sh

# Disables Wayland in BorgerPC's Login / Display Manager
# Author: mfm@magenta.dk

DIR="/etc/lightdm/lightdm.conf.d"

mkdir --parents $DIR 

cat <<- EOF > $DIR/10-disable-wayland.conf
	# No /usr/share/wayland-sessions please
	[LightDM]
	sessions-directory=/usr/share/xsessions:/usr/share/lightdm/sessions
EOF
