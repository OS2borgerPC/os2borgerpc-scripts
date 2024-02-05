#!/usr/bin/env bash

set -x

# Scanner software: https://download3.ebz.epson.net/dsc/f/03/00/15/47/63/01144a0c8e0b24754bde315b7621a90662107e95/epsonscan2_e.pdf

FILE1="epsonscan2.deb.tar.gz"

SCANNER_FOLDER="epsonscan2-scanner-software"

# Download the scanner software
wget -T 10 -nd --no-cache "https://download.ebz.epson.net/dsc/du/02/DriverDownloadInfo.do?LG2=JA&CN2=US&CTI=171&PRN=Linux%20deb%2064bit%20package&OSC=LX&DL" -O $FILE1

# Unpack the zipped files
tar -xzf $FILE1 --transform "s:^[^/]*:$SCANNER_FOLDER:"

# The scanner software folder has a built-in install script. We simply run that
./$SCANNER_FOLDER/install.sh

sleep 20

# The built-in install script installs the following desktop file, but it is added with nonstandard permissions (too
# permissive), which makes Ubuntu refuse to start it, if it is added to the desktop
chmod 644 /usr/share/applications/epsonscan2.desktop

# Cleanup
rm $FILE1
rm -R $SCANNER_FOLDER
