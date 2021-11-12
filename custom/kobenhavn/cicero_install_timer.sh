#! /usr/bin/env sh

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

export DEBIAN_FRONTEND=noninteractive

SHADOW=".skjult"
TIMER_LOGOUT_PROGRAM="/usr/share/os2borgerpc/bin/logout_timer.sh"
TIMER_LOGOUT_SYSTEMD_UNIT="/etc/systemd/system/os2borgerpc-logout-timer.service"
TIMER_USER_PROGRAM="/usr/share/os2borgerpc/bin/logout_timer_user.sh"
TIMER_USER_DESKTOP_FILE="/home/$SHADOW.config/autostart/logout-timer_user.desktop"

if [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] && \
   [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then
  # TODO: Do we need to install zenity?

  # The default time before logout
  printf "TIME_SECONDS=%s" "$SECONDS_TO_LOGOUT" > /usr/share/os2borgerpc/logout_timer.conf

  # This timer handles the actual logout and thus runs as root so the user can't kill the process
	cat <<- EOF > $TIMER_LOGOUT_PROGRAM
		#! /usr/bin/env sh

		# Remember to not run this script as the regular user as otherwise they can just kill the process

    # Quite hacky way to disable this for all others besides 'user'
    [ whoami != "user" ] && exit 0

    . /usr/share/os2borgerpc/logout_timer.conf

    COUNT=$TIME_SECONDS

		until [ "$COUNT" -eq "0" ]; do                              # Countdown loop.
		    COUNT=$((COUNT-1))                                      # Decrement seconds.
		    sleep 1
		done

    su --login user --command "DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u user)/bus" gnome-session-quit --logout --no-prompt"
    # Alternate approach:
    # who -u    #to obtain the ID of the session?
    # kill $idFoundAbove
    # Alternate approach:
    # killall lightdm
    # Alternate approach:
    # killall gnome-session
	EOF


	cat <<- EOF > $TIMER_LOGOUT_SYSTEMD_UNIT
		[Unit]
		Description=Run the logout timer after user login
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

  # This timer is for visually displaying how long they have left only.
	cat <<- EOF > $TIMER_USER_PROGRAM
		# Credits: https://handybashscripts.blogspot.com/2012/01/simple-timer-with-progress-bar.html

    . /usr/share/os2borgerpc/logout_timer.conf

    # Subtracting a little from this as we need this to run at least a bit before they're logged out
    COUNT=$((TIME_SECONDS - 15))

		#ICON=/usr/share/icons/Yaru/48x48/apps/clock-app.png
		ICON=clock-app

		COUNT=$1
		START=$COUNT                                                # Set a starting point.

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

	# Autorun file that simply launches the script above after startup
	cat <<- EOF > "$TIMER_USER_DESKTOP_FILE"
		[Desktop Entry]
		Type=Application
		Name=Automatically allow launching of .desktop files on the desktop
		Exec=$TIMER_USER_PROGRAM
		Icon=system-run
		X-GNOME-Autostart-enabled=true
	EOF

  systemd enable "$(basename $TIMER_LOGOUT_SYSTEMD_UNIT)"

else # Delete the timer
  systemd disable "$(basename $TIMER_LOGOUT_SYSTEMD_UNIT)"
  rm $TIMER_LOGOUT_SYSTEMD_UNIT $TIMER_LOGOUT_PROGRAM $TIMER_USER_PROGRAM
fi
