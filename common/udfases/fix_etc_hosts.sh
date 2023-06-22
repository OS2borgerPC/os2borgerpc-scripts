#!/usr/bin/env sh

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

HOSTS=/etc/hosts

# Don't add 127.0.1.1 if it isn't already there
if grep --quiet 127.0.1.1 $HOSTS; then
  sed --in-place /127.0.1.1/d $HOSTS
  sed --in-place "2i 127.0.1.1	$(hostname)" $HOSTS
fi
