#! /usr/bin/env sh

set -x

# This will not work if they have disabled user cleanup,
# at least not if lightdm is configured to not use it

# Use a boolean as parameter. A checked box will restrict write access
# an unchecked will restore default

# Why not use a .config/autostart file? Because the user isn't allowed to chown to root
# ...even if they are the current owner.

# chattr on DESKTOP is to prevent mv'ing DESKTOP to another name, and then creating a new one
# which they DO have write permissions to
# Another option considered was chowning /home/user itself (not recursively),
# but then login didn't work. (maybe due to .xauthority?)

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

USERNAME="user"
# Determine the name of the user desktop directory. This is done via xdg-user-dir,
# which checks the /home/user/.config/user-dirs.dirs file. To ensure this file exists,
# we run xdg-user-dirs-update, which generates it based on the environment variable
# LANG. This variable is empty in lightdm so we first export it
# based on the value stored in /etc/default/locale
export "$(grep LANG= /etc/default/locale | tr -d '"')"
runuser -u $USERNAME xdg-user-dirs-update
DESKTOP="$(runuser -u $USERNAME xdg-user-dir DESKTOP)"
USER_CLEANUP=/usr/share/os2borgerpc/bin/user-cleanup.bash
COMMENT="# Make the desktop read only to user"

ACTIVATE=$1

make_desktop_writable() {
	# All of the matched lines are deleted. This function thus serves to undo write access removal
	# shellcheck disable=SC2016
	sed --in-place --expression "/chattr [-+]i/d" --expression "/chown -R root:/d" \
		  --expression "/$COMMENT/d" --expression '/runuser/d' --expression '/export/d' \
		  --expression "/chown \$USERNAME/d" --expression "/.config/d" --expression "/The exact cause/d" \
		  --expression "/The lines below/d" --expression "/login issues/d" $USER_CLEANUP
	chattr -i "$DESKTOP"
}

# Make sure that DESKTOP dir exists under .skjult as otherwise this script will not work correctly
mkdir --parents "/home/.skjult/$(basename "$DESKTOP")"

# Undo write access removal - always do this to prevent adding the same lines multiple times (idempotency)
make_desktop_writable

if [ "$ACTIVATE" = 'True' ]; then
	# Prepend temporarily setting DESKTOP mutable before copying new files in, as otherwise that will fail
	# We first determine the name of the user desktop directory as before
	sed -i "/USERNAME=\"$USERNAME\"/a \
export \$(grep LANG= \/etc\/default\/locale | tr -d \'\"\')\n\
runuser -u $USERNAME xdg-user-dirs-update\n\
DESKTOP=\$(runuser -u $USERNAME xdg-user-dir DESKTOP)\n\
chattr -i \$DESKTOP" $USER_CLEANUP

	# Append setting the more restrictive permissions
	cat <<- EOF >> $USER_CLEANUP
		$COMMENT
		chown -R root:\$USERNAME \$DESKTOP
		chattr +i \$DESKTOP
		# The exact cause is unclear, but xdg-user-dir will rarely fail in such
		# a way that DESKTOP=/home/user. The lines below prevent this error
		# from causing login issues.
		chattr -i /home/user/
		chown \$USERNAME:\$USERNAME /home/\$USERNAME
		chown -R \$USERNAME:\$USERNAME /home/\$USERNAME/.config /home/\$USERNAME/.local
	EOF
	# Make sure that DESKTOP is immutable immediately after running this script
	chattr +i "$DESKTOP"
fi
