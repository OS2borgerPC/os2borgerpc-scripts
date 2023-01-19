#! /usr/bin/env sh

set -ex

# Set the locale and timezone
#echo "Europe/Copenhagen" > /etc/timezone
timedatectl set-timezone Europe/Copenhagen
dpkg-reconfigure -f noninteractive tzdata
sed -i 's/# \(da_DK.UTF-8 UTF-8\)/\1/'  /etc/locale.gen
dpkg-reconfigure --frontend=noninteractive locales
update-locale LANG=da_DK.UTF-8


# Update the time accordingly
DEBIAN_FRONTEND=noninteractive apt-get install -y ntpdate
ntpdate pool.ntp.org
