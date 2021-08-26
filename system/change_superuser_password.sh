#!/usr/bin/env sh 

# This script will change the superuser password on a OS2borgerPC machine.
#
# Expect exactly two input parameters

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
    CRYPTPASS=$(perl -e 'print crypt($ARGV[0], "password")' "$PASSWORD")
    # Done calculating, now do it.
    /usr/sbin/usermod "$TARGET_USER" -p "$CRYPTPASS"
else
    printf '%s\n' "Passwords didn't match!"
    exit 1
fi

exit 0
