#!/usr/bin/env sh

# SYNOPSIS
#    dconf_policy_a11y.sh [ENFORCE]
#
# DESCRIPTION
#    This script installs a policy that forces the Universal Access menu to be
#    shown at all times.
#
#    Use a boolean to decide whether to enforce or not. An unchecked box will
#    remove the policy and a checked one will enforce it.
#
# IMPLEMENTATION
#    copyright       Copyright 2022, Magenta ApS
#    license         GNU General Public License

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

# Change these three to set a different policy to another value
POLICY_PATH="org/gnome/desktop/a11y"
POLICY="always-show-universal-access-status"
POLICY_VALUE="true"

POLICY_FILE="/etc/dconf/db/os2borgerpc.d/00-accessibility"
POLICY_LOCK_FILE="/etc/dconf/db/os2borgerpc.d/locks/00-accessibility"

ACTIVATE=$1

# Delete the previous lock file (its name has changed)
rm --force /etc/dconf/db/os2borgerpc.d/locks/accessibility

if [ "$ACTIVATE" = 'True' ]; then

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
	rm -f "$POLICY_FILE" "$POLICY_LOCK_FILE"
fi

# Incorporate all of the text files we've just created into the system's dconf databases
dconf update
