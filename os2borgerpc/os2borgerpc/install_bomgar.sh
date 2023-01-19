#! /usr/bin/env sh

# This presupposes, as its first parameter, the Bomgar desktop file.
# Example file name, anonymized in case the last part contains a secret:
# bomgar-scc-zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz.desktop

set -x

BOMGAR_INSTALLER_PATH=$1
BOMGAR_INSTALLER_ORIGINAL_FILENAME=$2
OUR_USER="superuser"

# Bomgar literally won't install if the filename has been changed, so we restore it to that

cd /home/$OUR_USER || exit 1
mv "$BOMGAR_INSTALLER_PATH" "$BOMGAR_INSTALLER_ORIGINAL_FILENAME"

chmod u+x "$BOMGAR_INSTALLER_ORIGINAL_FILENAME"
sh "$BOMGAR_INSTALLER_ORIGINAL_FILENAME"

# Clenup
rm --force "$BOMGAR_INSTALLER_ORIGINAL_FILENAME"
