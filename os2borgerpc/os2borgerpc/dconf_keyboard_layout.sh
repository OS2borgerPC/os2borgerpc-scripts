#! /usr/bin/env sh

# SYNOPSIS
#    dconf_keyboard_layout.sh [ENFORCE]
#
# DESCRIPTION
#    This script installs a policy that adds a keyboard layout and as a
#    side effect it makes the keyboard layout switcher viewable in the menu bar
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

ACTIVATE=$1
LANGUAGE_TO_ADD=$2 # Example: ua for Ukrainian

# Determine the default language by checking LANG in /etc/default/locale
# The equal sign is there to prevent matching LANGUAGE if it is present in the file
DEFAULT_LANGUAGE=$(grep LANG= /etc/default/locale | cut --delimiter '_' --fields 2 | cut --delimiter '.' --fields 1)
DEFAULT_LANGUAGE=$(echo "$DEFAULT_LANGUAGE" | tr '[:upper:]' '[:lower:]')

# Change these three to set a different policy to another value
POLICY_PATH="org/gnome/desktop/input-sources"
POLICY="sources"
POLICY_VALUE="[('xkb','$DEFAULT_LANGUAGE'),('xkb','$LANGUAGE_TO_ADD')]"

POLICY_FILE="/etc/dconf/db/os2borgerpc.d/00-keyboard-layout"
POLICY_LOCK_FILE="/etc/dconf/db/os2borgerpc.d/locks/00-keyboard-layout"

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
	rm --force "$POLICY_FILE" "$POLICY_LOCK_FILE"
fi

# Incorporate all of the text files we've just created into the system's dconf databases
dconf update
