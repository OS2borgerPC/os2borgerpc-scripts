#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    general_lts_upgrade_in_place_step_1.sh
#%
#% DESCRIPTION
#%    Step one of the upgrade from 20.04 to 22.04.
#%
#================================================================
#- IMPLEMENTATION
#-    version         general_lts_upgrade_in_place_step_1.sh 0.0.1
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

# Fail on machines that have already been upgraded
if lsb_release -d | grep --quiet 22; then
  echo "Denne maskine er allerede blevet opgraderet til Ubuntu 22.04."
  exit 1
fi

# Update client
pip install --upgrade os2borgerpc-client

# Patch jobmanager and config to avoid early stoppage.

set_os2borgerpc_config job_timeout 800000

os2borgerpc_push_config_keys job_timeout

# Clear crontab and disable potential wake plans to prevent shutdown while the upgrade is running
TMP_ROOTCRON=/etc/os2borgerpc/tmp_rootcronfile
TMP_USERCRON=/etc/os2borgerpc/tmp_usercronfile
if [ ! -f "$TMP_ROOTCRON" ]; then
  crontab -l > $TMP_ROOTCRON
  crontab -r || true
  if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
    crontab -u user -l > $TMP_USERCRON
    crontab -u user -r || true
  fi
fi
if [ -f /etc/os2borgerpc/plan.json ]; then
  systemctl disable os2borgerpc-set_on-off_schedule.service
fi

touch /etc/os2borgerpc/first_upgrade_step_done
