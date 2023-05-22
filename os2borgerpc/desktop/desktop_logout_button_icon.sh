#! /usr/bin/env sh

# Arguments:
# 1: A boolean to decide whether to add or remove the button
# 2: The name the shortcut should have on the desktop.
# 3: A boolean to decide whether to prompt before logging out or log out immediately
# 4: An optional icon to use for the shortcut. Ideally SVG, but PNG and JPG work as well.

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

ACTIVATE=$1
SHORTCUT_NAME="$2"
PROMPT=$3
ICON_UPLOAD="$4"

# Determine the name of the user desktop directory. This is done via xdg-user-dir,
# which checks the /home/user/.config/user-dirs.dirs file. To ensure this file exists,
# we run xdg-user-dirs-update, which generates it based on the environment variable
# LANG. This variable is empty in lightdm so we first export it
# based on the value stored in /etc/default/locale
export "$(grep LANG= /etc/default/locale | tr -d '"')"
runuser -u user xdg-user-dirs-update
DESKTOP=$(basename "$(runuser -u user xdg-user-dir DESKTOP)")

OLD_DESKTOP_FILE=/home/.skjult/"$DESKTOP"/Logout.desktop
DESKTOP_FILE=/home/.skjult/"$DESKTOP"/logout.desktop

rm --force "$OLD_DESKTOP_FILE"

if [ "$ACTIVATE" = 'True' ]; then

  mkdir --parents "$(dirname "$DESKTOP_FILE")"

  TO_PROMPT_OR_NOT=--no-prompt

  if [ "$PROMPT" = "True" ]; then
    # If they DO want the prompt
    unset TO_PROMPT_OR_NOT
  fi

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
      cp "$ICON_UPLOAD" $ICON_BASE_PATH
      # Two ways to reference an icons:
      # 1. As a full path to the icon including it's extension. This works for PNG, SVG, JPG
      # 2. As a name without path and extension, likely as long as it's within an icon cache path. This works for PNG, SVG - but not JPG!
      ICON=$ICON_BASE_PATH/$ICON_NAME

      update-icon-caches $ICON_BASE_PATH
    fi
  fi

cat <<- EOF > "$DESKTOP_FILE"
	[Desktop Entry]
	Version=1.0
	Type=Application
	Name=$SHORTCUT_NAME
	Comment=Logud
	Icon=$ICON
	Exec=sh -c "sleep 0.1 && gnome-session-quit --logout $TO_PROMPT_OR_NOT"
EOF

else
  rm "$DESKTOP_FILE"
fi
