#! /usr/bin/env sh

# Adds, or Removes TeamViewer

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"
FILE="$(lower "$2")"

if [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] &&
  [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then
  echo "##### Attempting to install TeamViewer #####"
  apt-get update -y
  apt-get install -f "$FILE" -y
else
  echo "##### Removing TeamViewer #####"
  apt-get purge teamviewer -y
fi

rm "$FILE"
apt autoremove -y
