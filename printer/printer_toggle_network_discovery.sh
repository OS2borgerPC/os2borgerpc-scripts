#! /usr/bin/env sh

set -ex

# Enable / Disable network printer discovery.
# "til" enables network printer discovery, "fra" disables it.
# As a side effect all network printers previously found are removed 
# and any you want, have to be added manually.
# Log out or restart if changes don't take immediate effect.

# Author: mfm@magenta.dk

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"

CUPS_CONFIG=/etc/cups/cups-browsed.conf

if [ "$ACTIVATE" != 'fra' ] && [ "$ACTIVATE" != 'off' ]; then
  # Enable network printer discovery
  systemctl unmask avahi-daemon cups-browsed
  systemctl start avahi-daemon cups-browsed

  #sed -i 's,BrowseProtocols none,# BrowseProtocols none,' $CUPS_CONFIG

  # Alternate approach add these too
  #sed -i 's,BrowseLocalProtocols none,# BrowseLocalProtocols none,' $CUPS_CONFIG
  #sed -i 's,BrowseRemoteProtocols none,BrowseRemoteProtocols dnssd cups,' $CUPS_CONFIG

else # Disable network printer discovery
  systemctl mask avahi-daemon cups-browsed
  # Mask vs. disable: https://askubuntu.com/a/816378/284161
  systemctl stop avahi-daemon cups-browsed

  # Temporarily here to reset this setting to default from previous versions of
  # this script, since it isn't needed anymore
  #sed -i 's,BrowseProtocols none,# BrowseProtocols none,' $CUPS_CONFIG

  #sed -i 's,# BrowseProtocols none,BrowseProtocols none,' $CUPS_CONFIG
  # Alternate approach add these too
  #sed -i 's,# BrowseLocalProtocols none,BrowseLocalProtocols none,' $CUPS_CONFIG
  #sed -i 's,BrowseRemoteProtocols dnssd cups,BrowseRemoteProtocols none,' $CUPS_CONFIG
fi

# Restarting cups to reduce the chances of needing the restart:
#systemctl reload-or-restart cups-browsed cups avahi-daemon
