#!/usr/bin/env bash

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script har ingen effekt på en kiosk-maskine."
  exit 1
fi

USERCRON="/etc/os2borgerpc/usercron"
USER_CLEANUP="/usr/share/os2borgerpc/bin/user-cleanup.bash"
LOGOUT_TIMER_CLEANUP_FILE="/usr/share/os2borgerpc/bin/user-cleanup-logout-timer.bash"
ON_OFF_SCHEDULE_SCRIPT="/usr/local/lib/os2borgerpc/set_on-off_schedule.py"
GIO_LAUNCHER="/usr/share/os2borgerpc/bin/gio-fix-desktop-file-permissions.sh"

# Move the current user crontab to a file
crontab -u user -l > $USERCRON
chmod 700 $USERCRON

# Remove all lines not containing notify-send or zenity, which all of ours do
sed -i "/notify-send\|zenity/! d" $USERCRON

# Check the contents of the file
cat $USERCRON

# Check if they're using the old version of the logout timer script (unlikely)
OLD_LOGOUT_TIMER_FILE="False"
if grep --quiet "logout_timer_visual" $USER_CLEANUP; then
  OLD_LOGOUT_TIMER_FILE="True"
fi

# Overwrite user-cleanup.bash to the correct version with or without
# write access to users desktop removed depending on current settings
if grep --quiet "chattr" $USER_CLEANUP; then
  cat << EOF > $USER_CLEANUP
#!/bin/bash

# This script cleans up the users home directory.

USERNAME="user"

# Determine the name of the user desktop directory. This is done via xdg-user-dir,
# which checks the /home/user/.config/user-dirs.dirs file. To ensure this file exists,
# we run xdg-user-dirs-update, which generates it based on the environment variables
# LANG and LANGUAGE. These variables are empty in lightdm so we first export them
# based on the values stored in /etc/default/locale
export "\$(grep LANG= /etc/default/locale | tr -d '"')"
runuser -u \$USERNAME xdg-user-dirs-update
DESKTOP=\$(runuser -u \$USERNAME xdg-user-dir DESKTOP)

chattr -i "\$DESKTOP"

# Kill all processes started by user
pkill -KILL -u user

# Find all files/directories owned by user in the world-writable directories
FILES_DIRS=\$(find /var/tmp/ /var/crash/ /var/metrics/ /var/lock/ -user user)

rm --recursive --force /tmp/* /tmp/.??* /dev/shm/* /dev/shm/.??* /home/\$USERNAME \$FILES_DIRS
# Remove pending print jobs
PRINTERS=\$(lpstat -p | grep printer | awk '{ print \$2; }')

for PRINTER in \$PRINTERS
do
    lprm -P \$PRINTER -
done

# Reset user crontab
crontab -u user $USERCRON

# Remove possible scheduled at commands
if [ -f /usr/bin/at ]; then
  atq | cut --fields 1 | xargs --no-run-if-empty atrm
fi

# Restore \$HOME
rsync -vaz /home/.skjult/ /home/\$USERNAME/
chown -R \$USERNAME:\$USERNAME /home/\$USERNAME

# Make the desktop read only to user
chown -R root:\$USERNAME "\$DESKTOP"
chattr +i "\$DESKTOP"
# The exact cause is unclear, but xdg-user-dir will rarely fail in such
# a way that DESKTOP=/home/user. The lines below prevent this error
# from causing login issues.
chattr -i /home/user/
chown \$USERNAME:\$USERNAME /home/\$USERNAME
chown -R \$USERNAME:\$USERNAME /home/\$USERNAME/.config /home/\$USERNAME/.local
EOF
else
  cat << EOF > $USER_CLEANUP
#!/bin/bash

# This script cleans up the users home directory.

USERNAME="user"

# Kill all processes started by user
pkill -KILL -u user

# Find all files/directories owned by user in the world-writable directories
FILES_DIRS=\$(find /var/tmp/ /var/crash/ /var/metrics/ /var/lock/ -user user)

rm --recursive --force /tmp/* /tmp/.??* /dev/shm/* /dev/shm/.??* /home/\$USERNAME \$FILES_DIRS
# Remove pending print jobs
PRINTERS=\$(lpstat -p | grep printer | awk '{ print \$2; }')

for PRINTER in \$PRINTERS
do
    lprm -P \$PRINTER -
done

# Reset user crontab
crontab -u user $USERCRON

# Remove possible scheduled at commands
if [ -f /usr/bin/at ]; then
  atq | cut --fields 1 | xargs --no-run-if-empty atrm
fi

# Restore \$HOME
rsync -vaz /home/.skjult/ /home/\$USERNAME/
chown -R \$USERNAME:\$USERNAME /home/\$USERNAME
EOF
fi

# Ensure that desktop shortcuts remain activated
if [ -f "$GIO_LAUNCHER" ]; then
  sed -i "0,\@chown -R \$USERNAME:\$USERNAME /home/\$USERNAME@ s@@&\n$GIO_LAUNCHER@" $USER_CLEANUP
fi

# Ensure that possible logout timers continue to work correctly
if [ -f "$LOGOUT_TIMER_CLEANUP_FILE" ]; then
  echo "$LOGOUT_TIMER_CLEANUP_FILE" >> $USER_CLEANUP
elif [ "$OLD_LOGOUT_TIMER_FILE" = "True" ]; then
  cat << EOF >> $USER_CLEANUP
pkill -f logout_timer_visual.sh
pkill -f logout_timer_actual.sh
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
