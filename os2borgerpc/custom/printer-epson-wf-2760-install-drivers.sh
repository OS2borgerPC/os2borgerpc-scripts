#!/usr/bin/env bash

# Manuals for the three separate drivers:
# Printer driver: https://download3.ebz.epson.net/dsc/f/03/00/15/47/96/48c7ca288d9541e0fd0e1445e7a13cc605906505/escpr_e.pdf
# Scanner driver: https://download3.ebz.epson.net/dsc/f/03/00/15/47/63/01144a0c8e0b24754bde315b7621a90662107e95/epsonscan2_e.pdf
# Utility driver: https://download3.ebz.epson.net/dsc/f/03/00/15/37/37/3740a2986228a23c80b241ba919fe5595653ab9e/printerutility_e.pdf
#
# The scanner software is called epsonscan2.desktop
set -x

# lpadmin doesn't like spaces
NAME="$(echo "$1" | tr ' ' '_')"
IP_ADDRESS="$2"
PROTOCOL="$3"

FILE1="epson-wf-2760-driver.deb"
FILE2="epson-wf-2760-utilities.deb"
FILE3="epson-wf-2760-scanner.deb.tar.gz"
SCANNER_FOLDER="epson-wf-2760-scanner-driver"
PPD_FILE="/opt/epson-inkjet-printer-escpr/ppds/Epson/Epson-WF-2760_Series-epson-inkjet-printer-escpr.ppd.gz"

# Download the drivers
wget -T 10 -nd --no-cache "https://download.ebz.epson.net/dsc/du/02/DriverDownloadInfo.do?LG2=JA&CN2=US&CTI=176&PRN=Linux%20deb%2064bit%20package&OSC=LX&DL" -O $FILE1

wget -T 10 -nd --no-cache "https://download.ebz.epson.net/dsc/du/02/DriverDownloadInfo.do?LG2=JA&CN2=US&CTI=177&PRN=Linux%20deb%2064bit%20package&OSC=LX&DL" -O $FILE2

wget -T 10 -nd --no-cache "https://download.ebz.epson.net/dsc/du/02/DriverDownloadInfo.do?LG2=JA&CN2=US&CTI=171&PRN=Linux%20deb%2064bit%20package&OSC=LX&DL" -O $FILE3

# Unpack the zipped driver files
tar -xzf $FILE3 --transform "s:^[^/]*:$SCANNER_FOLDER:"

# Install the drivers
dpkg -i --force-all $FILE1
dpkg -i --force-all $FILE2
# The scanner driver folder has a built-in install script. We simply run that
./$SCANNER_FOLDER/install.sh

sleep 20

lpadmin -p "$NAME" -v "$PROTOCOL://$IP_ADDRESS" -P $PPD_FILE -E

# One of the packages/scripts installs the following desktop files, but they are added with nonstandard permissions (too
# permissive), which makes Ubuntu refuse to start them, if they're added to the desktop
chmod 644 /usr/share/applications/epsonscan2.desktop /usr/share/applications/epson-printer-utility.desktop

# Cleanup
rm $FILE1 $FILE2 $FILE3
rm -R $SCANNER_FOLDER
