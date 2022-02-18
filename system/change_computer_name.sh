#! /usr/bin/env sh

# This script will change the name of the computer, it will not
# change how it looks in the admin. There is no validation that this parameter is a valid name.
# Requirements for a valid hostname: https://www.man7.org/linux/man-pages/man7/hostname.7.html

set -e

NEW_COMPUTER_NAME=$1

PREFS_FILE=/etc/hosts
OLD_COMPUTER_NAME=$(hostname)

if [ $# -ne 1 ]; then
    printf '%s\n' "This script needs exactly one argument: The new name of the computer."
    exit 1
fi

# Update the name in /etc/hostname
hostnamectl set-hostname "$NEW_COMPUTER_NAME"

# Also update the name in /etc/hosts
sed -i "s/$OLD_COMPUTER_NAME/$NEW_COMPUTER_NAME/g" $PREFS_FILE

# Also update the name in the computer's Configuration in OS2borgerPC locally
set_os2borgerpc_config hostname "$NEW_COMPUTER_NAME"
# ...and push that change to the adminsite, so it isn't overwritten locally when jobmanager runs
os2borgerpc_push_config_keys hostname

printf '%s\n' "Rename done!"
printf '%s\n' "Now manually update the PC's name in the admin interface and it will have been renamed everywhere."
