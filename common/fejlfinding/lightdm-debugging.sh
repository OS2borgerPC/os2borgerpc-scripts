#! /usr/bin/env sh

set -x

header() {
  MSG=$1
  printf "\n\n\n%s\n\n\n" "### $MSG ###"
}

text() {
  MSG=$1
  printf "\n%s\n" "### $MSG ###"
}

header "ASSORTED DEBUGGING INFORMATION RELATED TO LIGHTDM:"

text "To eliminate it as a cause: Check if the HDD is full"
df -h

text "The installed version of lightdm"
lightdm --version


header "LOG FILES"

text "The log files available in the lightdm log dir"
ls -l /var/log/lightdm

header "LOG OUTPUT FROM LIGHTDM ITSELF"
text "lightdm.log:"
tail --lines 200 /var/log/lightdm/lightdm.log
text "seat0-greeter.log:"
tail --lines 200 /var/log/lightdm/seat0-greeter.log
text "x-0.log:"
tail --lines 200 /var/log/lightdm/x-0.log

header "LOG OUTPUT FROM XORG"
tail --lines 500 /var/log/Xorg.0.log


header "LIGHTDM MAIN CONFIG FILE CONTAINS THE FOLLOWING"
cat /etc/lightdm/lightdm.conf

header "SEE CONTENTS OF FILES UNDER LIGHTDM.CONF.D, IN CASE THERE ARE ANY"
cat /etc/lightdm/lightdm.conf.d/*


header "CHECK FOR THE EXISTENCE OF SOME OF LIGHTDM'S FILES, FX. TO VERIFY PERMISSIONS"
# shellcheck disable=SC2010
ls -l /var/lib/ | grep lightdm
# Exclude repetitive current dir and parent dirs from ls listing though
# shellcheck disable=SC2010
ls -laR /var/lib/lightdm* | grep -v " \."


header "CHECK IF USER (BORGER) IS EXPIRED OR NOT"
chage -l user
