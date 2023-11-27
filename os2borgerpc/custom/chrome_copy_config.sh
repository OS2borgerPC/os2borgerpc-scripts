#!/usr/bin/env sh

# A customer found out Chrome started incredibly slowly. Copying a basic, new profile fixed the issue.

set -ex

DIR=/home/.skjult/.config

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"

if [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] && \
   [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then
  mkdir --parents $DIR
  cd $DIR
  FILE="config-google-chrome_jE4lXgx.zip"
  wget https://os2borgerpc-media.magenta.dk/script_uploads/$FILE
  unzip $FILE
  rm $FILE
else
  rm -r $DIR/google-chrome
fi
