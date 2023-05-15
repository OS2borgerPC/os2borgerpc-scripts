#! /usr/bin/env sh

set -x

# This will not work if they have disabled user cleanup,
# at least not if lightdm is configured to not use it

# Use a boolean as parameter. A checked box will restrict write access
# an unchecked will restore default

# Why not use a .config/autostart file? Because the user isn't allowed to chown to root
# ...even if they are the current owner.

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
export "$(grep LANG= /etc/default/locale)"
runuser -u $USERNAME xdg-user-dirs-update
DESKTOP=$(basename "$(runuser -u $USERNAME xdg-user-dir DESKTOP)")
USER_CLEANUP=/usr/share/os2borgerpc/bin/user-cleanup.bash
COMMENT="# Make the desktop read only to user"
# This is to prevent mv'ing DESKTOP to another name, and then creating a new one
# which they DO have write permissions to
# Another option considered was chowning /home/user itself (not recursively),
# but then login didn't work. (maybe due to .xauthority?)

ACTIVATE=$1

make_desktop_writable() {
	# These matches are deliberately written to be pretty general to match the contents that older versions of the script added
	# All of the matched lines are deleted. This function thus serves to undo write access removal
  # shellcheck disable=SC2016
	sed --in-place --expression "\@chattr [-+]i@d" --expression "\@chown -R root:@d" \
		  --expression "\@$COMMENT@d" --expression '\@runuser@d' --expression '\@export@d' $USER_CLEANUP
	chattr -i "$DESKTOP"
}

# Make sure that DESKTOP dir exists under .skjult as otherwise this script will not work correctly
mkdir --parents "/home/.skjult/$(basename "$DESKTOP")"

# Undo write access removal.
# We always do this to prevent adding the same lines multiple times (idempotency)
make_desktop_writable

if [ "$ACTIVATE" = 'True' ]; then
	# Prepend temporarily set it mutable before copying new files in, as otherwise that will fail
	# We first determine the name of the user desktop directory as before
	sed -i "/USERNAME=\"$USERNAME\"/a \
export \$(grep LANG= \/etc\/default\/locale)\n\
runuser -u $USERNAME xdg-user-dirs-update\n\
DESKTOP=\$(runuser -u $USERNAME xdg-user-dir DESKTOP)\n\
chattr -i \$DESKTOP" $USER_CLEANUP

	# Append setting the more restrictive permissions
	cat <<- EOF >> $USER_CLEANUP
		$COMMENT
		chown -R root:\$USERNAME \$DESKTOP
		chattr +i \$DESKTOP
	EOF
fi
