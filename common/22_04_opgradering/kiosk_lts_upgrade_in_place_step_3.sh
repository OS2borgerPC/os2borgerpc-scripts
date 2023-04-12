#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    kiosk_lts_upgrade_in_place_step_3.sh
#%
#% DESCRIPTION
#%    Step three of the upgrade from 20.04 to 22.04.
#%    Designed for Kiosk machines
#%
#================================================================
#- IMPLEMENTATION
#-    version         kiosk_lts_upgrade_in_place_step_3.sh 0.0.1
#-    author          Andreas Poulsen
#-    copyright       Copyright 2022, Magenta Aps
#-    license         BSD/MIT
#-    email           info@magenta.dk
#-
#================================================================
#  HISTORY
#     2022/12/08 : ap : Script creation
#
#================================================================
# END_OF_HEADER
#================================================================

set -ex

if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en regulær OS2borgerPC-maskine."
  exit 1
fi

PREVIOUS_STEP_DONE="/etc/os2borgerpc/second_upgrade_step_done"
if [ ! -f "$PREVIOUS_STEP_DONE" ]; then
  echo "22.04 opgradering - Opgradering til Ubuntu 22.04 trin 2 er ikke blevet gennemført."
  exit 1
fi

# Make double sure that the crontab has been emptied
TMP_ROOTCRON=/etc/os2borgerpc/tmp_rootcronfile
if [ -f "$TMP_ROOTCRON" ]; then
  crontab -r || true
fi

# Prevent the upgrade from removing python while we are using it to run jobmanager
apt-mark hold python3.8

# Make sure release-upgrade prompt is not never so that the upgrade can run
# Also set the prompt to lts so that the upgrader will only look for lts releases
release_upgrades_file=/etc/update-manager/release-upgrades

sed -i "s/Prompt=.*/Prompt=lts/" $release_upgrades_file

# Perform the actual upgrade with some error handling
do-release-upgrade -f DistUpgradeViewNonInteractive >  /var/log/os2borgerpc_upgrade_1.log || true

apt-get --assume-yes --fix-broken install || true
apt-get --assume-yes autoremove || true
apt-get --assume-yes clean || true
apt-get --assume-yes install --upgrade python3-pip || true

# Make sure that jobmanager can still find the client
PIP_ERRORS="False"
pip install -q os2borgerpc_client || PIP_ERRORS="True"

if [ "$PIP_ERRORS" == "True" ]; then
  mkdir --parents /usr/local/lib/python3.10
  cp --recursive --no-clobber /usr/local/lib/python3.8/dist-packages/ /usr/local/lib/python3.10/
fi

if ! lsb_release -d | grep --quiet 22; then
  echo "Opgraderingen er ikke blevet gennemført. Prøv at genstarte computeren og køre dette script igen."
  exit 1
fi

rm --force $PREVIOUS_STEP_DONE

touch /etc/os2borgerpc/third_upgrade_step_done
