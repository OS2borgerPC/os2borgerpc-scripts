#!/usr/bin/env sh

# This script will change the superuser password on a OS2borgerPC machine.
#
# Expects exactly two input parameters

if [ $# -ne 2 ]
then
    printf '%s\n' "usage: $(basename "$0") <password> <confirmation>"
    exit 1
fi

if [ "$1" = "$2" ]
then
    # change password
    TARGET_USER=superuser
    PASSWORD="$1"
    echo "$TARGET_USER:$PASSWORD" | /usr/sbin/chpasswd
else
    printf '%s\n' "Passwords didn't match!"
    exit 1
fi

exit 0
