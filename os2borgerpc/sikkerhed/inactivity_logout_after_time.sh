#! /usr/bin/env sh

# This script and "inactivity_suspend_after_time.sh" are mutually exclusive, and each of them
# are written to overwrite each other, so whichever was the last of them run takes effect.

# PARAMETERS
# 1. Checkbox. Enables/disables the script.
# 2. Integer. How many minutes to wait before showing the warning dialog
# 3. Integer. How many minutes to wait before logging out
# 4. String. (optional) The text to be shown in the warning dialog. If no input is given, a default is used
# 5. String. (optional) The text to be shown on the dialog button. If no input is given, a default is used

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

ENABLE=$1
DIALOG_TIME_MINS=$2
LOGOUT_TIME_MINS=$3
DIALOG_TEXT=$4
BUTTON_TEXT=$5

# Note: Currently this log is never rotated, so it'll grow and grow
INACTIVITY_SCRIPT="/usr/share/os2borgerpc/bin/inactive_logout.sh"
INACTIVITY_SCRIPT_LOG="/usr/share/os2borgerpc/bin/inactive_logout.log"
LIGHTDM_SCRIPT="/etc/lightdm/greeter-setup-scripts/suspend_after_time.sh"

# Stop Debconf from interrupting when interacting with the package system
export DEBIAN_FRONTEND=noninteractive

error() {
  echo "$1"
  exit 1
}

# If this is run after inactivity_suspend_after_time, ensure the suspend script
# hasn't left files behind
rm --force $LIGHTDM_SCRIPT

# Handle deactivating inactivity logout
if [ "$ENABLE" = "False" ]; then
  rm --force $INACTIVITY_SCRIPT $INACTIVITY_SCRIPT_LOG
  OLDCRON="/tmp/oldcron"
  crontab -l > $OLDCRON
  if [ -f "$OLDCRON" ]; then
    sed --in-place "\@$INACTIVITY_SCRIPT@d" $OLDCRON
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

# Install xprintidle
apt-get update --assume-yes

# Only try installing if it isn't already as otherwise it will exit with nonzero and stop the script
if ! dpkg --get-selections | grep -v deinstall | grep --quiet xprintidle; then
  if ! apt-get install --assume-yes xprintidle; then
    # apt install could fail due to debian frontend lock being unavailable
    # during automatic updates
    error "apt failed to install xprintidle"
  fi
fi

# if line already added to crontab: skip
if ! crontab -l | grep "$INACTIVITY_SCRIPT"; then
	line="* * * * * $INACTIVITY_SCRIPT"
	(crontab -l -u root; echo "$line") | crontab -u root -
fi

# New auto_logout file, running as root
cat <<- EOF > $INACTIVITY_SCRIPT
	#! /usr/bin/env sh

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

	LOG=$INACTIVITY_SCRIPT_LOG

	echo $LOGOUT_TIME_MS \$(xprintidle) >> \$LOG

	if [ \$(xprintidle) -ge $LOGOUT_TIME_MS ]; then
		echo 'Logging user out' >> \$LOG
		pkill -KILL -u user
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

chmod +x $INACTIVITY_SCRIPT
