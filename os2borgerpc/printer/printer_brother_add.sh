#!/usr/bin/env sh

# Installs Linux (deb) Driver + CUPS wrapper for arbitrary Brother printers

# Example URLs to download drivers for Brother printers:
# https://www.brother.dk/support/hl-l5100dn/downloads
# https://www.brother.dk/support/HL-L8260CDW/downloads

set -ex

DRIVER="$1"
CUPS_WRAPPER="$2"
NETWORK_CONNECTED="$3"

# Removes the argument number that we currently add in front of file names
restore_original_filename() {
  basename "$1" | sed "s/[^_]*_//"
}

dpkg --install --force-all "$DRIVER" "$CUPS_WRAPPER"

# The above currently adds a USB printer with the model name. Example: HLL8260CDW
# Deleting that if the user specifies the computer is not connected to it via USB.
if [ "$NETWORK_CONNECTED" = "True" ]; then
	DRIVER_ORIG_NAME=$(restore_original_filename "$DRIVER")
	# Isolating the model name from a string like hll8260cdwlpr-1.5.0-0.i386.deb and uppercasing it
	PRINTER_NAME=$(basename --suffix "lpr" "$(echo "$DRIVER_ORIG_NAME" | cut --delimiter '-' --fields 1)" | tr "[:lower:]" "[:upper:]")
	lpadmin -x "$PRINTER_NAME"
fi

# Cleanup
rm "$DRIVER" "$CUPS_WRAPPER"
