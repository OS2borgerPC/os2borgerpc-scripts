#!/usr/bin/env sh

set -x

# Princh says spaces won't work, likely because of CUPS itself, so replace spaces with underscores
printer_name="$(echo "$1" | tr ' ' '_')"
printer_id="$2"
printer_descr="$3"

# Delete the printer if a printer already exists by that name
lpadmin -x "$printer_name"

# No princh-cloud-printer binary in path, so checking for princh-setup
if which princh-setup > /dev/null; then
   lpadmin -p "$printer_name" -v "princh:$printer_id" -D "$printer_descr" -E -P /usr/share/ppd/princh/princheu.ppd
else
   echo "Princh er ikke installeret. Kør scriptet til at installere Princh først."
   exit 1
fi
