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
if ! grep --quiet "Dpkg::Lock" /etc/apt/apt.conf.d/local; then
  cat <<- EOF > /etc/apt/apt.conf.d/local
	Dpkg::Options {
	   "--force-confdef";
	   "--force-confold";
	};
	Dpkg::Lock {Timeout "300";};
EOF
fi

# Stop Debconf from doing anything
export DEBIAN_FRONTEND=noninteractive

# Update apt packages
apt-get update > /dev/null # Resync the local package index from its remote counterpart
# Configure any packages which have been unpacked but not configured, as otherwise --fix-broken might fail
# However, package configuration can also fail due to dependency issues that would be fixed by --fix-broken
# so if the command fails, try to run --fix-broken
dpkg --configure -a || apt-get --assume-yes --fix-broken install
# Attempt to fix broken or interrupted installations
# If this fails, try to configure any packages which have been unpacked but not configured
apt-get --assume-yes --fix-broken install || dpkg --configure -a
apt-get --assume-yes dist-upgrade # Upgrade all packages, and if needed remove packages preventing an upgrade
apt-get --assume-yes autoremove # Remove packages only installed as dependencies which are no longer dependencies
apt-get --assume-yes clean # Remove local repository of retrieved package files
