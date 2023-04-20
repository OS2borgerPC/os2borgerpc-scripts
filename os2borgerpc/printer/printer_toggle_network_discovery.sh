#! /usr/bin/env sh

set -ex

# Enable / Disable network printer discovery.
# Use a boolean to enable or disable. A checked box will disable
# network printer discovery and an unchecked one will enable it.
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

ACTIVATE=$1

POLKIT_POLICY="/etc/polkit-1/localauthority/10-vendor.d/01-os2borgerpc-deny-user-managing-units.pkla"

if [ "$ACTIVATE" = "True" ]; then
  # Disable network printer discovery
  systemctl mask avahi-daemon cups-browsed
  # Mask vs. disable: https://askubuntu.com/a/816378/284161
  systemctl stop avahi-daemon cups-browsed

  cat <<- EOF > $POLKIT_POLICY
		[User shan't manage units, to prevent simple-scan/saned from prompting for password trying to start avahi-daemon]
		Identity=unix-user:user
		Action=org.freedesktop.systemd1.manage-units
		ResultAny=no
		ResultInactive=no
		ResultActive=no
	EOF

else # Enable network printer discovery
  systemctl unmask avahi-daemon cups-browsed
  systemctl start avahi-daemon cups-browsed

  rm --force $POLKIT_POLICY
fi
