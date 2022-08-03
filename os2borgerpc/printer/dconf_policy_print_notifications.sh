#! /usr/bin/env sh
#
# SYNOPSIS
#    dconf_policy_print_notifications.sh [ENFORCE]
#
# DESCRIPTION
#    This script installs a policy that forcefully prevents
#    print notifications from popping up.
#
#    It takes one optional parameter: whether or not to enforce this policy.
#    Use a boolean to decide whether or not to enforce this policy, a checked box
#	   will enable the script, an unchecked box will remove it.
#
# IMPLEMENTATION
#    copyright       Copyright 2022, Magenta ApS
#    license         GNU General Public License

set -x

POLICY_PATH="org/gnome/desktop/notifications/application/gnome-printers-panel"
POLICY="show-banners"
POLICY_VALUE="false"

POLICY_FILE="/etc/dconf/db/os2borgerpc.d/00-$POLICY"
POLICY_LOCK_FILE="/etc/dconf/db/os2borgerpc.d/locks/00-$POLICY"

ACTIVATE=$1

if [ "$ACTIVATE" = 'True' ]; then
	mkdir --parents "$(dirname "$POLICY")"
	mkdir --parents "$(dirname "$POLICY_LOCK")"

	# dconf does not, by default, require the use of a system database, so
	# add one (called "os2borgerpc") to store our system-wide settings in
	cat > "/etc/dconf/profile/user" <<- END
		user-db:user
		system-db:os2borgerpc
	END

	# Alternately disable notifications for print completely:
	# enable=false
	cat > "$POLICY_FILE" <<- END
		[$POLICY_PATH]
		$POLICY=$POLICY_VALUE
	END
	# "dconf update" will only act if the content of the keyfile folder has
	# changed: individual files changing are of no consequence. Force an update
	# by changing the folder's modification timestamp
	touch "$(dirname "$POLICY")"

	# Tell the system that the values of the dconf keys we've just set can no
	# longer be overridden by the user
	cat > "$POLICY_LOCK_FILE" <<- END
		/$POLICY_PATH/$POLICY
	END
else
	rm -f "$POLICY_FILE" "$POLICY_LOCK_FILE"
fi

# Incorporate all of the text files we've just created into the system's dconf databases
dconf update
