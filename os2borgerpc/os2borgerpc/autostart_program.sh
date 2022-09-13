#!/bin/bash

# DESCRIPTION 
# This script either copies a given installed .desktop file to the autostart directory
# or removes a given file from the autostart directory. 
#
# To check which scripts are installed on a machine run the script 
# "desktop_print_program_list.sh" AKA "Desktop - Vis programliste" with paremeter 
# "mulige" to print a full list of eligible files to add to autostart.
#
# PARAMENTERS
# 1. String. The given file's name, either with no extension or with .desktop
#            eg. "firefox" or "firefox.desktop". This parameter IS case-sensitive
#            as some applications have capitalized characters in their filename.
# 2. Checkbox. Check this box to delete a file from the autostart folder instead.

SELECTED=$1
DELETE=$2

if [[ $SELECTED != *.desktop ]]; then
    SELECTED="$SELECTED.desktop"
fi

AUTOSTART_DIR="/home/.skjult/.config/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/$SELECTED"
INSTALLED_APP_FILE="/usr/share/applications/$SELECTED"

if [ "$DELETE" = "True" ]; then 
    echo "Removing $SELECTED from autostart directory"
    
    rm "$AUTOSTART_FILE"

    exit "$?"    
fi

mkdir -p $AUTOSTART_DIR

echo "Adding $SELECTED to autostart directory"

cp "$INSTALLED_APP_FILE" "$AUTOSTART_FILE"

exit "$?"
