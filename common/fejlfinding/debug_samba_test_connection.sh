#! /usr/bin/env sh
#
# Takes to params: IP address and password
#
# To access the share interface, run:
# smbclient '//<IP_ADDRESS_HERE>/<SHARE_NAME>' -U <USER>%<PASSWORD>
# ...so more specifically:
# smbclient '//<IP_ADDRESS_HERE>/scan' -U samba%<PASSWORD>

export DEBIAN_FRONTEND=noninteractive
PKG="smbclient"
USER_NAME="samba"
SHARE_NAME="scan"

# Quiet output from apt so it doesn't massively populate the script log
apt-get update -qq
apt-get install --assume-yes -qq $PKG

# Connect to the server and exit again
if smbclient //"$1"/$SHARE_NAME -U $USER_NAME%"$2" -c exit; then
    SUCCESS=1
    echo "Connection successful"
else
    echo "Connection failed"
fi

# smbclient is just used for testing. Delete it again.
apt-get remove --assume-yes -qq $PKG

if [ -z "$SUCCESS" ]; then
    exit 1
fi
