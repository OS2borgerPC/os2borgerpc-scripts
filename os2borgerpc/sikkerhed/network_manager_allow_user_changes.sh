#! /usr/bin/env sh

# Allows any user to manage network manager
#
# Arguments
#   1: Whether to enable or disable user access to modifying Network Manager settings
#      'True' enables, 'False' disables
#
# Author: mfm@magenta.dk

ACTIVATE="$1"

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

# Note to future dev: Method attempted which proved unsuccessful:
# 1. Add user to netdev, systemd-network or network groups
NETWORK_MANAGER_CONF=/etc/NetworkManager/NetworkManager.conf
# We used to use /var/lib for this one policy, whereas /etc were used for the rest. /etc/ takes precedence over
# /var/lib, so use that instead
NM_POLKIT_OLD=/var/lib/polkit-1/localauthority/50-local.d/networkmanager.pkla
NM_POLKIT_NEW=/etc/polkit-1/localauthority/50-local.d/networkmanager.pkla
mkdir --parents "$(dirname $NM_POLKIT_NEW)"

if [ -f $NM_POLKIT_OLD ]; then
  mv $NM_POLKIT_OLD $NM_POLKIT_NEW
fi

# Cleanup after previous runs of this script - or disable access if previously given (idempotency)
sed --in-place '/auth-polkit=false/d' $NETWORK_MANAGER_CONF
# Only make this replacement for user-related entries
sed --in-place '/unix-group:user/{ n; n; n; n; s/ResultActive=yes/ResultActive=no/ }' $NM_POLKIT_NEW

if [ "$ACTIVATE" = 'True' ]; then
  sed --in-place '/\[main\]/a\auth-polkit=false' $NETWORK_MANAGER_CONF
  # Only make this replacement for user-related entries
  sed --in-place '/unix-group:user/{ n; n; n; n; s/ResultActive=no/ResultActive=yes/ }' $NM_POLKIT_NEW
fi
