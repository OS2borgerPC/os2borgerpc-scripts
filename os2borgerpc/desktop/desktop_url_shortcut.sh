#! /usr/bin/env sh

# Creates a customly named shortcut on the desktop for the normal user, which
# opens the URL given as an argument in the default browser.
#
# After the script has run log out or restart the computer for the changes to
# take effect.
#
# Arguments:
# 1: ACTIVATE: Use a boolean to decide whether to add or not. A checked box will
# add the shortcut and an unchecked will remove it
# 2: URL: The URL to visit when clicked
# 3: SHORTCUT_NAME: The name the shortcut should have - it needs to be a valid filename!
# 4: ICON_UPLOAD: The path to an icon. If empty preferences-system-network from the current theme is used

set -x

ACTIVATE=$1
URL=$2
SHORTCUT_NAME="$3"
ICON_UPLOAD="$4"

SHADOW=".skjult"
DESKTOP_FILE="/home/$SHADOW/Skrivebord/$SHORTCUT_NAME.desktop"

if [ "$ACTIVATE" = 'True' ]; then

  if [ -z "$ICON_UPLOAD" ]; then
    ICON_NAME="preferences-system-network"
  else
    # HANDLE ICON HERE
    if ! echo "$ICON_UPLOAD" | grep --quiet '.png\|.svg\|.jpg\|.jpeg'; then
      printf "Error: Only .svg, .png, .jpg and .jpeg are supported as icon-formats."
      exit 1
    else
      ICON_BASE_PATH=/usr/local/share/icons
      mkdir --parents "$ICON_BASE_PATH"
      # Copy icon from the default destination to where it should actually be
      cp "$ICON_UPLOAD" $ICON_BASE_PATH/
      # A .desktop file apparently expects an icon without an extension
      ICON_NAME="$(basename "$ICON_UPLOAD" | sed -e 's/\.[^.]*$//')"

      update-icon-caches $ICON_BASE_PATH
    fi
  fi

  mkdir --parents /home/$SHADOW/Skrivebord

	#	Originally used: Type=Link and URL=$URL and no Exec line, but seemingly that doesn't work in 20.04
	cat <<- EOF > "$DESKTOP_FILE"
		[Desktop Entry]
		Encoding=UTF-8
		Name=$SHORTCUT_NAME
		Type=Application
		Exec=xdg-open $URL
		Icon=$ICON_NAME
	EOF

	chmod +x "$DESKTOP_FILE"
else
	rm "$DESKTOP_FILE"
	# Backwards compatibility:
	# In case they have an URL shortcut made with the previous version of this script,
	# this version should still allow them to remove that (it was an extensionless shell script)
  # Don't add recursive here, as otherwise with an empty argument it could delete the Skrivebord
  # directory itself
	rm --force "$(dirname "$DESKTOP_FILE")/$(basename -s ".desktop" "$DESKTOP_FILE")"
fi
