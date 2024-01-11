#! /usr/bin/env sh

# http://deb.anydesk.com/howto.html

INSTALL="$1"

export DEBIAN_FRONTEND=noninteractive
ANYDESK_APT_SOURCE="/etc/apt/sources.list.d/anydesk-stable.list"

if [ "$INSTALL" = "True" ]; then

    wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | apt-key add -
    echo "deb http://deb.anydesk.com/ all main" > $ANYDESK_APT_SOURCE

    apt-get update
    apt-get install --assume-yes anydesk
else
    # Note: Not currently removing the signing key
    apt-get remove --assume-yes anydesk
    rm $ANYDESK_APT_SOURCE
fi
