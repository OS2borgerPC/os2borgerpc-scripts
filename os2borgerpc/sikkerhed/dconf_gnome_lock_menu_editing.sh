#! /usr/bin/env sh

ACTIVATE=$1

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

POLICY_LOCK_FILE=/etc/dconf/db/os2borgerpc.d/locks/02-launcher-favorites

# Locks the menu so it can't be edited (adding/removing/moving items in the menu)
if [ "$ACTIVATE" = 'True' ]; then
	cat <<- EOF > $POLICY_LOCK_FILE
		/org/gnome/shell/favorite-apps
	EOF
else
	rm $POLICY_LOCK_FILE
fi

dconf update
