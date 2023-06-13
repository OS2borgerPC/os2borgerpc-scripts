#!/usr/bin/env sh

set -x

POLICY_VALUE="$2"

# Change these three to set a different policy to another value
POLICY_PATH="org/gnome/SimpleScan"
POLICY="selected-device"
# Whatever priority you want for the file. Doesn't matter much but important things should have a low number
POLICY_PRIORITY="05"

POLICY_FILE="/etc/dconf/db/os2borgerpc.d/$POLICY_PRIORITY-$POLICY"
POLICY_LOCK_FILE="/etc/dconf/db/os2borgerpc.d/locks/$POLICY_PRIORITY-$POLICY"

ACTIVATE=$1

if [ "$ACTIVATE" = 'True' ]; then
	mkdir --parents "$(dirname "$POLICY_FILE")" "$(dirname "$POLICY_LOCK_FILE")"

	# dconf does not, by default, require the use of a system database, so
	# add one (called "os2borgerpc") to store our system-wide settings in
	cat > "/etc/dconf/profile/user" <<-END
		user-db:user
		system-db:os2borgerpc
	END

	cat > "$POLICY_FILE" <<-END
		[$POLICY_PATH]
		$POLICY=$POLICY_VALUE
	END
	# "dconf update" will only act if the content of the keyfile folder has
	# changed: individual files changing are of no consequence. Force an update
	# by changing the folder's modification timestamp
	touch "$(dirname "$POLICY_FILE")"

	# Tell the system that the values of the dconf keys we've just set can no
	# longer be overridden by the user
	cat > "$POLICY_LOCK_FILE" <<-END
		/$POLICY_PATH/$POLICY
	END
else
	rm --force "$POLICY_FILE" "$POLICY_LOCK_FILE"
fi

# Incorporate all of the text files we've just created into the system's dconf databases
dconf update
