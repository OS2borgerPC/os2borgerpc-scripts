#! /usr/bin/env sh

# One-off synchronize time with htpdate.
# Used on instances where NTP ports or NTP synchronization in general are blocked.
# If possible, we recommend opening up in the firewall for NTP instead.

# This script may cause jobmanager to time out due to changes in the time settings

set -ex

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install --assume-yes htpdate

# Ensure that the htpdate service is disabled in case the script times out before htpdate is removed
systemctl disable --now htpdate

echo "time before updating"
date
htpdate -s www.pool.ntp.org dk.pool.ntp.org www.wikipedia.org
echo "time after updating"
date

# htpdate only updates the system clock so update the hardware clock from the system clock
hwclock --systohc

# Enabling this service as previous versions of the script disabled it
# because it was under suspicion for interfering and syncing the time back to be incorrect
# (if NTP is blocked by the firewall)
systemctl enable --now systemd-timesyncd

# Clean up and remove htpdate, as otherwise it leaves a service running which continually syncs time
# via htpdate
apt-get remove --assume-yes htpdate
