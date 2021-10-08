#! /usr/bin/env sh

# apt-get install could fail due to debian frontend lock being unavailable
# during automatic updates
set -e

DIALOG_TIME=$1 # Time before dialog appears, defined in minutes
LOGOUT_TIME=$2 # Time before user is logged out, defined in minutes
DIALOG_TEXT=$3 # Text to be shown in the dialog
BUTTON_TEXT=$4 # Text to be shown on the dialog button

error() {
  echo "$1"
  exit 1
}

if [ -z "$DIALOG_TIME" ]
then
	error 'Please insert the time the user has to be inactive before dialog is shown.'
fi

if [ -z "$LOGOUT_TIME" ]
then
	error 'Please insert the time the user has to be inactive before being logged out.'
fi

if [ "$DIALOG_TIME" -gt "$LOGOUT_TIME" ]
then
	error 'Dialog time is greater than logout time and dialog will therefore not be shown. Edit dialog time!'
fi

if [ -z "$DIALOG_TEXT" ]
then
	error 'Please insert the text to be displayed in the dialog.'
fi

if [ -z "$BUTTON_TEXT" ]
then
	error 'Please insert the text to be displayed on the dialog button.'
fi

# xprintidle uses milliseconds, so convert the user inputted minutes to that
LOGOUT_TIME_MS=$(( LOGOUT_TIME * 60 * 1000 ))
DIALOG_TIME_MS=$(( DIALOG_TIME * 60 * 1000 ))

# Install xprintidle
# Stop Debconf from doing anything
export DEBIAN_FRONTEND=noninteractive
apt-get update --assume-yes
apt-get install --assume-yes xprintidle

# if line already added to crontab skip
TEMP=$(crontab -l | grep "inactive_logout.sh")
if [ -z "$TEMP" ]
then
	line="* * * * * /usr/share/os2borgerpc/bin/inactive_logout.sh"
	(crontab -l -u root; echo "$line") | crontab -u root -
fi


# New auto_logout file, running as root
cat <<- EOF > /usr/share/os2borgerpc/bin/inactive_logout.sh
	#! /usr/bin/env sh

	# If the user is inactive for too long, a dialog will appear, warning the user that the session will end.
	# If the user do not touch the mouse or press any keyboard key the session will end.
  # Only have one dialog at a time, so remove preexisting ones.
  # Create a new message every time, in case someone didn't close it but
  # just put e.g. a browser in front, to ensure they or someone else gets a
  # new warning when/if inactivity is reached again

	# DEV NOTE: It appears this way of obtaining the DISPLAY doesn't work in
	# Ubuntu 21:04, so possibly not in future versions either
	USER_DISPLAY=\$(who | grep -w 'user' | sed -rn 's/.*(:[0-9]*).*/\1/p')

	# These are used by xprintidle
	export XAUTHORITY=/home/user/.Xauthority
	export DISPLAY=\$USER_DISPLAY
	su - user -c "DISPLAY=\$USER_DISPLAY xhost +localhost"

	LOG_DIR=/usr/share/os2borgerpc/bin/inactive_logout.log
	echo $LOGOUT_TIME_MS \$(xprintidle) >> \$LOG_DIR

	if [ \$(xprintidle) -ge $LOGOUT_TIME_MS ]
	then
		echo 'Logging user out' >> \$LOG_DIR
		pkill -KILL -u user
		exit 0
	fi
	# if idle time is past the dialog time: show the dialog
	if [ \$(xprintidle) -ge $DIALOG_TIME_MS ]
	then
    # Do spare the poor lives of potential other zenity windows.
    PID_ZENITY="\$(pgrep --full 'Inaktivitet')"
    if [ -n \$PID_ZENITY ];
    then
      kill \$PID_ZENITY
    fi
	  # echo 'Running zenity...' >> \$LOG_DIR
	  # We use the --title to match against above
	  zenity --warning --text="$DIALOG_TEXT" --ok-label="$BUTTON_TEXT" --no-wrap --display=\$USER_DISPLAY --title "Inaktivitet"
	fi

	exit 0
EOF

chmod +x /usr/share/os2borgerpc/bin/inactive_logout.sh
