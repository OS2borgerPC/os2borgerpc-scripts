#! /usr/bin/env sh

# DESCRIPTION
#
# This script will log out the user and suspend the PC after a given period of inactivity.
# A configurable warning is shown before the user is logged out and the pc suspended.
#
# The script will also suspend the PC after the same period of inactivity on the login screen.
# This second part of the script requires "lightdm_greeter_setup_scripts" to be run and enabled to take effect
#
# The script is designed to wake up the PC 1 minute before a potential scheduled shutdown (on/off-schedule)
# so that it can be shut down as planned.
# If no scheduled shutdown exists, it will suspend the PC until it is woken manually.
#
# This script and "inactivity_logout_after_time.sh" are mutually exclusive, and each of them
# are written to overwrite each other, so whichever was the last of them run takes effect.
#
# PARAMETERS
# 1. Checkbox. Enables/disables the script.
# 2. Integer. How many minutes to wait before showing the warning dialog
# 3. Integer. How many minutes to wait before logging out and suspending
# 4. String. (optional) The text to be shown in the warning dialog. If no input is given, a default is used
# 5. String. (optional) The text to be shown on the dialog button. If no input is given, a default is used

set -x

ENABLE=$1
DIALOG_TIME_MINS=$2
LOGOUT_TIME_MINS=$3
DIALOG_TEXT=$4
BUTTON_TEXT=$5

# Note: Currently these logs are never rotated, so they'll grow and grow
SUSPEND_SCRIPT="/usr/share/os2borgerpc/bin/inactive_logout.sh"
SUSPEND_SCRIPT_LOG="/usr/share/os2borgerpc/bin/inactive_logout.log"
LIGHTDM_SUSPEND_SCRIPT="/etc/lightdm/greeter-setup-scripts/suspend_after_time.sh"
LIGHTDM_SUSPEND_SCRIPT_LOG="/etc/lightdm/scriptlogs/suspend_after_time.log"
LIGHTDM_GREETER_SETUP_SCRIPT="/etc/lightdm/greeter_setup_script.sh"
LIGHTDM_GREETER_SCRIPTS_DIR="/etc/lightdm/greeter-setup-scripts"

# Stop Debconf from interrupting when interacting with the package system
export DEBIAN_FRONTEND=noninteractive

error() {
  echo "$1"
  exit 1
}

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  error "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
fi

# Handle deactivating inactivity suspend
if [ "$ENABLE" = "False" ]; then
  rm --force $SUSPEND_SCRIPT $LIGHTDM_SUSPEND_SCRIPT $SUSPEND_SCRIPT_LOG $LIGHTDM_SUSPEND_SCRIPT_LOG
  OLDCRON="/tmp/oldcron"
  crontab -l > $OLDCRON
  if [ -f "$OLDCRON" ]; then
    sed --in-place "\@$SUSPEND_SCRIPT@d" $OLDCRON
    crontab $OLDCRON
    rm --force $OLDCRON
  fi
  exit
fi

[ -z "$DIALOG_TIME_MINS" ] && error 'Please insert the time the user has to be inactive before dialog is shown.'
[ -z "$LOGOUT_TIME_MINS" ] && error 'Please insert the time the user has to be inactive before being logged out.'
[ "$DIALOG_TIME_MINS" -gt "$LOGOUT_TIME_MINS" ] && error 'Dialog time is greater than logout time and dialog will therefore not be shown. Edit dialog time!'
[ -z "$DIALOG_TEXT" ] && DIALOG_TEXT="Du er inaktiv og bliver logget ud om kort tid..."
[ -z "$BUTTON_TEXT" ] && BUTTON_TEXT="OK"

# xprintidle uses milliseconds, so convert the user inputted minutes to that
LOGOUT_TIME_MS=$(( LOGOUT_TIME_MINS * 60 * 1000 ))
DIALOG_TIME_MS=$(( DIALOG_TIME_MINS * 60 * 1000 ))

# Older versions of this script used sh, but our lightdm suspend script uses
# bash specifics. Change it to run the script directly with whatever interpreter it has.
# This requires ensuring that lightdm has execute permissions on all those scripts.
chmod --rescursive 700 $LIGHTDM_GREETER_SCRIPTS_DIR
cat << EOF > $LIGHTDM_GREETER_SETUP_SCRIPT
#!/bin/sh
greeter_setup_scripts=\$(find $LIGHTDM_GREETER_SCRIPTS_DIR -mindepth 1)
for file in \$greeter_setup_scripts
do
    ./"\$file" &
done
EOF

chmod 700 $LIGHTDM_GREETER_SETUP_SCRIPT

mkdir --parents "$(dirname $LIGHTDM_SUSPEND_SCRIPT)" "$(dirname $SUSPEND_SCRIPT_LOG)"

TIMEOUT_SECS=$((LOGOUT_TIME_MINS * 60))

cat << EOF > "$LIGHTDM_SUSPEND_SCRIPT"
#!/usr/bin/env bash

LOG=$LIGHTDM_SUSPEND_SCRIPT_LOG

while :
do
  echo "Starting sleep for $TIMEOUT_SECS seconds" >> \$LOG
  sleep $TIMEOUT_SECS
  echo "Sleep over" >> \$LOG
  if [ -z \$(users) ]; then
    echo "no active users, suspending" >> \$LOG
    # If the pc has a time plan, don't use systemctl suspend, but instead rtcwake -m mem,
    # which is functionally the same and allows the machine to wake up in time to be shut down
    # by the time plan
    re="([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+) .+"
    if [[ \$(crontab -l | grep scheduled_off) =~ \$re ]]; then
      MINUTES=\${BASH_REMATCH[1]}
      HOURS=\${BASH_REMATCH[2]}
      DAY=\${BASH_REMATCH[3]}
      MONTH=\${BASH_REMATCH[4]}
      YEAR=\$(date +%Y)
      # wake up 1 minute before shut down
      MINM1P60=\$(( \$(( MINUTES - 1)) + 60))
      # Rounding minutes
      MINS=\$(( MINM1P60 % 60))
      HRCORR=\$(( 1 - \$(( MINM1P60 / 60))))
      HRS=\$(( HOURS - HRCORR))
      HRS=\$(( \$(( HRS + 24)) % 24))
      rtcwake -m mem --date "\$YEAR-\$MONTH-\$DAY \$HRS:\$MINS"
    else
      systemctl suspend
    fi
  else
    echo "should be logged in as \$(users) breaking loop" >> \$LOG
    break
  fi
done

echo "exited loop" >> \$LOG
exit 0
EOF

chmod 700 $LIGHTDM_SUSPEND_SCRIPT

# Install xprintidle
apt-get update --assume-yes

# Only try installing if it isn't already as otherwise it will exit with nonzero
# and stop the script
if ! dpkg --get-selections | grep -v deinstall | grep --quiet xprintidle; then
  if ! apt-get install --assume-yes xprintidle; then
    # apt install could fail due to debian frontend lock being unavailable
    # during automatic updates
    error "apt failed to install xprintidle"
  fi
fi

# if line already added to crontab: skip
if ! crontab -l | grep "$SUSPEND_SCRIPT"; then
	line="* * * * * $SUSPEND_SCRIPT"
	(crontab -l -u root; echo "$line") | crontab -u root -
fi

# New auto_logout file, running as root
cat <<- EOF > $SUSPEND_SCRIPT
	#!/usr/bin/env bash

	# If the user is inactive for too long, a dialog will appear, warning the user that the session will end.
	# If the user do not touch the mouse or press any keyboard key the session will end.
	# Only have one dialog at a time, so remove preexisting ones.
	# Create a new message every time, in case someone didn't close it but
	# just put e.g. a browser in front, to ensure they or someone else gets a
	# new warning when/if inactivity is reached again

	USER_DISPLAY=\$(who | grep -w 'user' | sed -rn 's/.*(:[0-9]*).*/\1/p')

	# These are used by xprintidle
	export XAUTHORITY=/home/user/.Xauthority
	export DISPLAY=\$USER_DISPLAY
	su - user -c "DISPLAY=\$USER_DISPLAY xhost +localhost"

	LOG=$SUSPEND_SCRIPT_LOG

	echo $LOGOUT_TIME_MS \$(xprintidle) >> \$LOG

	# If the pc has a time plan, don't use systemctl suspend, but instead rtcwake -m mem,
	# which is functionally the same and allows the machine to wake up in time to be shut down
	# by the time plan

	if [ \$(xprintidle) -ge $LOGOUT_TIME_MS ]; then
	  echo 'Logging user out' >> \$LOG
	  pkill -KILL -u user
	  echo 'suspending pc' >> \$LOG
	  # If the pc has a time plan, don't use systemctl suspend, but instead rtcwake -m mem,
	  # which is functionally the same and allows the machine to wake up in time to be shut down
	  # by the time plan
	  re="([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+) .+"
	  if [[ \$(crontab -l | grep scheduled_off) =~ \$re ]]; then
	    MINUTES=\${BASH_REMATCH[1]}
	    HOURS=\${BASH_REMATCH[2]}
	    DAY=\${BASH_REMATCH[3]}
	    MONTH=\${BASH_REMATCH[4]}
	    YEAR=\$(date +%Y)
	    # wake up 1 minute before shut down
	    MINM1P60=\$(( \$(( MINUTES - 1)) + 60))
	    # Rounding minutes
	    MINS=\$(( MINM1P60 % 60))
	    HRCORR=\$(( 1 - \$(( MINM1P60 / 60))))
	    HRS=\$(( HOURS - HRCORR))
	    HRS=\$(( \$(( HRS + 24)) % 24))
	    # When run from the crontab, rtcwake needs the full path for some reason or it won't work
	    /usr/sbin/rtcwake -m mem --date "\$YEAR-\$MONTH-\$DAY \$HRS:\$MINS"
	  else
	    systemctl suspend
	  fi
	  exit 0
	fi
	# if idle time is past the dialog time: show the dialog
	if [ \$(xprintidle) -ge $DIALOG_TIME_MS ]; then
	  # Do spare the poor lives of potential other zenity windows.
	  PID_ZENITY="\$(pgrep --full 'Inaktivitet')"
	  if [ -n \$PID_ZENITY ]; then
	    kill \$PID_ZENITY
	  fi
	  # echo 'Running zenity...' >> \$LOG
	  # We use the --title to match against above
	  zenity --warning --text="$DIALOG_TEXT" --ok-label="$BUTTON_TEXT" --no-wrap --display=\$USER_DISPLAY --title "Inaktivitet"
	fi
EOF

chmod 700 $SUSPEND_SCRIPT
