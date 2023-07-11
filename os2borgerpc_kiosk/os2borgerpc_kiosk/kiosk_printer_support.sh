#! /usr/bin/env sh

# Stop Debconf from interrupting when interacting with the package system
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get --assume-yes install cups
