#! /usr/bin/env sh

# This script is based off their own install guide
# https://prod-edam.honeywell.com/content/dam/honeywell-edam/sps/ppr/en-us/public/products/printers/common/documents/sps-ppr-prt-cups-en-ab.pdf?download=false
# Their page about the printer: https://sps.honeywell.com/us/en/products/productivity/printers/desktop/pc43d-desktop-direct-thermal-barcode-printer
# The driver is downloaded here, and it requires an account. The download itself is performed by their dedicated Windows program.
# https://hsmftp.honeywell.com/

# NOTE: Their install script automatically adds the printer as a USB device, with the following name:
# HLL8260CDW

INSTALL="$1"
HONEYWELL_CUPS_DRIVER_PACKAGE_PATH="$2"   # A tar.gz obtained from Honeywell

export DEBIAN_FRONTEND=noninteractive
# This list of dependencies for Ubuntu are taken from their own documentation - the Honeywell CUPS Printing Application Brief
# Many of these should already be installed, though
DEPENDENCIES="cups automake autoconf gcc ghostscript poppler-utils netpbm"

# We make an explicit dir for the unpacked files so we are able to CD there later to run "make uninstall" if needed
INSTALL_DIR="/usr/share/os2borgerpc/lib/honeywell_intermec_pc43d"

set -ex

if [ "$INSTALL" = "True" ] ; then
  [ -z "$HONEYWELL_CUPS_DRIVER_PACKAGE_PATH" ] && echo "When installing, this script requires adding a CUPS driver as the second argument. Exiting" && exit 1
  HONEYWELL_CUPS_DRIVER_PACKAGE_FILE_NAME=$(basename "$HONEYWELL_CUPS_DRIVER_PACKAGE_PATH")

  echo "Installing dependencies:"
  # shellcheck disable=SC2086  # We want word-splitting
  apt-get install --assume-yes $DEPENDENCIES
  # Idempotency/Cleanup: Delete the install dir first in case there are old versions of their CUPS driver lying around
  rm --recursive --force $INSTALL_DIR
  mkdir --parents $INSTALL_DIR
  mv "$HONEYWELL_CUPS_DRIVER_PACKAGE_PATH" $INSTALL_DIR/
  cd $INSTALL_DIR
  tar -xzvf "$HONEYWELL_CUPS_DRIVER_PACKAGE_FILE_NAME"
  #rm "$HONEYWELL_CUPS_DRIVER_PACKAGE_FILE_NAME"
  # The file currently contains a single directory. cd into that.
  cd "$(tar -tf "$HONEYWELL_CUPS_DRIVER_PACKAGE_FILE_NAME" | head --lines 1)"
  echo "Running Honeywell's install script:"
  # NOTE: Their script doesn't add the printer, but strangely DOES modify whichever is the first added printer it finds.
  # Specifically it runs the following commands, setting these options:
  # lpadmin -p $PRINTER -o usb-no-reattach-default=true
  # lpadmin -p $PRINTER -o usb-unidir-default=true
  ./build.sh

  # Once connected the printer is added automatically under the following name:
  # PC43d-203-FP

  # If successful the drivers should now be available at: /usr/share/cups/model/intermec
  # Specifically these files are available for 43d:
  # intermec-dp-pc43d-203.ppd
  # intermec-dp-pc43d-300.ppd
  # The numbers in question are supposed to specify DPI, though looking at their contents it looks like they may both be 203 DPI?
else
  cd $INSTALL_DIR
  # Hopefully there's only one dir in there. We don't assume the name in case they decide to change it.
  cd "$(ls --directory ./*/)"
  echo "Running Honeywell's uninstall script:"
  make uninstall
  # Leaving the directory in case the uninstall fails somehow
  # If wanting to delete the printer itself:
  #lpadmin -x "PC43d-203-FP"
  # NOTE: Leaving the dependencies installed in case other scripts may install/need them
fi
