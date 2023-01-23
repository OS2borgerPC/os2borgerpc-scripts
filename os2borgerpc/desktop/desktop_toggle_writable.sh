#! /usr/bin/env sh

set -x

# This will not work if they have disabled user cleanup,
# at least not if lightdm is configured to not use it

# Use a boolean as parameter. A checked box will restrict write access
# an unchecked will restore default

# Why not use a .config/autostart file? Because the user isn't allowed to chown to root
# ...even if they are the current owner.

USER="user"
DESKTOP="Skrivebord"
USER_CLEANUP=/usr/share/os2borgerpc/bin/user-cleanup.bash
SET_USER_DESKTOP_MUTABLE="chattr -i /home/$USER/$DESKTOP"
SET_USER_DESKTOP_ROOT_OWNED="chown -R root:user /home/$USER/$DESKTOP"
# This is to prevent mv'ing Skrivebord to another name, and then creating a new one
# which they DO have write permissions to
# Another option considered was chowning /home/user itself (not recursively),
# but then login didn't work. (maybe due to .xauthority?)
SET_USER_DESKTOP_IMMUTABLE="chattr +i /home/$USER/$DESKTOP"

ACTIVATE=$1

make_desktop_writable() {
	sed -i "\@$SET_USER_DESKTOP_MUTABLE@d" $USER_CLEANUP
	sed -i "\@$SET_USER_DESKTOP_ROOT_OWNED@d" $USER_CLEANUP
	sed -i "\@$SET_USER_DESKTOP_IMMUTABLE@d" $USER_CLEANUP
	chattr -i /home/$USER/$DESKTOP
}

# Make sure that /home/.skjult/Skrivebord exists as otherwise this script will not work correctly
mkdir --parents /home/.skjult/Skrivebord

# Undo write access removal.
# We always do this to prevent adding the same lines multiple times (idempotency)
make_desktop_writable

if [ "$ACTIVATE" = 'True' ]; then
	# Temporarily set it mutable before copying new files in, as otherwise that will fail
	sed -i "/# Restore \$HOME/a\ $SET_USER_DESKTOP_MUTABLE" $USER_CLEANUP
	cat <<- EOF >> $USER_CLEANUP
		$SET_USER_DESKTOP_ROOT_OWNED
		$SET_USER_DESKTOP_IMMUTABLE
	EOF
fi
