#! /usr/bin/env sh

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

ACTIVATE="$1"

CONF="/etc/lightdm/lightdm.conf.d/login-check-graphical.conf"

if [ "$ACTIVATE" = "True" ]; then

cat << EOF > $CONF
[LightDM]
logind-check-graphical=true
EOF

else
  rm --force $CONF
fi
