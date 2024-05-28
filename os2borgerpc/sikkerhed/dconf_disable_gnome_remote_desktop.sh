#! /usr/bin/env sh

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

# Change these three to set a different policy to another value
POLICY_FILE="/etc/dconf/db/os2borgerpc.d/00-remote-desktop"
POLICY_LOCK_FILE="/etc/dconf/db/os2borgerpc.d/locks/00-remote-desktop"

ACTIVATE=$1

if [ "$ACTIVATE" = 'True' ]; then
	# Disable GNOME Remote Desktop VNC + RDP (and also lock to "View Only" which should be superfluous when they can't be
	# enabled, but...)
	cat > "$POLICY_FILE" <<-END
		[org/gnome/desktop/remote-desktop/rdp]
		enable=false
		view-only=true
		[org/gnome/desktop/remote-desktop/vnc]
		enable=false
		view-only=true
	END

	# Tell the system that the values of the dconf keys we've just set can no
	# longer be overridden by the user
	cat > "$POLICY_LOCK_FILE" <<-END
		/org/gnome/desktop/remote-desktop/rdp/enable
		/org/gnome/desktop/remote-desktop/vnc/enable
		/org/gnome/desktop/remote-desktop/rdp/view-only
		/org/gnome/desktop/remote-desktop/vnc/view-only
	END
else
	rm --force "$POLICY_FILE" "$POLICY_LOCK_FILE"
fi

# Incorporate all of the text files we've just created into the system's dconf databases
dconf update
