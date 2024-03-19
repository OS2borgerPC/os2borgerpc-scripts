#!/usr/bin/env sh
# 
# This script will change the superuser password on a OS2borgerPC machine.
#
# Expects exactly two input parameters

set -e

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
    
    # The chpasswd always return exit code 0, even when it fails.
    # We therefore need to check if there is a text, only failure to change the password generates text.
    output=$(echo "$TARGET_USER:$PASSWORD" | /usr/sbin/chpasswd 2>&1)

    if [ -n "$output" ]; then
        echo "Failed to change password. Error message: $output"
        exit 1
    fi
else
    printf '%s\n' "Passwords didn't match!"
    exit 1
fi
