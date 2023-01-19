#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    lts_upgrade_in_place_2.sh
#%
#% DESCRIPTION
#%    Step two of the upgrade from 16.04 to 20.04.
#%
#================================================================
#- IMPLEMENTATION
#-    version         lts_upgrade_in_place_step_2.sh 0.0.1
#-    author          Carsten Agger
#-    copyright       Copyright 2020, Magenta Aps
#-    license         BSD/MIT
#-    email           info@magenta.dk
#-
#================================================================
#  HISTORY
#     2021/01/13 : carstena : Script creation
#
#================================================================
# END_OF_HEADER
#================================================================

set -ex

# Fix dpkg settings to avoid interactivity.
cat << EOF > /etc/apt/apt.conf.d/local

Dpkg::Options {
   "--force-confdef";
   "--force-confold";
}

EOF

do-release-upgrade -f DistUpgradeViewNonInteractive > /var/log/os2borgerpc_upgrade_1.log




