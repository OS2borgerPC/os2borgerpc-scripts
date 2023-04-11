#! /usr/bin/env sh

# Arguments:
# 1: Whether to add or remove the logout button from the menu. 'True' adds it.
# 2: The name the shortcut should have in the menu (display when you hover over the icon)
# 3: Whether to put the icon at the start of the end of the menu. 'True' for start, 'False' for end.
# 4: An optional icon to use for the shortcut. Ideally SVG, but PNG and JPG work as well.

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

ADD="$1"
SHORTCUT_NAME="$2"
MENU_START="$3"
ICON_UPLOAD="$4"

DESKTOP_FILE=/usr/share/applications/os2borgerpc-menu-logout.desktop
DESKTOP_FILE_NAME=$(basename $DESKTOP_FILE)
LAUNCHER_FAVORITES_FILE=/etc/dconf/db/os2borgerpc.d/02-launcher-favorites

remove_logout_buttons_from_menu()  {
	# Remove it from the start of the list
	sed -i "s/\['$DESKTOP_FILE_NAME', /\[/" $LAUNCHER_FAVORITES_FILE
	# Remove it from the end of the list
	sed -i "s/, '$DESKTOP_FILE_NAME'//" $LAUNCHER_FAVORITES_FILE
}

if [ "$ADD" = False ]; then
	remove_logout_buttons_from_menu
else

	if [ -z "$ICON_UPLOAD" ]; then
		ICON="system-log-out"
	else

		# HANDLE ICON HERE
		if ! echo "$ICON_UPLOAD" | grep --quiet '.png\|.svg\|.jpg\|.jpeg'; then
			printf "Error: Only .svg, .png, .jpg and .jpeg are supported as icon-formats."
			exit 1
		else
			ICON_BASE_PATH=/usr/local/share/icons
			ICON_NAME="$(basename "$ICON_UPLOAD")"
			mkdir --parents "$ICON_BASE_PATH"
			# Copy icon from the default destination to where it should actually be
			# Two ways to reference an icons:
			# 1. As a full path to the icon including it's extension. This works for PNG, SVG, JPG
			# 2. As a name without path and extension, likely as long as it's within an icon cache path. This works for PNG, SVG - but not JPG!
			cp "$ICON_UPLOAD" $ICON_BASE_PATH
			ICON=$ICON_BASE_PATH/$ICON_NAME

			update-icon-caches $ICON_BASE_PATH
		fi
	fi

	cat <<- EOF > $DESKTOP_FILE
		[Desktop Entry]
		Type=Application
		Name=$SHORTCUT_NAME
		Icon=$ICON
		Exec=gnome-session-quit --logout
	EOF

	# Idempotency: First remove the shortcut if it's already there (if not it has no effect), before adding adding it
	remove_logout_buttons_from_menu

	# ...and now add it:
	if [ "$MENU_START" = "True" ]; then
			sed -i "s/favorite-apps=\[/favorite-apps=\['$DESKTOP_FILE_NAME', /" $LAUNCHER_FAVORITES_FILE
	else
			sed -i "s/'\]/', '$DESKTOP_FILE_NAME'\]/" $LAUNCHER_FAVORITES_FILE
	fi

fi

dconf update
