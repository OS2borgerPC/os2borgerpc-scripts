#! /usr/bin/env sh

# Disables Wayland in BorgerPC's Login / Display Manager
# Author: mfm@magenta.dk

cat << EOF > /etc/lightdm/lightdm.conf.d/10-disable-wayland.conf
# No /usr/share/wayland-sessions please
[LightDM]
sessions-directory=/usr/share/xsessions:/usr/share/lightdm/sessions
EOF
