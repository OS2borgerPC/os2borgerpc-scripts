#! /usr/bin/env sh

# Synchronize time with htpdate.
# Used on instances where NTP ports or NTP synchronization in general are blocked.

set -ex

apt-get update
apt-get install --assume-yes htpdate

echo "time before updating"
date
htpdate -s www.pool.ntp.org dk.pool.ntp.org www.wikipedia.org
echo "time after updating"
date

# Clean up and remove htpdate, as otherwise it leaves a service running which continually syncs time
# via htpdate
apt-get remove --assume-yes htpdate