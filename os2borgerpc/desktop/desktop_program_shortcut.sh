#! /usr/bin/env sh

# Adds/Removes programs from the desktop in Ubuntu 20.04
# Author: mfm@magenta.dk
#
# Note that the program assumes danish locale, where the 'Desktop' directory
# is instead named 'Skrivebord'.
#
# Arguments:
# 1: Use a boolean to decide whether to add or remove the program shortcut
# 2: This argument should specify the name of a program (.desktop-file)
# under /usr/share/applications/

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE=$1
PROGRAM="$(lower "$2")"

SHADOW=.skjult

if [ "$ACTIVATE" = 'True' ]; then
  mkdir --parents /home/$SHADOW/Skrivebord
  cp "/usr/share/applications/$PROGRAM.desktop" /home/$SHADOW/Skrivebord/
else
  echo "Forsøger at slette programmet $PROGRAM"
  rm "/home/$SHADOW/Skrivebord/$PROGRAM.desktop"
fi
