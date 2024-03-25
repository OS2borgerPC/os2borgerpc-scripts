#! /usr/bin/env sh

SUMMARY_INFO_ONLY="$1"

printf "\n\nADDED PRINTERS:\n\n"
# NOTE: Removed lpc call as it's deprecated, and its mainly for printing info on the print queue, like lpq, and not for listing printers
lpstat -s && printf "\n"

printf "\n\nAVAILABLE PRINTERS:\n\n"

# Temporarily enable scanning for network devices if it's been disabled (via printer_toggle_network_discovery.sh)
# before checking for available printers
if systemctl --quiet status avahi-daemon | grep --ignore-case --quiet masked; then
  TEMP_ENABLED=True
  systemctl --quiet unmask avahi-daemon cups-browsed
  systemctl --quiet start avahi-daemon cups-browsed
  # Give the services a bit of time to start
  sleep 5
fi

printf "\n- Overview:\n"
lpinfo -v

if [ "$SUMMARY_INFO_ONLY" = "False" ]; then
  printf "\n- Detailed listing:\n"
  # Prints more detailed info about printers the computer sees, potentially with info about IP address etc.
  # Note: lpinfo is potentially deprecated, or at least part of its functionality is
  lpinfo -lv
  # lpstat -le can also list them, but it doesn't list protocols and such
fi

# Other options for scanning for printers:
# avahi-browse -a | grep Printer

# Disable scanning for network devices again, if it was enabled by this script
if [ -n "$TEMP_ENABLED" ]; then
  systemctl --quiet mask avahi-daemon cups-browsed
  systemctl --quiet stop avahi-daemon cups-browsed
fi
