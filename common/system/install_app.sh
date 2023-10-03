#!/usr/bin/env bash

set -x

INSTALL=$1
APPNAME=$2

# Stop Debconf from doing anything
export DEBIAN_FRONTEND=noninteractive

# Resync the local package index from its remote counterpart
apt-get --assume-yes update
# Attempt to fix broken or interrupted installations
apt-get --assume-yes --fix-broken install

# Install or remove the chosen package
if [ "$INSTALL" = "True" ]; then
  apt-get --assume-yes install "$APPNAME"
else
  apt-get --assume-yes remove "$APPNAME"
fi

# Remove packages only installed as dependencies, which are no longer dependencies
apt-get --assume-yes autoremove
# Remove local repository of retrieved package files
apt-get --assume-yes clean
