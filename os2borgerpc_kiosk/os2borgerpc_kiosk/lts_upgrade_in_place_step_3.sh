#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    lts_upgrade_in_place_3.sh
#%
#% DESCRIPTION
#%    Step three of the upgrade from 16.04 to 20.04.
#%
#================================================================
#- IMPLEMENTATION
#-    version         lts_upgrade_in_place_step_3.sh 0.0.1
#-    author          Carsten Agger, Marcus Funch Mogensen
#-    copyright       Copyright 2020, Magenta Aps
#-    license         BSD/MIT
#-    email           info@magenta.dk
#-
#================================================================
#  HISTORY
#     2021/03/19 : mfm : Add OS2display migration
#     2021/01/13 : carstena : Script creation
#
#================================================================
# END_OF_HEADER
#================================================================

set -ex

do-release-upgrade -f DistUpgradeViewNonInteractive >  /var/log/os2borgerpc_upgrade_2.log

