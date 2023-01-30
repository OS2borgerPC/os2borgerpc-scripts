#!/usr/bin/env bash

if [ -d "/snap/firefox" ]; then
  sed -i "s/firefox_firefox/google-chrome/" /etc/dconf/db/os2borgerpc.d/02-launcher-favorites
else
  sed -i "s/firefox/google-chrome/" /etc/dconf/db/os2borgerpc.d/02-launcher-favorites
fi

dconf update
