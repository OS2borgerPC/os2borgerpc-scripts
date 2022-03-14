#! /usr/bin/env sh

# This will not work if they have disabled user cleanup,
# at least not if lightdm is configured to not use it

# Why not use a .config/autostart file? Because the user isn't allowed to chown to root
# ...even if they are the current owner.

USER="user"
DESKTOP="Skrivebord"
USER_CLEANUP=/usr/share/os2borgerpc/bin/user-cleanup.bash
TEXT1="chown -R root:user /home/$USER/$DESKTOP"
# This is to prevent mv'ing Skrivebord to another name, and then creating a new one
# which they DO have write permissions to
# Another option considered was chowning /home/user itself (not recursively),
# but then login didn't work. (maybe due to .xauthority?)
TEXT2="chattr +i /home/$USER/$DESKTOP"

lower() {
	echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"

if [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] && \
   [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then
	# Don't add it if it's already there (idempotency)
	if ! grep -q -- "$TEXT1" "$USER_CLEANUP"; then
		cat <<- EOF >> $USER_CLEANUP
			$TEXT1
			$TEXT2
		EOF
	fi
else
	# Restore default, which currently is write access
	sed -i "\@$TEXT1@d" $USER_CLEANUP
	sed -i "\@$TEXT2@d" $USER_CLEANUP
  chattr -i /home/$USER/$DESKTOP
fi
