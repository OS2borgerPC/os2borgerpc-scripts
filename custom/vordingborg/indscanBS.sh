#! /usr/bin/env sh

set -x

SCAN_DIRECTORY_SOURCE='/home/.skjult/Skrivebord/scan'
SCAN_DIRECTORY_DESTINATION=$(echo $SCAN_DIRECTORY_SOURCE | sed 's/.skjult/user/')
SAMBA_CONFIG=/etc/samba/smb.conf

# Cleanup old config changes since we append below
apt-get purge --assume-yes samba samba-common-bin

apt-get update --assume-yes
apt-get install samba samba-common-bin --assume-yes

mkdir --parents "$SCAN_DIRECTORY_SOURCE"

adduser --no-create-home --disabled-password --disabled-login --gecos smbusr
#smbpasswd -a smbusr
usermod smbusr -p borger1234

sed --in-place '/\[global\]/a\usershare max shares = 100' $SAMBA_CONFIG
sed --in-place '/\[global\]/a\usershare allow guests = yes' $SAMBA_CONFIG
sed --in-place '/\[global\]/a\usershare owner only = false' $SAMBA_CONFIG

cat <<- EOF >> $SAMBA_CONFIG
	[scanning]
	comment = Scannede dokumenter
	path = $SCAN_DIRECTORY_DESTINATION
	browseable = yes
	read only = no
	guest ok = no
EOF
