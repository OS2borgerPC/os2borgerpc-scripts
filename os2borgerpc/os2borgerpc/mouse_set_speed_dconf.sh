#! /usr/bin/env sh

set -x

# Example value:
# [org/gnome/desktop/peripherals/mouse]
# speed=-0.69117647058823528

# Convert potential commas used for decimals into dots
MOUSE_SPEED="$(echo "$@" | tr ',' '.')"

# Change these three to set a different policy to another value
POLICY_PATH="org/gnome/desktop/peripherals/mouse"
POLICY="speed"
POLICY_VALUE="$MOUSE_SPEED"

POLICY_FILE="/etc/dconf/db/os2borgerpc.d/00-$POLICY"
POLICY_LOCK_FILE="/etc/dconf/db/os2borgerpc.d/locks/00-$POLICY"

if [ "$1" = "fra" ]; then
    rm -f "$POLICY_FILE" "$POLICY_LOCK_FILE"
else

    mkdir --parents "$(dirname $POLICY_FILE)" "$(dirname $POLICY_LOCK_FILE)"

    # dconf does not, by default, require the use of a system database, so
    # add one (called "os2borgerpc") to store our system-wide settings in
    cat > "/etc/dconf/profile/user" <<END
user-db:user
system-db:os2borgerpc
END

    cat > "$POLICY_FILE" <<END
[$POLICY_PATH]
$POLICY=$POLICY_VALUE
END
    # "dconf update" will only act if the content of the keyfile folder has
    # changed: individual files changing are of no consequence. Force an update
    # by changing the folder's modification timestamp
    touch "$(dirname "$POLICY_FILE")"

    # Tell the system that the values of the dconf keys we've just set can no
    # longer be overridden by the user
    cat > "$POLICY_LOCK_FILE" <<END
/$POLICY_PATH/$POLICY
END
fi

# Incorporate all of the text files we've just created into the system's dconf databases
dconf update
