#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    lts_upgrade_in_place_step_1.sh
#%
#% DESCRIPTION
#%    Step one of the upgrade from 20.04 to 22.04.
#%
#================================================================
#- IMPLEMENTATION
#-    version         lts_upgrade_in_place_step_1.sh 0.0.1
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

# Patch jobmanager and config to avoid early stoppage.

set_os2borgerpc_config job_timeout 800000

os2borgerpc_push_config_keys job_timeout

# Clear crontab and disable potential wake plans to prevent shutdown while the upgrade is running
TMP_CRON=/etc/os2borgerpc/tmp_cronfile
if [ ! -f "$TMP_CRON" ]; then
  crontab -l > $TMP_CRON
  crontab -r
fi
if [ -f /etc/os2borgerpc/plan.json ]; then
  systemctl disable os2borgerpc-set_on-off_schedule.service
fi
