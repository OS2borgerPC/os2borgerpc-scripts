#! /usr/bin/env sh

set -ex

# lpadmin doesn't like spaces
NAME="$(echo "$1" | tr ' ' '_')"
HOST="$2"
DESCRIPTION="$3"
LOCATION="$4"

CONNECTION="ipp://"

# Execute command with user defined vars
lpadmin -p "$NAME" -v "$CONNECTION$HOST" -D "$DESCRIPTION" -E -m everywhere -L "$LOCATION"
