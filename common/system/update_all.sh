#!/usr/bin/env bash

# SYNOPSIS
#    update_all.sh
#
# DESCRIPTION
#    This script updates all apt repositories and then applies all available
#    upgrades, picking default values for all debconf questions. It takes no
#    parameters.
#
# IMPLEMENTATION
#    version         update_all.sh (magenta.dk) 1.0.0
#    author          Alexander Faithfull
#    copyright       Copyright 2019, Magenta ApS
#    license         GNU General Public License
#    email           af@magenta.dk

set -e

# Fix dpkg settings to avoid interactivity.
cat <<- EOF > /etc/apt/apt.conf.d/local
	Dpkg::Options {
	   "--force-confdef";
	   "--force-confold";
	}
EOF

# Stop Debconf from doing anything
export DEBIAN_FRONTEND=noninteractive

# Update apt packages
# Snap packages are updated automatically by default in Ubuntu
apt-get update > /dev/null
apt-get --assume-yes --fix-broken --fix-missing install # Attempt to fix broken or interrupted installations, and add missing packages
apt-get --assume-yes upgrade
apt-get --assume-yes dist-upgrade
apt-get --assume-yes autoremove
apt-get --assume-yes clean
