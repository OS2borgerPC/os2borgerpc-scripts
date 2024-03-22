#! /usr/bin/env sh

set -x

PRINTER_NAME="PC43d-203-FP"
PAPER_SIZE_MM="63x114"
ORIENTATION=5 # = 270 degrees rotated: reverse landscape

CUPS_PRINTER_CONF="/etc/cups/printers.conf"

echo "Set the two settings that their build scripts tries to set for the printer"
lpadmin -p $PRINTER_NAME -o usb-no-reattach-default=true
lpadmin -p $PRINTER_NAME -o usb-unidir-default=true

echo "Set paper size to 63x114, Media Type to \"Mark\""
# black marks are used by thermal printers, helping the printer determine the beginning and end of the ticket
# ...according to https://superuser.com/questions/768262/thermal-printer-black-mark-sensor , anyway.
lpoptions -o PageSize="Custom.${PAPER_SIZE_MM}mm" -o inMediaType="mark"

echo "Set orientation to 270 degrees rotated (AKA reverse landscape)"
# See available orientations here: https://www.cups.org/doc/options.html#ORIENTATION:%7E:text=Setting%20the%20Orientation
# printers.conf says not to edit it while cups is running, so stop cups
systemctl stop cups
# Also tried these, which I'd prefer over using "sed" on the config file, but they seemed to have no effect?
#lpadmin -p $PRINTER_NAME -o orientation-requested=$ORIENTATION
#lpoptions -p $PRINTER_NAME -o orientation-requested=$ORIENTATION
sed --in-place "s/orientation-requested [0-9]/orientation-requested $ORIENTATION/" $CUPS_PRINTER_CONF

# Now start cups again to make the above config file change take effect
systemctl start cups

printf "\n\n\n"

echo "Finally list all the settings after the changes, for verification that the changes succeeded"
lpoptions -p $PRINTER_NAME -l
echo "Contents of $CUPS_PRINTER_CONF:"
cat $CUPS_PRINTER_CONF
