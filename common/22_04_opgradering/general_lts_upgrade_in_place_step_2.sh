#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    general_lts_upgrade_in_place_step_2.sh
#%
#% DESCRIPTION
#%    Step two of the upgrade from 20.04 to 22.04.
#%
#================================================================
#- IMPLEMENTATION
#-    version         general_lts_upgrade_in_place_step_2.sh 0.0.1
#-    author          Andreas Poulsen
#-    copyright       Copyright 2022, Magenta Aps
#-    license         BSD/MIT
#-    email           info@magenta.dk
#-
#================================================================
#  HISTORY
#     2022/09/15 : ap : Script creation
#
#================================================================
# END_OF_HEADER
#================================================================

set -ex

PREVIOUS_STEP_DONE="/etc/os2borgerpc/first_upgrade_step_done"
if [ ! -f "$PREVIOUS_STEP_DONE" ]; then
  echo "22.04 opgradering - Opgradering til Ubuntu 22.04 trin 1 er ikke blevet gennemført."
  exit 1
fi

# Make double sure that the crontab has been emptied
TMP_ROOTCRON=/etc/os2borgerpc/tmp_rootcronfile
if [ -f "$TMP_ROOTCRON" ]; then
  crontab -r || true
  if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
    crontab -u user -r || true
  fi
fi

# Fix dpkg settings to avoid interactivity.
cat << EOF > /etc/apt/apt.conf.d/local
Dpkg::Options {
   "--force-confdef";
   "--force-confold";
};
Dpkg::Lock {Timeout "3600";};
EOF

# Prevent timezone issues
hwclock --hctosys

# Stop Debconf from doing anything
export DEBIAN_FRONTEND=noninteractive

# Resync the local package index from its remote counterpart
apt-get --assume-yes update

# Attempt to fix broken or interrupted installations
apt-get --assume-yes --fix-broken install

# Remove unnecessary applications
apt-get -y remove --purge remmina transmission-gtk apport whoopsie

# Run available updates in preparation for the release-upgrade
apt-get --assume-yes upgrade

apt-get --assume-yes dist-upgrade

# Remove packages only installed as dependencies, which are no longer dependencies
apt-get --assume-yes autoremove

# Remove local repository of retrieved package files
apt-get --assume-yes clean

rm --force $PREVIOUS_STEP_DONE
