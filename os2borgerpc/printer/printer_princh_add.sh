#! /usr/bin/env sh

set -ex

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi
# lpadmin doesn't like spaces
NAME="$(echo "$1" | tr ' ' '_')"
PRINCH_ID="$2"
DESCRIPTION="$3"
SET_STANDARD="$4"

# Delete the printer if a printer already exists by that NAME
lpadmin -x "$NAME" || true

# No princh-cloud-printer binary in path, so checking for princh-setup
if which princh-setup > /dev/null; then
   lpadmin -p "$NAME" -v "princh:$PRINCH_ID" -D "$DESCRIPTION" -E -P /usr/share/ppd/princh/princheu.ppd -L "$DESCRIPTION"
else
   echo "Princh is not installed. Please run the script that installs Princh before this one."
   exit 1
fi

if [ "$SET_STANDARD" = "True" ]; then
  # Set the printer as standard printer
  lpadmin -d "$NAME" && lpstat -d
fi
