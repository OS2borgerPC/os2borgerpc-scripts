#!/bin/bash

set -x

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"
LICENCE_KEY=$2 # available in the Heimdal Dashboard.

if [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] &&
   [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then

    apt-get update --assume-yes
    apt-get install --assume-yes ca-certificates curl unzip gnupg lsb-release netcat

    curl https://linuxrepo.heimdalsecurity.com/pgp-key.public \
    | gpg --yes --dearmor -o \
    /usr/share/keyrings/heimdal-keyring.gpg

    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/heimdal-keyring.gpg]'\
    'https://linuxrepo.heimdalsecurity.com/apt-repo stable main' \
    | tee /etc/apt/sources.list.d/heimdal.list

    apt-get update --assume-yes

    echo "$LICENCE_KEY" | apt-get install heimdal --assume-yes

    apt-get autoremove --assume-yes

else

    apt purge heimdal --assume-yes
    rm /usr/share/keyrings/heimdal-keyring.gpg
    rm /etc/apt/sources.list.d/heimdal.list

fi
