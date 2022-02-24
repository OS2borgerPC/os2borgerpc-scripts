#! /usr/bin/env sh

# Allows any user to manage network manager
#
# Arguments
#   1: Whether to enable or disable user access to modifying Network Manager settings
#      'yes' enables, 'no' disables
#
# Author: mfm@magenta.dk

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"

# Note to future dev: Methods attempted which proved unsuccessful:
# 1. Add user to netdev, systemd-network or network groups
# 2. Modify polkit
FILE=/etc/NetworkManager/NetworkManager.conf

if [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] && \
   [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then
  sed --in-place '/[main]/a\auth-polkit=false' $FILE
else
  sed --in-place '/auth-polkit=false/d' $FILE
fi
