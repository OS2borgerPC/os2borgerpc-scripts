#! /usr/bin/env sh

BRIEF_INFO=$1

printf "\n\nADDED PRINTERS:\n\n"
lpc status && printf "\n" && lpstat -s

printf "\n\nAVAILABLE PRINTERS:\n\n"
if [ "$BRIEF_INFO" = "False" ]; then
  # Prints more detailed info about printers the computer sees, with info about IP address etc.
  lpinfo -lv
else
  lpinfo -v
fi

exit 0
