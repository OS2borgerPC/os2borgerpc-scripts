#! /usr/bin/env sh

header() {
  MSG=$1
  printf "\n\n\n%s\n\n\n" "### $MSG: ###"
}

text() {
  MSG=$1
  printf "\n%s\n" "### $MSG: ###"
}

text "Check the version of hplip"
dpkg -l hplip | cat  # Piping to cat because otherwise it seems to open "less"

text "Info about currently added printers"
lpstat -v

text "Global standard paper size is set to"
# "Paperconf prints  the  name  of the
# the  system-  or  user-specified paper, obtained by looking in order at
# the PAPERSIZE environment variable, at the contents of the file  speci-
# fied by the PAPERCONF environment variable, at the contents of /etc/pa-
# persize or by using letter as a fall-back value if none  of  the  other
# alternatives are successful"
paperconf
# The related command "paperconfig" can set the default paper size.

header "Current printer settings for all added printers"

for printer in $(lpstat -a | cut  --delimiter ' ' --fields 1); do
  text "Printer name: \"$printer\" has these options set:"
  lpoptions -l -p "$printer"
  echo ""
done

header "Print contents of /etc/cups/printers.conf"
cat /etc/cups/printers.conf
