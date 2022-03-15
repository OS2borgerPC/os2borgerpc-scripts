#! /usr/bin/env sh

# This will not work if they have disabled user cleanup,
# at least not if lightdm is configured to not use it

# Why not use a .config/autostart file? Because the user isn't allowed to chown to root
# ...even if they are the current owner.

USER="user"
DESKTOP="Skrivebord"
USER_CLEANUP=/usr/share/os2borgerpc/bin/user-cleanup.bash
TEXT1="chattr -i /home/$USER/$DESKTOP"
TEXT2="chown -R root:user /home/$USER/$DESKTOP"
# This is to prevent mv'ing Skrivebord to another name, and then creating a new one
# which they DO have write permissions to
# Another option considered was chowning /home/user itself (not recursively),
# but then login didn't work. (maybe due to .xauthority?)
TEXT3="chattr +i /home/$USER/$DESKTOP"

lower() {
	echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"

cleanup() {
	# Restore write access
	sed -i "\@$TEXT1@d" $USER_CLEANUP
	sed -i "\@$TEXT2@d" $USER_CLEANUP
	sed -i "\@$TEXT3@d" $USER_CLEANUP
	chattr -i /home/$USER/$DESKTOP
}

# First cleanup after previous runs of this script (idempotency)
cleanup

if [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] && \
   [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then
	# Temporarily set it mutable before copying new files in, as otherwise that will fail
	sed -i "/# Restore \$HOME/a\ $TEXT1" $USER_CLEANUP
		cat <<- EOF >> $USER_CLEANUP
		$TEXT2
		$TEXT3
	EOF
fi
