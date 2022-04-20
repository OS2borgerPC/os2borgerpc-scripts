#!/usr/bin/env sh

# SYNOPSIS
#    dconf_policy_desktop.sh [FILE]
#
# DESCRIPTION
#    This script changes and locks the desktop background for all users on the
#    system using a dconf lock.
#
#    It takes one parameter: the path to the desktop background.

set -x

POLICY="/etc/dconf/db/os2borgerpc.d/00-background"
POLICY_LOCK="/etc/dconf/db/os2borgerpc.d/locks/background"


if [ -n "$1" ]; then
	mkdir --parents "$(dirname "$POLICY")" "$(dirname "$POLICY_LOCK")"

	# dconf does not, by default, require the use of a system database, so
	# add one (called "os2borgerpc") to store our system-wide settings in
  cat > "/etc/dconf/profile/user" <<-END
		user-db:user
		system-db:os2borgerpc
	END

	# Copy the new desktop background into the appropriate folder
	LOCAL_PATH="/usr/share/backgrounds"
	cp "$1" "$LOCAL_PATH/"

	cat > "$POLICY" <<-END
		[org/gnome/desktop/background]
		picture-uri='file://$LOCAL_PATH'
		picture-options='zoom'
	END
	# "dconf update" will only act if the content of the keyfile folder has
	# changed: individual files changing are of no consequence. Force an update
	# by changing the folder's modification timestamp
	touch "$(dirname "$POLICY")"

	# Tell the system that the values of the dconf keys we've just set can no
	# longer be overridden by the user
	cat > "$POLICY_LOCK" <<-END
		/org/gnome/desktop/background/picture-uri
		/org/gnome/desktop/background/picture-options
	END
else
	printf "This script requires one parameter: The path to a file to be set as background"
	exit 1
fi

# Incorporate all of the text files we've just created into the system's dconf databases
dconf update
