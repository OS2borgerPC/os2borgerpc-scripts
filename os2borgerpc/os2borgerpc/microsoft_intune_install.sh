#! /usr/bin/env sh

# This script is written based off the following guide:
# https://learn.microsoft.com/en-us/mem/intune/user-help/microsoft-intune-app-linux

export DEBIAN_FRONTEND=noninteractive

PKG="intune-portal"

ACTIVATE="$1"

if [ "$ACTIVATE" = "True" ]; then

    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" > /etc/apt/sources.list.d/microsoft-ubuntu-jammy-prod.list
    rm microsoft.gpg
    apt-get update
    apt-get install --assume-yes $PKG
else
    apt-get remove --assume-yes $PKG
    rm /usr/share/keyrings/microsoft.gpg
fi
