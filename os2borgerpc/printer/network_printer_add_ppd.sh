#! /usr/bin/env sh

set -ex

# lpadmin doesn't like spaces
NAME="$(echo "$1" | tr ' ' '_')"
HOST="$2"
DESCRIPTION="$3"
DRIVER="$4"
PROTOCOL="${5:-socket}"

lpadmin -p "$NAME" -v "$PROTOCOL://$HOST" -D "$DESCRIPTION" -E -P "$DRIVER" -L "$DESCRIPTION"
