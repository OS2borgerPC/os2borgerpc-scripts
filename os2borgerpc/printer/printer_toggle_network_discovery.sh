#! /usr/bin/env sh

set -ex

# Enable / Disable network printer discovery.
# "til" enables network printer discovery, "fra" disables it.
# As a side effect all network printers previously found are removed 
# and any you want, have to be added manually.
# Log out or restart if changes don't take immediate effect.
#
# Attempted solutions that proved insufficient:
# 1. Disable fx. BrowseProtocols in /etc/cups/cupsd.conf AND
# /etc/cups/cups-browsed.conf
# 2. Completely disable cups-browsed: systemctl mask cups-browsed
#
# Author: mfm@magenta.dk

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"

if [ "$ACTIVATE" != 'fra' ] && [ "$ACTIVATE" != 'off' ]; then
  # Enable network printer discovery
  systemctl unmask avahi-daemon cups-browsed
  systemctl start avahi-daemon cups-browsed

else # Disable network printer discovery
  systemctl mask avahi-daemon cups-browsed
  # Mask vs. disable: https://askubuntu.com/a/816378/284161
  systemctl stop avahi-daemon cups-browsed
fi
