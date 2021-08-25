#! /usr/bin/env sh

# Author: mfm@magenta.dk
#
# Arguments:
# 1: Whether to add or delete the shortcut from the desktop.
#    'nej' or 'falsk' removes it.
# 2: The name the button should have on the desktop. 
#    If you choose deletion, the contents of the name argument does not matter.
# 3: Whether to prompt for restart or not
# 4: The icon to use for the button. Ideally SVG, but PNG works as well.
#    If you choose deletion, which file you add here doesn't matter.

set -x

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

NAME=$1
PROMPT="$(lower "$2")"
ICON_UPLOAD=$3

FILE_PATH=/home/.skjult/Skrivebord/Logout.desktop

TO_PROMPT_OR_NOT=--no-prompt

if [ "$PROMPT" != 'false' ] && [ "$PROMPT" != 'falsk' ] && \
   [ "$PROMPT" != 'no' ] && [ "$PROMPT" != 'nej' ]; then
  # If they DO want the prompt
  unset TO_PROMPT_OR_NOT
fi

# HANDLE ICON HERE
if ! echo "$ICON_UPLOAD" | grep --quiet '.png\|.svg'; then
  printf "Fejl: Kun .svg og .png understøttes som ikon-formater."
  exit 1
else
  ICON_BASE_PATH=/usr/local/share/icons/
  mkdir --parents "$ICON_BASE_PATH"
  # Copy icon from the default destination to where it should actually be
  cp "$ICON_UPLOAD" $ICON_BASE_PATH
  # A .desktop file apparently expects an icon without an extension
  ICON_NAME="$(basename "$ICON_UPLOAD" | sed -e 's/.png|.svg//')"

  update-icon-caches $ICON_BASE_PATH
fi

cat << EOF > $FILE_PATH
  [Desktop Entry]
  Version=1.0
  Type=Application
  Name=$NAME
  Comment=Logud
  Icon=$ICON_BASE_PATH$ICON_NAME
  Exec=gnome-session-quit --logout $TO_PROMPT_OR_NOT
EOF
