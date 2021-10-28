#! /usr/bin/env sh

# Create a persistent directory in the user's home directory
# Logout or restart to take effect
#
# Arguments
#   1: Whether to add or remove the shared dir
#      'yes' adds, 'no' removes
#   2: The name of the shared dir to add or remove
#
# Author: mfm@magenta.dk
# Credits: carstena@magenta.dk

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"
NAME="$2"

DIR=/var/local/$NAME
USERNAME=user
SHADOW=.skjult

if [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] && \
   [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then

  mkdir --parents "$DIR"
  chown $USERNAME:$USERNAME "$DIR"
  ln --symbolic "$DIR" "/home/$SHADOW/Skrivebord/$NAME"

else # Delete the persistent dir with the specified NAME

  rm --recursive "$DIR"
  rm "/home/$SHADOW/Skrivebord/$NAME"
fi
