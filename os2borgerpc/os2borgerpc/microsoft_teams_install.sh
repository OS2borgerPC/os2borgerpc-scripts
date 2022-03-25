#! /usr/bin/env sh

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"
FILE="$(lower "$2")"

if [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] &&
  [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then
  echo "##### Attempting to install Microsoft Teams #####"
  apt-get update -y
  apt-get install -f "$FILE" -y
else
  echo "##### Removing Microsoft Teams #####"
  apt-get purge teams -y
fi

rm "$FILE"
apt autoremove -y
