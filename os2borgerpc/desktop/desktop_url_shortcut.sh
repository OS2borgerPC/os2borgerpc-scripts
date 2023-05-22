#! /usr/bin/env sh

# Creates a customly named shortcut on the desktop for the normal user, which
# opens the URL given as an argument in the default browser.
#
# After the script has run log out or restart the computer for the changes to
# take effect.
#
# Arguments:
# 1: A boolean to decide whether to add or not. A checked box will
# add the shortcut and an unchecked will remove it
# 2: The URL to visit when clicked
# 3: The name the shortcut should have - it needs to be a valid filename!
# 4: The path to an icon. If empty an icon from the current theme is used, specified below

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

ACTIVATE=$1
URL=$2
SHORTCUT_NAME="$3"
ICON_UPLOAD="$4"

# Determine the name of the user desktop directory. This is done via xdg-user-dir,
# which checks the /home/user/.config/user-dirs.dirs file. To ensure this file exists,
# we run xdg-user-dirs-update, which generates it based on the environment variable
# LANG. This variable is empty in lightdm so we first export it
# based on the value stored in /etc/default/locale
export "$(grep LANG= /etc/default/locale | tr -d '"')"
runuser -u user xdg-user-dirs-update
DESKTOP=$(basename "$(runuser -u user xdg-user-dir DESKTOP)")

SHADOW=".skjult"
DESKTOP_FILE="/home/$SHADOW/$DESKTOP/$SHORTCUT_NAME.desktop"

if [ "$ACTIVATE" = 'True' ]; then

  if [ -z "$ICON_UPLOAD" ]; then
    ICON="preferences-system-network"
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
      cp "$ICON_UPLOAD" $ICON_BASE_PATH/
      # Two ways to reference an icons:
      # 1. As a full path to the icon including it's extension. This works for PNG, SVG, JPG
      # 2. As a name without path and extension, likely as long as it's within an icon cache path. This works for PNG, SVG - but not JPG!
      ICON=$ICON_BASE_PATH/$ICON_NAME


      update-icon-caches $ICON_BASE_PATH
    fi
  fi

  mkdir --parents /home/$SHADOW/"$DESKTOP"

	#	Originally used: Type=Link and URL=$URL and no Exec line, but seemingly that doesn't work in 20.04
	cat <<- EOF > "$DESKTOP_FILE"
		[Desktop Entry]
		Encoding=UTF-8
		Name=$SHORTCUT_NAME
		Type=Application
		Exec=xdg-open $URL
		Icon=$ICON
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
