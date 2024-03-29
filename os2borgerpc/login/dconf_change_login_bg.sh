#! /usr/bin/env sh

# Sets new background image on login-screen

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

ACTIVATE=$1
IMAGE_UPLOAD=$2
IMAGE_NAME=$(basename "$IMAGE_UPLOAD")

mv "$IMAGE_UPLOAD" "/usr/share/backgrounds/"

# Change these three to set a different policy to another value
POLICY_PATH="com/canonical/unity-greeter"
POLICY="background"
POLICY_VALUE="'/usr/share/backgrounds/$IMAGE_NAME'"

POLICY_FILE="/etc/dconf/db/os2borgerpc.d/06-login-screen-bg-image"
POLICY_LOCK_FILE="/etc/dconf/db/os2borgerpc.d/locks/06-login-screen-bg-image"


if [ "$ACTIVATE" = 'True' ]; then

	mkdir --parents "$(dirname $POLICY_FILE)" "$(dirname $POLICY_LOCK_FILE)"

	# dconf does not, by default, require the use of a system database, so
	# add one (called "os2borgerpc") to store our system-wide settings in
	cat > "/etc/dconf/profile/user" <<-END
		user-db:user
		system-db:os2borgerpc
	END

	cat > "$POLICY_FILE" <<-END
		[$POLICY_PATH]
		draw-user-backgrounds=false
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
    rm POLICY_VALUE
fi

# Incorporate all of the text files we've just created into the system's dconf databases
dconf update
