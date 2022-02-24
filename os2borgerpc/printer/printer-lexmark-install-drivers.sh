#!/usr/bin/env sh

# Installs Linux Universal Printer Driver for Lexmark printers

# SRC for the file:
# https://www.lexmark.com/en_us/printer/7693/Lexmark-MS610dn#drivers

FILE="Lexmark-UPD-PPD-Files.tar.Z"

wget https://downloads.lexmark.com/downloads/drivers/$FILE

tar xzvf $FILE
chmod u+x ppd_files/install_ppd.sh

ppd_files/install_ppd.sh

rm $FILE
