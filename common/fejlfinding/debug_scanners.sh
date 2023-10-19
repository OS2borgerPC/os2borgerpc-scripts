#! /usr/bin/env sh

set -x

text() {
  MSG=$1
  printf "\n%s\n" "### $MSG ###"
}

text "Information about usb-devices"
lsusb

text "Information about /dev/bus/usb"
ls -l /dev/bus/usb/*/*

text "Information about scan-related bin-files"
# shellcheck disable=SC2010   # it's just a debugging script and that dir won't have non-alphanumeric names
ls -l /usr/bin | grep scan

text "Information about group membership"
cat /etc/group

text "Check if there are any firmware files in /usr/share/sane and, if so, if their permissions are correct"
ls -lR /usr/share/sane

text "Check if scanimage -L and sane-find-scanner get permission errors when run as the regular user, as otherwise it may prevent the user from scanning"
timeout 13 su --login user --command "scanimage -L"
timeout 13 su --login user --command "sane-find-scanner"

text "Run sane-find-scanner as root, just to get the information, in case the above fails"
sane-find-scanner

text "Check if any udev rules are likely to match the scanner. If not we may need to create a custom udev rule for the vendor and product, to ensure everyone has read access"
# https://wiki.archlinux.org/title/SANE#Permission_problem
cat /usr/lib/udev/rules.d/60-libsane.rules
cat /usr/lib/udev/rules.d/99-libsane.rules
