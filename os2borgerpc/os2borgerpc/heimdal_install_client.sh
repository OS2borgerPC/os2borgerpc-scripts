#! /usr/bin/env sh

# This script is essentially just a wrapper for the official heimdal installation script found here:
# https://support.heimdalsecurity.com/hc/en-us/articles/4433189823773-Installing-the-HEIMDAL-Agent-Ubuntu-Debian-

ACTIVATE="$1"
LICENSE_KEY="$2"

export DEBIAN_FRONTEND=noninteractive
HEIMDAL_SCRIPT_NAME="install-heimdal.sh"
HEIMDAL_INSTALL_SCRIPT_URL="https://prodcdn.heimdalsecurity.com/setup-linux/$HEIMDAL_SCRIPT_NAME"

set -x

if [ "$ACTIVATE" = "True" ]; then
    wget "$HEIMDAL_INSTALL_SCRIPT_URL"
    sh $HEIMDAL_SCRIPT_NAME -l "$LICENSE_KEY"

    # Fetching the heimdal keyring as their installer script currently doesn't do this, and then overwriting their apt sources list for heimdal to point to that keyring
    # This is taken from the "manual" section of their installation guide
    curl https://linuxrepo.heimdalsecurity.com/pgp-key.public | gpg --yes --dearmor -o /usr/share/keyrings/heimdal-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/heimdal-keyring.gpg] https://linuxrepo.heimdalsecurity.com/apt-repo stable main" > /etc/apt/sources.list.d/heimdal.list

    echo "After installation: Checking if the Heimdal client is now running:"
    systemctl status heimdal-clienthost

    echo "Cleaning up afterwards"
    rm $HEIMDAL_SCRIPT_NAME
else
    echo "Attempting to remove Heimdal"
    apt-get purge heimdal --assume-yes
    # It seems the service isn't uninstalled by the above, so disable and stop it
    systemctl disable --now heimdal-clienthost
    rm /usr/share/keyrings/heimdal-keyring.gpg /etc/apt/sources.list.d/heimdal.list
fi
