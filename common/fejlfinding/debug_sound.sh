#! /usr/bin/env sh

# This scripts prints out various pieces of information to help debug sound issues.
# This script is both compatible with OS2borgerPC and Kiosk, once Pulseaudio has been installed on Kiosk.

MAIN_OS2BORGERPC_PULSEAUDIO_CONFIG="/etc/pulse/default.pa.d/os2borgerpc.pa"
MAIN_PULSEAUDIO_CONFIG="/etc/pulse/default.pa"

text() {
  MSG=$1
  printf "\n%s\n" "### $MSG ###"
}

text "List contents of the main system wide Pulseaudio config dir"
ls -l "$(dirname $MAIN_PULSEAUDIO_CONFIG)"

text "List contents of the Pulseaudio config autoload dir (if it exists)"
ls -l /etc/pulse/default.pa.d/

text "List contents of the main Pulseaudio config"
cat $MAIN_PULSEAUDIO_CONFIG

text "List contents of the OS2borgerPC Pulseaudio config"
cat $MAIN_OS2BORGERPC_PULSEAUDIO_CONFIG

# Some of these files may not exist. Exit successfully regardless.
exit 0
