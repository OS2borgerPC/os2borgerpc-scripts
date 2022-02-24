#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    lts_upgrade_in_place_1.sh
#%
#% DESCRIPTION
#%    Step one of the upgrade from 16.04 to 20.04.
#%
#================================================================
#- IMPLEMENTATION
#-    version         lts_upgrade_in_place_step_1.sh 0.0.1
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

# Patch jobmanager to avoid early stoppage.
sed -i "s/900/800000/" /usr/local/lib/python2.7/dist-packages/bibos_client/jobmanager.py || exit 1

reboot
