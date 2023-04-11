#!/usr/bin/env sh

# SYNOPSIS
#    dconf_policy_desktop.sh [FILE]
#
# DESCRIPTION
#    This script changes and locks the desktop background for all users on the
#    system using a dconf lock.
#
#    It takes one parameter: the path to the desktop background.
#
# IMPLEMENTATION
#    copyright       Copyright 2022, Magenta ApS
#    license         GNU General Public License

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

IMAGE_FILE=$1

POLICY_FILE="/etc/dconf/db/os2borgerpc.d/00-background"
POLICY_LOCK_FILE="/etc/dconf/db/os2borgerpc.d/locks/background"


if [ -n "$IMAGE_FILE" ]; then
	mkdir --parents "$(dirname "$POLICY_FILE")" "$(dirname "$POLICY_LOCK_FILE")"

	# dconf does not, by default, require the use of a system database, so
	# add one (called "os2borgerpc") to store our system-wide settings in
  cat > "/etc/dconf/profile/user" <<-END
		user-db:user
		system-db:os2borgerpc
	END

	# Copy the new desktop background into the appropriate folder
	LOCAL_PATH="/usr/share/backgrounds/$(basename "$IMAGE_FILE")"
	cp "$IMAGE_FILE" "$LOCAL_PATH"

	cat > "$POLICY_FILE" <<-END
		[org/gnome/desktop/background]
		picture-uri='file://$LOCAL_PATH'
		picture-options='zoom'
	END
	# "dconf update" will only act if the content of the keyfile folder has
	# changed: individual files changing are of no consequence. Force an update
	# by changing the folder's modification timestamp
	touch "$(dirname "$POLICY_FILE")"

	# Tell the system that the values of the dconf keys we've just set can no
	# longer be overridden by the user
	cat > "$POLICY_LOCK_FILE" <<-END
		/org/gnome/desktop/background/picture-uri
		/org/gnome/desktop/background/picture-options
	END
else
	printf "This script requires one parameter: The path to a file to be set as background"
	exit 1
fi

# Incorporate all of the text files we've just created into the system's dconf databases
dconf update
