#!/usr/bin/env bash

sed -i "s/firefox/google-chrome/" /etc/dconf/db/os2borgerpc.d/02-launcher-favorites

dconf update
