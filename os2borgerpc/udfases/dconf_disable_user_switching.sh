#! /usr/bin/env sh

# Removes user switching from the menu

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

# Change these three to set a different policy to another value
POLICY_PATH="org/gnome/desktop/lockdown"
POLICY="disable-user-switching"
POLICY_VALUE="true"

POLICY_FILE="/etc/dconf/db/os2borgerpc.d/00-$POLICY"
POLICY_LOCK_FILE="/etc/dconf/db/os2borgerpc.d/locks/00-$POLICY"

cat > "$POLICY_FILE" <<-END
	[$POLICY_PATH]
	$POLICY=$POLICY_VALUE
END
# Tell the system that the values of the dconf keys we've just set can no
# longer be overridden by the user
cat > "$POLICY_LOCK_FILE" <<-END
	/$POLICY_PATH/$POLICY
END

# Incorporate all of the text files we've just created into the system's dconf databases
dconf update
