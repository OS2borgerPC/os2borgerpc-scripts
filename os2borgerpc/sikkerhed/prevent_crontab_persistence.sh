#!/usr/bin/env bash

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script har ingen effekt på en kiosk-maskine."
  exit 1
fi

USERCRON="/etc/os2borgerpc/usercron"
USER_CLEANUP="/usr/share/os2borgerpc/bin/user-cleanup.bash"
ON_OFF_SCHEDULE_SCRIPT="/usr/local/lib/os2borgerpc/set_on-off_schedule.py"

# Move the current user crontab to a file
if [ ! -f "$USERCRON" ]; then
  crontab -u user -l > $USERCRON
fi

chmod 700 $USERCRON

# Remove all lines not containing notify-send or zenity, which all of ours do
sed -i "/notify-send\|zenity/! d" $USERCRON

# Check the contents of the file
cat $USERCRON

if ! grep --quiet "crontab" $USER_CLEANUP; then
  cat << EOF >> $USER_CLEANUP

# Restore user crontab
crontab -u user $USERCRON
EOF
fi

if ! grep --quiet "atq" $USER_CLEANUP; then
  cat << EOF >> $USER_CLEANUP

# Remove possible scheduled at commands
if [ -f /usr/bin/at ]; then
  atq | cut --fields 1 | xargs --no-run-if-empty atrm
fi
EOF
fi

if ! grep --quiet "pkill" $USER_CLEANUP; then
  cat << EOF >> $USER_CLEANUP

# Kill all processes started by user
pkill -KILL -u user
EOF
fi

if ! grep --quiet "FILES_DIRS" $USER_CLEANUP; then
  cat << EOF >> $USER_CLEANUP

# Find all files/directories owned by user in the world-writable directories
FILES_DIRS=\$(find /var/tmp/ /var/crash/ /var/metrics/ /var/lock/ -user user)
rm --recursive --force /dev/shm/* /dev/shm/.??* \$FILES_DIRS
EOF
fi

# If they're using on/off schedules, change the schedule to use the usercron-file
if [ -f "$ON_OFF_SCHEDULE_SCRIPT" ] && grep --quiet "/tmp/usercron" $ON_OFF_SCHEDULE_SCRIPT; then
  sed -i "s@USERCRON = \"/tmp@USERCRON = \"/etc/os2borgerpc@" $ON_OFF_SCHEDULE_SCRIPT
  sed -i "0,/with open(USERCRON, 'w') as cronfile/{//d}" $ON_OFF_SCHEDULE_SCRIPT
  sed -i "/subprocess\.run(\[\"crontab\", \"-u\", \"user\", \"-l\"/d" $ON_OFF_SCHEDULE_SCRIPT
  sed -i "/os\.path\.exists(USERCRON)/d" $ON_OFF_SCHEDULE_SCRIPT
  sed -i "/os\.remove(USERCRON)/d" $ON_OFF_SCHEDULE_SCRIPT
fi
