#! /usr/bin/env sh

set -ex

# Some printer guides require you to put printer filter files into a certain dir.
# These files may have the extension .pl or .pm

restore_original_filename() {
  basename "$1" | sed "s/[^_]*_//"
}

FILTER_FILE_1="$1"
FILTER_FILE_2="$2"

# The adminsite currently adds a number in front of file parameters, indicating which positional parameter it was.
# Remove that from the name
FILTER_FILE_1_ORIG_NAME=$(restore_original_filename "$FILTER_FILE_1")
[ -n "$FILTER_FILE_2" ] && FILTER_FILE_2_ORIG_NAME=$(restore_original_filename "$FILTER_FILE_2")

CUPS_FILTER_DIR="/usr/lib/cups/filter"

mv "$FILTER_FILE_1" "$CUPS_FILTER_DIR/$FILTER_FILE_1_ORIG_NAME"
[ -n "$FILTER_FILE_2" ] && mv "$FILTER_FILE_2" "$CUPS_FILTER_DIR/$FILTER_FILE_2_ORIG_NAME"

# Ensure the added filters have the right permissions
chmod 755 "$CUPS_FILTER_DIR/$FILTER_FILE_1_ORIG_NAME"
[ -n "$FILTER_FILE_2" ] && chmod 755 "$CUPS_FILTER_DIR/$FILTER_FILE_2_ORIG_NAME"

# Now restart the CUPS server
systemctl restart cups

echo "For manual verification that the files have been added and have the right permissions:"
ls -l $CUPS_FILTER_DIR
