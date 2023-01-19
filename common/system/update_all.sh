#!/usr/bin/env bash

# SYNOPSIS
#    update_all.sh
#
# DESCRIPTION
#    This script updates all apt repositories and then applies all available
#    upgrades, picking default values for all debconf questions. It takes no
#    parameters.
#    Snap packages are already updated automatically by default in Ubuntu.
#
# IMPLEMENTATION
#    copyright       Copyright 2022, Magenta ApS
#    license         GNU General Public License

set -ex

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
apt-get update > /dev/null # Resync the local package index from its remote counterpart
dpkg --configure -a # Configure any packages which have been unpacked but not configured, as otherwise --fix-broken might fail
apt-get --assume-yes --fix-broken install # Attempt to fix broken or interrupted installations
apt-get --assume-yes dist-upgrade # Upgrade all packages, and if needed remove packages preventing an upgrade
apt-get --assume-yes autoremove # Remove packages only installed as dependencies which are no longer dependencies
apt-get --assume-yes clean # Remove local repository of retrieved package files
