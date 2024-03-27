#! /usr/bin/env sh
# 
# Takes to params: IP address and password
# 
# To access the share interface, run:
# smbclient '//<IP_ADDRESS_HERE>/<SHARE_NAME>' -U <USER>%<PASSWORD>
# ...so more specifically: 
# smbclient '//<IP_ADDRESS_HERE>/scan' -U samba%<PASSWORD>

# Connect to the server and exit again
if smbclient //"$1"/scan -U samba%"$2" -c exit; then
    echo "Connection successful"
    exit 0
else
    echo "Connection failed"
    exit 1
fi
