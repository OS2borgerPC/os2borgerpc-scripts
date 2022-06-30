#! /usr/bin/env sh

# We need to run this program only AFTER login, so not graphical.target or whatever, if that
# includes the login manager which also runs in X.

# This program needs to run as root or superuser so a user can't kill it,
# but at the same time the timer program must run as the regular user to be able to write things to
# screen.
# It's fine if they kill the visual timer as long as they're then logged out automatically or the timer
# continues in the background. Or we can restart zenity in that case.

set -x

# Argument handling
ACTIVATE=$1
MINUTES_TO_LOGOUT_MSG=$2
X_POSITION=$3
Y_POSITION=$4
GRACE_PERIOD_SECONDS=$5 # Example: 40
PRE_TIMER_TEXT=$6       # Example: "Tid tilbage: "
TEXT_AFTER_TIMEOUT=$7   # Example: "Tiden er udløbet: Du logges snart af."

# Settings
export DEBIAN_FRONTEND=noninteractive
SHADOW=".skjult"
LOGOUT_TIMER_ACTUAL="/usr/share/os2borgerpc/bin/logout_timer_actual.sh"
LOGOUT_TIMER_VISUAL="/usr/share/os2borgerpc/bin/logout_timer_visual.sh"
LOGOUT_TIMER_ACTUAL_LAUNCHER="/usr/share/os2borgerpc/bin/logout_timer_actual_launcher.sh"
LOGOUT_TIMER_VISUAL_DESKTOP_FILE="/home/$SHADOW/.config/autostart/logout-timer_user.desktop"
LOGOUT_TIMERS_CONF="/usr/share/os2borgerpc/logout_timer.conf"
SESSION_CLEANUP_FILE="/usr/share/os2borgerpc/bin/user-cleanup.bash"
ICON="clock-app"

# They might have automatic login enabled or not. We add it to all lightdm programs just in case.
LIGHTDM_PAM="/etc/pam.d/lightdm"
LIGHTDM_GREETER_PAM="/etc/pam.d/lightdm-greeter"
LIGHTDM_AUTOLOGIN_PAM="/etc/pam.d/lightdm-autologin"
LIGHTDM_FILES="$LIGHTDM_PAM $LIGHTDM_GREETER_PAM $LIGHTDM_AUTOLOGIN_PAM"


[ $# -lt 7 ] && printf "%s\n" "This script takes at least $# arguments. Exiting." && exit 1

if [ "$ACTIVATE" = 'True' ]; then
	# TODO: Do we need to install zenity?
	apt-get install --assume-yes xdotool

	# The default time before logout
	printf "TIME_MINUTES=%s" "$MINUTES_TO_LOGOUT_MSG" > $LOGOUT_TIMERS_CONF

  # This timer handles the actual logout and thus runs as root so the user can't kill the process
	cat <<- EOF > $LOGOUT_TIMER_ACTUAL
		#! /usr/bin/env sh

		. $LOGOUT_TIMERS_CONF

		# Adding a little to this so they're warned a bit before they're actually logged out
		# This is even more important since currently the timers might get out of sync
		COUNT=\$((TIME_MINUTES * 60 + $GRACE_PERIOD_SECONDS))

		until [ "\$COUNT" -eq "0" ]; do                                # Countdown loop.
		    COUNT=\$((COUNT-1))                                        # Decrement seconds.
		    sleep 1
		done

		su --login user --command "DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/\$(id -u user)/bus" gnome-session-quit --logout --no-prompt"
		# Alternate approaches:
		# 1. who -u    #to obtain the ID of the session?
		#    kill <idFoundAbove>
		# 2. killall lightdm
		# 3. killall gnome-session
	EOF

	# This timer is for visually displaying how long they have left only.
	# Using bash to have access to set -m
	cat <<- EOF > $LOGOUT_TIMER_VISUAL
		#! /usr/bin/env bash

		# Credits: https://handybashscripts.blogspot.com/2012/01/simple-timer-with-progress-bar.html

		# We need job control to move the window but then suspend until the countdown finishes
		set -m

		# Load TIME_MINUTES from the config
		. $LOGOUT_TIMERS_CONF

		TITLE="Logintid"
		TIME_SECONDS=\$((TIME_MINUTES * 60))                           # Set a starting point.

		COUNT=\$TIME_SECONDS

		until [ "\$COUNT" -eq "0" ]; do                                # Countdown loop.
		    COUNT=\$((COUNT-1))                                        # Decrement seconds.
		    PERCENT=\$((100-100*COUNT/TIME_SECONDS))                   # Calc percentage.
		    echo "#$PRE_TIMER_TEXT \$(echo "obase=60;\$COUNT" | bc)"   # Convert to H:M:S.
		    echo \$PERCENT                                             # Output for progbar.
		    sleep 1
		done | zenity --title "\$TITLE" --progress --percentage=0 --text="" \
		    --auto-close --no-cancel &                                 # Progbar/time left.

		# xdotool would not work in Wayland
		sleep 3   # Give the zenity window a bit of time to appear before we try moving it
		xdotool windowmove "\$(xdotool search --name "\$TITLE")" $X_POSITION $Y_POSITION
		fg

		zenity --notification --window-icon $ICON --icon-name $ICON \
		    --text "$TEXT_AFTER_TIMEOUT"                               # Indicate finished!
	EOF

	# Simply a small script that launches the timer in the background and immediately exits
	# so the PAM stack continues instead of it waiting for the timer to run out
	# Using bash as disown is undefined in sh
	cat <<- EOF > $LOGOUT_TIMER_ACTUAL_LAUNCHER
		#! /usr/bin/env bash

		$LOGOUT_TIMER_ACTUAL &
		disown
	EOF

	# Make PAM run LOGOUT_TIMER_ACTUAL_LAUNCHER for user, so it's run as root
	# Idempotency: Don't add it multiple times if this script is run more than once
  if ! grep -q "# OS2borgerPC Timer" $LIGHTDM_GREETER_PAM; then
  	for f in $LIGHTDM_FILES; do
  		sed --in-place "/@include common-session/i# OS2borgerPC Timer\nsession [success=1 default=ignore] pam_succeed_if.so user != user\nsession optional pam_exec.so $LOGOUT_TIMER_ACTUAL_LAUNCHER" "$f"
  	done
  fi

	# Make a .desktop autostart for the visual countdown program
	mkdir --parents /home/$SHADOW/.config/autostart

	# Autorun file that simply launches the script above after startup
	cat <<- EOF > "$LOGOUT_TIMER_VISUAL_DESKTOP_FILE"
		[Desktop Entry]
		Type=Application
		Name=Automatically allow launching of .desktop files on the desktop
		Exec=$LOGOUT_TIMER_VISUAL
		Icon=system-run
		X-GNOME-Autostart-enabled=true
	EOF

	# Modify the cleanup run at logout to also kill remaining timers so they don't persist affecting
	# the next login
	if ! grep -q "$(basename $LOGOUT_TIMER_ACTUAL)" $SESSION_CLEANUP_FILE; then
		cat <<- EOF >> $SESSION_CLEANUP_FILE
			pkill -f $(basename $LOGOUT_TIMER_ACTUAL)
			pkill -f $(basename $LOGOUT_TIMER_VISUAL)
		EOF
	fi

	chmod u+x $LOGOUT_TIMER_ACTUAL $LOGOUT_TIMER_ACTUAL_LAUNCHER
	chmod +x $LOGOUT_TIMER_VISUAL $LOGOUT_TIMER_VISUAL_DESKTOP_FILE

else # Delete everything related to the timer
	rm $LOGOUT_TIMER_ACTUAL $LOGOUT_TIMER_VISUAL $LOGOUT_TIMER_VISUAL_DESKTOP_FILE $LOGOUT_TIMER_ACTUAL_LAUNCHER
	# Remove the cleanup of timer processes
	sed --in-place "/pkill -f $(basename $LOGOUT_TIMER_ACTUAL)/d" $SESSION_CLEANUP_FILE
	sed --in-place "/pkill -f $(basename $LOGOUT_TIMER_VISUAL)/d" $SESSION_CLEANUP_FILE

	for f in $LIGHTDM_FILES; do
		sed --in-place "/# OS2borgerPC Timer/d" "$f"
		sed --in-place "/session \[success=1 default=ignore\] pam_succeed_if.so user != user/d" "$f"
		sed --in-place "\@session optional pam_exec.so $LOGOUT_TIMER_ACTUAL_LAUNCHER@d" "$f"
	done
fi
