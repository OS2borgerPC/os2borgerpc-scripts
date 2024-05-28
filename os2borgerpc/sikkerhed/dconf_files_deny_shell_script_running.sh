#! /usr/bin/env sh

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

# Example value:
# [org/gnome/nautilus/preferences]
# executable-text-activation='display'

ENABLE="$1"

# Change these three to set a different policy to another value
POLICY_PATH="org/gnome/nautilus/preferences"
POLICY="executable-text-activation"
POLICY_VALUE="'display'"

POLICY_FILE="/etc/dconf/db/os2borgerpc.d/05-$POLICY"
POLICY_LOCK_FILE="/etc/dconf/db/os2borgerpc.d/locks/05-$POLICY"

if [ "$ENABLE" = "True" ]; then
	cat > "$POLICY_FILE" <<-END
		[$POLICY_PATH]
		$POLICY=$POLICY_VALUE
	END
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
