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

ADD=$1
PROGRAM="$(lower "$2")"

SHADOW=.skjult

if [ "$ADD" = 'True' ]; then
  mkdir --parents /home/$SHADOW/Skrivebord
  if [ -f "/var/lib/snapd/desktop/applications/${PROGRAM}_$PROGRAM.desktop" ]; then
    cp "/var/lib/snapd/desktop/applications/${PROGRAM}_$PROGRAM.desktop" /home/$SHADOW/Skrivebord/
  else
    cp "/usr/share/applications/$PROGRAM.desktop" /home/$SHADOW/Skrivebord/
  fi
else
  echo "Forsøger at slette programmet $PROGRAM"
  if [ -f "/home/$SHADOW/Skrivebord/${PROGRAM}_$PROGRAM.desktop" ]; then
    rm "/home/$SHADOW/Skrivebord/${PROGRAM}_$PROGRAM.desktop"
  else
    rm "/home/$SHADOW/Skrivebord/$PROGRAM.desktop"
  fi
fi
