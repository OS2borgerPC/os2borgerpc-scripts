#! /usr/bin/env sh

# Disables Wayland in BorgerPC's Login / Display Manager

cat << EOF >> /etc/lightdm/lightdm.conf

# No /usr/share/wayland-sessions please
[LightDM]
sessions-directory=/usr/share/xsessions:/usr/share/lightdm/sessions
EOF
