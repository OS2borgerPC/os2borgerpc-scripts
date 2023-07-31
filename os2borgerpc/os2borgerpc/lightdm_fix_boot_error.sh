#! /usr/bin/env sh

set -x

ACTIVATE="$1"

LIGHTDM_CONF="/etc/lightdm/lightdm.conf"

if [ "$ACTIVATE" = "True" ]; then

  if ! grep -q -- "\[LightDM\]" "$LIGHTDM_CONF"; then
cat << EOF >> $LIGHTDM_CONF

[LightDM]
logind-check-graphical=true
EOF
  else
    echo "It appears as if the config file already contains the change?"
    exit 1
  fi

else
  # Delete the above lines (currently except the empty line)
  sed --in-place --expression '/\[LightDM\]/d' --expression '/logind-check-graphical/d' $LIGHTDM_CONF
fi
