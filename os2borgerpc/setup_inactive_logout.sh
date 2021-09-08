#! /usr/bin/env sh

# Time before dialog appears, defined in minutes
DIALOG_TIME=$1
if [ -z "$DIALOG_TIME" ]
then
	echo 'Please insert the time the user has to be inactive before dialog is shown.'
	exit 1
fi

# Time before user is logged out, defined in minutes
LOGOUT_TIME=$2
if [ -z "$LOGOUT_TIME" ]
then
	echo 'Please insert the time the user has to be inactive before being logged out.'
	exit 1
fi

if [ "$DIALOG_TIME" -gt "$LOGOUT_TIME" ]
then
	echo 'Dialog time is greater than logout time and dialog will therefore not be shown. Edit dialog time!'
	exit 1
fi	

# Text to be shown in the dialog
DIALOG_TEXT=$3
if [ -z "$DIALOG_TEXT" ]
then
	echo 'Please insert the text to be displayed in the dialog.'
	exit 1
fi

# Text to be shown on the dialog button
BUTTON_TEXT=$4
if [ -z "$BUTTON_TEXT" ]
then
	echo 'Please insert the text to be displayed on the dialog button.'
	exit 1
fi

# Install xprintidle
# Stop Debconf from doing anything
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y xprintidle

# if line already added to crontab skip
TEMP=$(crontab -l | grep "inactive_logout.sh")
if [ -z "$TEMP" ]
then
	line="* * * * * /usr/share/os2borgerpc/bin/inactive_logout.sh"
	(crontab -l -u root; echo "$line") | crontab -u root -
fi


# New auto_logout file
cat << EOF > /usr/share/os2borgerpc/bin/inactive_logout.sh
#! /usr/bin/env sh

# If the user is inactive for too long, a dialog will appear, warning the user that the session will end.
# If the user do not touch the mouse or press any keyboard key the session will end.

USER_DISPLAY=\$(who | grep -w 'user' | sed -rn 's/.*(:[0-9]*).*/\1/p')

export XAUTHORITY=/home/user/.Xauthority
export DISPLAY=\$USER_DISPLAY

su - user -s /bin/bash -c 'xhost +localhost'

# LOG_DIR=/usr/share/os2borgerpc/bin/inactive_logout.log
NEW_LOGOUT_TIME=$(( LOGOUT_TIME * 60 * 1000 ))
# echo \$NEW_LOGOUT_TIME \$(xprintidle) >> \$LOG_DIR

if [ \$(xprintidle) -ge \$NEW_LOGOUT_TIME ]
then 
	# echo 'Logging user out' >> \$LOG_DIR
	pkill -KILL -u user
	exit 0	
fi
NEW_DIALOG_TIME=$(( DIALOG_TIME * 60 * 1000 ))
# if idle time is past the dialog time: show the dialog
if [ \$(xprintidle) -ge \$NEW_DIALOG_TIME ]
then 
  # ...but only create a dialog if one doesn't already exist
  if ! pgrep --full 'Inaktivitet' > /dev/null
  then
    # echo 'Running zenity...' >> \$LOG_DIR
    # We use the --title to match against above
    zenity --warning --text="$DIALOG_TEXT" --ok-label="$BUTTON_TEXT" --no-wrap --display=\$USER_DISPLAY --title "Inaktivitet"
  fi
fi

exit 0

EOF

chmod +x /usr/share/os2borgerpc/bin/inactive_logout.sh
