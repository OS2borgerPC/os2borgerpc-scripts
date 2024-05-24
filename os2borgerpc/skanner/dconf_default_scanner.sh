#!/usr/bin/env sh

set -x

POLICY_VALUE="$2"

# Change these three to set a different policy to another value
POLICY_PATH="org/gnome/simple-scan"
POLICY="selected-device"
# These two are used to Name the dconf policy file, which can really be whatever you want. Give files lower numbers to load earlier
POLICY_PRIORITY="05"
POLICY_READABLE_NAME="default-scanner"

POLICY_FILE="/etc/dconf/db/os2borgerpc.d/$POLICY_PRIORITY-$POLICY_READABLE_NAME"
POLICY_LOCK_FILE="/etc/dconf/db/os2borgerpc.d/locks/$POLICY_PRIORITY-$POLICY_READABLE_NAME"

ACTIVATE=$1

if [ "$ACTIVATE" = 'True' ]; then

	cat > "$POLICY_FILE" <<- END
		[$POLICY_PATH]
		$POLICY="$POLICY_VALUE"
	END
	# "dconf update" will only act if the content of the keyfile folder has
	# changed: individual files changing are of no consequence. Force an update
	# by changing the folder's modification timestamp
	touch "$(dirname "$POLICY_FILE")"

	# Tell the system that the values of the dconf keys we've just set can no
	# longer be overridden by the user
	cat > "$POLICY_LOCK_FILE" <<- END
		/$POLICY_PATH/$POLICY
	END
else
	rm --force "$POLICY_FILE" "$POLICY_LOCK_FILE"
fi

# Incorporate all of the text files we've just created into the system's dconf databases
dconf update
