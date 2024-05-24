#! /usr/bin/env sh

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

# Example value:
# [org/gnome/desktop/peripherals/mouse]
# speed=-0.69117647058823528

# Convert potential commas used for decimals into dots
MOUSE_SPEED="$(echo "$1" | tr ',' '.')"

# Change these three to set a different policy to another value
POLICY_PATH="org/gnome/desktop/peripherals/mouse"
POLICY="speed"
POLICY_VALUE="$MOUSE_SPEED"

POLICY_FILE="/etc/dconf/db/os2borgerpc.d/00-$POLICY"
POLICY_LOCK_FILE="/etc/dconf/db/os2borgerpc.d/locks/00-$POLICY"

if [ "$MOUSE_SPEED" = "fra" ]; then
    rm --force "$POLICY_FILE" "$POLICY_LOCK_FILE"
else
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
fi

# Incorporate all of the text files we've just created into the system's dconf databases
dconf update
