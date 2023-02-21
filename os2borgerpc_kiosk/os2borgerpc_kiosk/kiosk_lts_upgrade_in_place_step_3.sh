#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    kiosk_lts_upgrade_in_place_3.sh
#%
#% DESCRIPTION
#%    Step three of the upgrade from 20.04 to 22.04.
#%    Designed for Kiosk machines
#%
#================================================================
#- IMPLEMENTATION
#-    version         lts_upgrade_in_place_step_3.sh 0.0.1
#-    author          Carsten Agger, Marcus Funch Mogensen
#-    modified by     Andreas Poulsen
#-    copyright       Copyright 2020, Magenta Aps
#-    license         BSD/MIT
#-    email           info@magenta.dk
#-
#================================================================
#  HISTORY
#     2022/12/08 : ap : Modified to upgrade from 20.04 to 22.04
#     2021/03/19 : mfm : Add OS2display migration
#     2021/01/13 : carstena : Script creation
#
#================================================================
# END_OF_HEADER
#================================================================

set -ex

if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en regulær borgerPC-maskine."
  exit 1
fi

# Make double sure that the crontab has been emptied
TMP_ROOTCRON=/etc/os2borgerpc/tmp_rootcronfile
if [ -f "$TMP_ROOTCRON" ]; then
  crontab -r || true
fi

# Prevent the upgrade from removing python while we are using it to run jobmanager
apt-mark hold python3.8

# Perform the actual upgrade with some error handling
ERRORS="False"
do-release-upgrade -f DistUpgradeViewNonInteractive >  /var/log/os2borgerpc_upgrade_1.log || ERRORS="True"

# Make sure that jobmanager can still find the client
pip install -q os2borgerpc_client

if [ "$ERRORS" == "True" ]; then
  apt-get --assume-yes --fix-broken install
  apt-get --assume-yes autoremove
  apt-get --assume-yes clean
fi
