#!/usr/bin/env sh

# SYNOPSIS
#    dconf_policy_desktop.sh [FILE]
#
# DESCRIPTION
#    This script changes and locks the desktop background for all users on the
#    system using a dconf lock.
#
#    It requires one parameter: the path to the desktop background.
#	 The second parameter is optional and relates to picture option, it defaults to "zoom".
#	 Picture options accept: zoom, centered, stretched, spanned, wallpaper, scaled
#
# IMPLEMENTATION
#    copyright       Copyright 2022, Magenta ApS
#    license         GNU General Public License

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

lower() {
	echo "$@" | tr '[:upper:]' '[:lower:]'
}

IMAGE_FILE=$1
OPTION_VALUE=$(lower "$2")
POLICY_FILE="/etc/dconf/db/os2borgerpc.d/00-background"
POLICY_LOCK_FILE="/etc/dconf/db/os2borgerpc.d/locks/00-background"

# Delete the previous lock file (its name has changed)
rm --force /etc/dconf/db/os2borgerpc.d/locks/background

if [ -n "$IMAGE_FILE" ]; then

	if [ -n "$OPTION_VALUE" ]; then
		if ! echo "$OPTION_VALUE" | grep --ignore-case --extended-regexp "^(zoom|centered|stretched|wallpaper|scaled|none)$"; then
			echo "The second parameter must be one of: zoom, centered, stretched, wallpaper, scaled, none"
			exit 1
		fi
	else
		OPTION_VALUE="zoom"
	fi

	# Copy the new desktop background into the appropriate folder
	LOCAL_PATH="/usr/share/backgrounds/$(basename "$IMAGE_FILE")"
	cp "$IMAGE_FILE" "$LOCAL_PATH"

	cat > "$POLICY_FILE" <<-END
		[org/gnome/desktop/background]
		picture-uri='file://$LOCAL_PATH'
		picture-options='$OPTION_VALUE'
	END
	# Tell the system that the values of the dconf keys we've just set can no
	# longer be overridden by the user
	cat > "$POLICY_LOCK_FILE" <<-END
		/org/gnome/desktop/background/picture-uri
		/org/gnome/desktop/background/picture-options
	END
else
	printf "This script requires one parameter: The path to a file to be set as background"
	exit 1
fi

# Incorporate all of the text files we've just created into the system's dconf databases
dconf update
