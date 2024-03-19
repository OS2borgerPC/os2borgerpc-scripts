#!/usr/bin/env sh
# 
# This script will change the audience user password on a OS2borgerPC machine.
#
# Expects exactly two input parameters

set -e

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

if [ $# -ne 2 ]
then
    printf '%s\n' "usage: $(basename "$0") <password> <confirmation>"
    exit 1
fi

if [ "$1" = "$2" ]; then

    # whois package contains mkpasswd
    if ! dpkg -l | grep --quiet whois; then
        apt-get update
        apt-get install --assume-yes whois
    fi

    # change password
    TARGET_USER=user

    # If the password is encrypted, it will just pass through the checks for chpasswd
    ENCRYPTED_CODE=$(echo "$1" | mkpasswd --method=Yescrypt --stdin)
    
    # The chpasswd always return exit code 0, even when it fails.
    # We therefore need to check if there is a text, only failure to change the password generates text.
    # The -e flag is used for pre-encrypted passwords
    output=$(echo "$TARGET_USER:$ENCRYPTED_CODE" | /usr/sbin/chpasswd --encrypted 2>&1)

    if [ -n "$output" ]; then
        echo "Failed to change password. Error message: $output"
        exit 1
    fi
else
    printf '%s\n' "Passwords didn't match!"
    exit 1
fi
