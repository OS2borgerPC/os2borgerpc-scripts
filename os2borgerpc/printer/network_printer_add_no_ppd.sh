#! /usr/bin/env sh

set -ex

# lpadmin doesn't like spaces
NAME="$(echo "$1" | tr ' ' '_')"
HOST="$2"
DESCRIPTION="$3"
PROTOCOL="${4:-ipp}"
SET_STANDARD="$5"

[ "$PROTOCOL" = "ipp" ] && ENABLE_IPP_EVERYWHERE="-m everywhere"

# shellcheck disable=SC2086  # We want word-splitting in the last argument
lpadmin -p "$NAME" -v "$PROTOCOL://$HOST" -D "$DESCRIPTION" -L "$DESCRIPTION" -E $ENABLE_IPP_EVERYWHERE

if [ "$SET_STANDARD" = "True" ]; then
  # Set the printer as standard printer
  lpadmin -d "$NAME" && lpstat -d
fi
