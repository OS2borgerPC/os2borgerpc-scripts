#!/bin/sh
# Script for removing the on/off schedule and the related services/crontab entries from a computer

set -x

WAKE_PLAN_FILE=/etc/os2borgerpc/plan.json
ON_OFF_SCHEDULE_SERVICE="/etc/systemd/system/os2borgerpc-set_on-off_schedule.service"
ON_OFF_SCHEDULE_SCRIPT="/usr/local/lib/os2borgerpc/set_on-off_schedule.py"
SCHEDULED_OFF_SCRIPT="/usr/local/lib/os2borgerpc/scheduled_off.sh"

# Remove the on/off schedule service
systemctl disable os2borgerpc-set_on-off_schedule.service
rm --force $ON_OFF_SCHEDULE_SCRIPT \
            $ON_OFF_SCHEDULE_SERVICE \
            $SCHEDULED_OFF_SCRIPT \
            $WAKE_PLAN_FILE

# Disable the alarm meant to wake the machine if it is not shut down by the schedule
rtcwake -m disable

# Remove related Crontab entries
TCRON=/tmp/oldcron
crontab -l > $TCRON
if [ -f $TCRON ]; then
  sed --in-place "/scheduled_off/d" $TCRON
  sed --in-place "/set_on-off_schedule/d" $TCRON
  crontab $TCRON
fi
rm --force $TCRON

# Only clean up usercron if the machine is not a kiosk
if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  USERCRON=/tmp/usercron
  crontab -u user -l > $USERCRON
  if [ -f $USERCRON ]; then
    sed --in-place "/zenity/d" $USERCRON
    crontab -u user $USERCRON
  fi
  rm --force $USERCRON
fi
