#!/usr/bin/env sh

# DESCRIPTION
# This script either copies a given installed .desktop file to the autostart directory
# or removes a given file from the autostart directory.
#
# To check which scripts are installed on a machine run the script
# "desktop_print_program_list.sh" AKA "Desktop - Vis programliste" with paremeter
# "mulige" to print a full list of eligible files to add to autostart.
#
# PARAMENTERS
# 1. String. The given file's name, e.g. firefox, without the .desktop extension.
#            This parameter IS case-sensitive as some applications have
#            capitalized characters in their filename.
# 2. Checkbox. Check this box to add the file to the autostart folder.
#              Leave it empty to delete the file from the autostart folder instead.

set -x

PROGRAM="$1"
ADD="$2"

AUTOSTART_DIR="/home/.skjult/.config/autostart"

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

if [ -f "/var/lib/snapd/desktop/applications/${PROGRAM}_$PROGRAM.desktop" ]; then

  INSTALLED_APP_FILE="/var/lib/snapd/desktop/applications/${PROGRAM}_$PROGRAM.desktop"
  AUTOSTART_FILE="$AUTOSTART_DIR/${PROGRAM}_$PROGRAM.desktop"
else
  INSTALLED_APP_FILE="/usr/share/applications/$PROGRAM.desktop"
  AUTOSTART_FILE="$AUTOSTART_DIR/$PROGRAM.desktop"
fi

mkdir --parents $AUTOSTART_DIR

# Remove it first, partially because ln even with --force cannot replace it if it's a regular file
rm --force "$AUTOSTART_FILE"

if [ "$ADD" = "True" ]; then

  echo "Adding $PROGRAM to autostart directory"

  ln --symbolic --force "$INSTALLED_APP_FILE" "$AUTOSTART_FILE"

  exit "$?"
fi
