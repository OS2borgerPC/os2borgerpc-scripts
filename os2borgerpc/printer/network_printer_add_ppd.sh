#! /usr/bin/env sh

set -ex

# lpadmin doesn't like spaces
NAME="$(echo "$1" | tr ' ' '_')"
HOST="$2"
DESCRIPTION="$3"
DRIVER="$4"
PROTOCOL="${5:-socket}"
SET_STANDARD="$6"

lpadmin -p "$NAME" -v "$PROTOCOL://$HOST" -D "$DESCRIPTION" -E -P "$DRIVER" -L "$DESCRIPTION"

if [ "$SET_STANDARD" = "True" ]; then
  # Set the printer as standard printer
  lpadmin -d "$NAME" && lpstat -d
fi
