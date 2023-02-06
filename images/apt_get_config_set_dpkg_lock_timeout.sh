#! /usr/bin/env bash

# This script is used to add or remove the setting dpkg lock timeout "300" from the apt-get configuration
# It takes a single boolean parameter: whether to add the setting or remove it

ACTIVATE=$1

APT_CONFIG_FILE=/etc/apt/apt.conf.d/local

# Always start by trying to remove the line to prevent duplicate entries
sed --in-place '/Dpkg::Lock/d' $APT_CONFIG_FILE

if [ "$ACTIVATE" = "True" ]; then
  cat << EOF >> $APT_CONFIG_FILE
Dpkg::Lock {Timeout "300";};
EOF
fi