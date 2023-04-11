#!/usr/bin/env bash

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

# In 22.04 Firefox is a snap, in 20.04 it's an apt package.
# Once everyone has upgraded, support for the latter can be removed
if [ -d "/snap/firefox" ]; then
  sed -i "s/firefox_firefox/google-chrome/" /etc/dconf/db/os2borgerpc.d/02-launcher-favorites
else
  sed -i "s/firefox/google-chrome/" /etc/dconf/db/os2borgerpc.d/02-launcher-favorites
fi

dconf update
