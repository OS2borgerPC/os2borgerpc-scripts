#! /usr/bin/env sh

# TODO: It appears as if four timer processes are started?!
#user        1635  0.0  0.0   2616   604 ?        S    13:52   0:00 /bin/sh /usr/share/os2borgerpc/bin/logout_timer_user.sh
#root        1643  0.0  0.1  14852  4736 ?        S    13:52   0:00 sudo /usr/share/os2borgerpc/bin/logout_timer.sh
#user        1650  0.0  0.0   2616  1048 ?        S    13:52   0:00 /bin/sh /usr/share/os2borgerpc/bin/logout_timer_user.sh
#root        1701  0.0  0.0   2616  1580 ?        S    13:52   0:00 sh /usr/share/os2borgerpc/bin/logout_timer.sh


# TODO: these timers should only run for "user"!
# TODO: We need to run this program only AFTER login, so not graphical.target or whatever, if that
# includes the login manager which also runs in X.
# At the same time if switching from systemd enabling to systemd starting it from the PAM module,
# this script suddenly relies on the cicero PAM module. Not so nice.
# We could add it to /etc/sudoers as no password and then run it from a .desktop file?
# I would assume that would mean they can run it but they can't kill it?

# TODO: This program needs to run as root or superuser so a user can't kill it,
# but at the same time the timer program must run as the regular user to be able to write things to
# screen?
# It's fine if they kill zenity as long as they're then logged out automatically or the timer
# continues in the background, or zenity is restarted. A systemd service?
# Also get_os2borgerpc_config, to obtain the starting time, is not callable from user, we need root for that.
# Also get_os2borgerpc_config is actually not relevant, because the total timer might be 24 minutes
# but maybe they have 15 minutes left.
# So essentially when we check their user with PAM we need to calculate and save how much time they
# have left, and then that's used as the starting point for the counter in this script

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"
SECONDS_TO_LOGOUT=$2
X_POSITION=$3
Y_POSITION=$4

export DEBIAN_FRONTEND=noninteractive

SHADOW=".skjult"
TIMER_LOGOUT_PROGRAM="/usr/share/os2borgerpc/bin/logout_timer.sh"
TIMER_USER_PROGRAM="/usr/share/os2borgerpc/bin/logout_timer_user.sh"
TIMER_LAUNCHER="/usr/share/os2borgerpc/bin/timer_launcher.sh"
TIMERS_DESKTOP_FILE="/home/$SHADOW/.config/autostart/logout-timer_user.desktop"
SUDOERS_CUSTOM=/etc/sudoers.d/os2borgerpc-cicero
LOGOUT_TIMER_CONF=/usr/share/os2borgerpc/logout_timer.conf


[ $# -lt 1 ] && printf "The script takes at least one argument: Whether to enable or disable the timer" && exit 1

if [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] && \
   [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then
  # TODO: Do we need to install zenity?
  apt-get install --assume-yes xdotool

  # The default time before logout
  printf "TIME_SECONDS=%s" "$SECONDS_TO_LOGOUT" > $LOGOUT_TIMER_CONF

  # This timer handles the actual logout and thus runs as root so the user can't kill the process
	cat <<- EOF > $TIMER_LOGOUT_PROGRAM
		#! /usr/bin/env sh

		# Remember to NOT run this script as the regular user as otherwise they can just kill the process

		. $LOGOUT_TIMER_CONF

		COUNT=\$TIME_SECONDS

		until [ "\$COUNT" -eq "0" ]; do                              # Countdown loop.
		    COUNT=\$((COUNT-1))                                      # Decrement seconds.
		    sleep 1
		done

		su --login user --command "DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/\$(id -u user)/bus" gnome-session-quit --logout --no-prompt"
		# Alternate approach:
		# who -u    #to obtain the ID of the session?
		# kill <idFoundAbove>
		# Alternate approach:
		# killall lightdm
		# Alternate approach:
		# killall gnome-session
	EOF

# The newline below is crucial, otherwise it's not a valid sudoers file
printf "user ALL = NOPASSWD: %s\n" $TIMER_LOGOUT_PROGRAM > $SUDOERS_CUSTOM
chmod 0440 $SUDOERS_CUSTOM

  # This timer is for visually displaying how long they have left only.
	cat <<- EOF > $TIMER_USER_PROGRAM
    #! /usr/bin/env sh

    # We need job control to move the window but then suspend until zenity closes
    set -m

		# Credits: https://handybashscripts.blogspot.com/2012/01/simple-timer-with-progress-bar.html

    TITLE="Logintid"

    . $LOGOUT_TIMER_CONF

    GRACE_PERIOD_SECONDS=15
    # Subtracting a little from this as we need this to run at least a bit before they're logged out
    COUNT=\$((TIME_SECONDS - GRACE_PERIOD_SECONDS))

		#ICON=/usr/share/icons/Yaru/48x48/apps/clock-app.png
		ICON=clock-app

		START=\$COUNT                                                # Set a starting point.

		until [ "\$COUNT" -eq "0" ]; do                              # Countdown loop.
		    COUNT=\$((COUNT-1))                                      # Decrement seconds.
		    PERCENT=\$((100-100*COUNT/START))                        # Calc percentage.
		    echo "#Tid tilbage: \$(echo "obase=60;\$COUNT" | bc)"    # Convert to H:M:S.
		    echo \$PERCENT                                           # Output for progbar.
		    #echo \$COUNT | xsel -i -p
		    sleep 1
		done | zenity --title "$TITLE" --progress --percentage=0 --text="" \
		    --window-icon \$ICON --icon-name \$ICON --auto-close --no-cancel &               # Progbar/time left.

    # xdotool would not work in Wayland
    xdotool windowmove "$(xdotool search "$TITLE")" $X_POSITION $Y_POSITION
    fg

		#xsel -o -p

		#notify-send -i \$ICON "## Tiden er udløbet: Du logges af om få sekunder. ##"       # Attention finish!
		zenity --notification --window-icon \$ICON --icon-name \$ICON \
		    --text "## Tiden er udløbet: Du logges af om få sekunder. ##"                   # Indicate finished!
	EOF

  # Simply a small script to launch from the desktop file which starts both timers
	cat <<- EOF > $TIMER_LAUNCHER
		#! /usr/bin/env bash

		# Using bash because disown is undefined in POSIX sh

		$TIMER_USER_PROGRAM &
		disown
		sudo $TIMER_LOGOUT_PROGRAM &
		disown
	EOF

  mkdir --parents /home/$SHADOW/.config/autostart

	# Autorun file that simply launches the script above after startup
	cat <<- EOF > "$TIMERS_DESKTOP_FILE"
		[Desktop Entry]
		Type=Application
		Name=Automatically allow launching of .desktop files on the desktop
		Exec=$TIMER_LAUNCHER
		Icon=system-run
		X-GNOME-Autostart-enabled=true
	EOF

  chmod +x $TIMER_LOGOUT_PROGRAM $TIMER_USER_PROGRAM $TIMER_LAUNCHER $TIMERS_DESKTOP_FILE

else # Delete the timer
  rm $TIMER_LOGOUT_PROGRAM $TIMER_USER_PROGRAM $TIMER_LAUNCHER $TIMERS_DESKTOP_FILE
fi
