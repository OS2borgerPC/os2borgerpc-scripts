#!/usr/bin/env sh

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"

export DEBIAN_FRONTEND=noninteractive
FILE="/home/chrome/.xinitrc"
PROGRAM="unclutter-xfixes"

apt-get update --assume-yes

if [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] && \
   [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then

  apt-get install --assume-yes $PROGRAM

  if ! grep --quiet -- "$PROGRAM" "$FILE"; then
    # 3 i means: Insert on line 3
    sed --in-place "3 i $PROGRAM &" $FILE
  fi
else
  sed -i "/$PROGRAM/d" $FILE
  apt-get --assume-yes remove $PROGRAM
fi
