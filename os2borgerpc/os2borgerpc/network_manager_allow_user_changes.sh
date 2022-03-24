#! /usr/bin/env sh

# Allows any user to manage network manager
#
# Arguments
#   1: Whether to enable or disable user access to modifying Network Manager settings
#      'True' enables, 'False' disables
#
# Author: mfm@magenta.dk

ACTIVATE="$1"

# Note to future dev: Method attempted which proved unsuccessful:
# 1. Add user to netdev, systemd-network or network groups
FILE=/etc/NetworkManager/NetworkManager.conf

# Cleanup after previous runs of this script - or disable access if previously given (idempotency)
sed --in-place '/auth-polkit=false/d' $FILE

if [ "$ACTIVATE" = 'True' ]; then
  sed --in-place '/\[main\]/a\auth-polkit=false' $FILE
fi
