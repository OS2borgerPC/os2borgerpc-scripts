#! /usr/bin/env sh

# TODO: This program needs to run as root or superuser so a user can't kill it,
# but at the same time the timer program must run as the regular user to be able to write things to
# screen?
# It's fine if they kill zenity as long as they're then logged out automatically or the timer
# continues in the background, or zenity is restarted. A systemd service?
# Also get_os2borgerpc_config, to obtain the starting time, is not callable from user, we need root for that.
# Also get_os2borgerpc_config is actually not relevant, because the total timer might be 24 minutes
# but maybe they have 15 minutes left.
# So essentially when we check their user with PAM we need to calculate and save how much time they
# have left, and then that's used as the starting for the counter in this script

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"

export DEBIAN_FRONTEND=noninteractive

TIMER_LOGOUT_SYSTEMD_UNIT="/etc/systemd/system/os2borgerpc-logout-timer.service"
TIMER_USER_SYSTEMD_UNIT="/etc/systemd/user/os2borgerpc-logout-timer-user.service"

TIMER_LOGOUT_PROGRAM="/usr/share/os2borgerpc/bin/login-timer.sh"
TIMER_USER_PROGRAM="/usr/share/os2borgerpc/bin/login-timer-user.sh"
OUR_USER="user"

if [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] && \
   [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then

  # TODO: Do we need to install zenity?

	cat <<- EOF > $TIMER_LOGOUT_SYSTEMD_UNIT
		[Unit]
		Description=Run the login timer after user login
		DefaultDependencies=no
		After=network.target

		[Service]
		Type=simple
		ExecStart=$TIMER_LOGOUT_PROGRAM
		TimeoutStartSec=0
		RemainAfterExit=yes

		[Install]
		WantedBy=default.target
	EOF

	cat <<- EOF > $TIMER_USER_SYSTEMD_UNIT
		[Unit]
		Description=Run the login timer after user login
		DefaultDependencies=no
		After=network.target

		[Service]
		Type=simple
		User=$OUR_USER
		Group=$OUR_USER
		ExecStart=$TIMER_USER_PROGRAM
		TimeoutStartSec=0
		RemainAfterExit=yes
    # Restart=always
    # RestartSec=10

		[Install]
		WantedBy=default.target
	EOF

  # This timer handles the actual logout and thus runs as root so the user can't kill the process
	cat <<- EOF > $TIMER_LOGOUT_PROGRAM
		#! /usr/bin/env sh

		COUNT=$1

		until [ "$COUNT" -eq "0" ]; do                              # Countdown loop.
		    COUNT=$((COUNT-1))                                      # Decrement seconds.
		    sleep 1
		done

    su --login user --command "DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u user)/bus" gnome-session-quit --logout --no-prompt"
    # who -u    #to obtain the ID of the session?
    # kill $idFoundAbove
	EOF

  # This timer is for visually displaying how long they have left only.
	cat <<- EOF > $TIMER_USER_PROGRAM
		# Remember to not run this script as the regular user as otherwise they can just kill the process
		# TODO: The user needs to be able to close the timer, and it still needs to continue the countdown.

		# Credits: https://handybashscripts.blogspot.com/2012/01/simple-timer-with-progress-bar.html

		#ICON=/usr/share/icons/Yaru/48x48/apps/clock-app.png        # Existing icon?
		ICON=clock-app                                              # Existing icon?

		COUNT=$1
		START=$COUNT                                                # Set a start point.

		until [ "$COUNT" -eq "0" ]; do                              # Countdown loop.
		    COUNT=$((COUNT-1))                                      # Decrement seconds.
		    PERCENT=$((100-100*COUNT/START))                        # Calc percentage.
		    echo "#Tid tilbage: $(echo "obase=60;$COUNT" | bc)"     # Convert to H:M:S.
		    echo $PERCENT                                           # Output for progbar.
		    #echo $COUNT | xsel -i -p
		    sleep 1
		done | zenity --title "Logintid" --progress --percentage=0 --text="" \
		    --window-icon $ICON --icon-name $ICON --auto-close --no-cancel # Progbar/time left.

		#xsel -o -p

		#notify-send -i $ICON "## Tiden er udløbet: Du logges af. ##"        # Attention finish!
		zenity --notification --window-icon $ICON --icon-name $ICON \
		    --text "## Tiden er udløbet: Du logges af. ##"                   # Indicate finished!
	EOF

  systemd enable $(basename $TIMER_USER_SYSTEMD_UNIT) $(basename $TIMER_LOGOUT_SYSTEMD_UNIT)

else # Delete the timer
  systemd disable $(basename $TIMER_USER_SYSTEMD_UNIT) $(basename $TIMER_LOGOUT_SYSTEMD_UNIT)
  rm $TIMER_USER_SYSTEMD_UNIT $TIMER_LOGOUT_SYSTEMD_UNIT $TIMER_LOGOUT_PROGRAM $TIMER_USER_PROGRAM
fi
