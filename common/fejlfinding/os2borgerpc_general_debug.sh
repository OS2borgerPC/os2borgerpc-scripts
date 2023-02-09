#! /usr/bin/env sh

# General information script for OS2borgerPC, useful for debugging
# Feel very free to add steps that gather additional, relevant information and commit the changes!

set -x

header() {
  MSG=$1
  printf "\n\n\n%s\n\n\n" "### $MSG ###"
}

text() {
  MSG=$1
  printf "\n%s\n" "### $MSG ###"
}

header "General info:"

text "Print the OS2borgerPC configuration file:"
cat /etc/os2borgerpc/os2borgerpc.conf

text "Print the OS2borgerPC client version:"
pip3 list installed | grep os2borgerpc-client

text "Info on lightdm, the display manager:"
cat /etc/lightdm/lightdm.conf

text "Print info on automatic updates:"
cat /etc/apt/apt.conf.d/90os2borgerpc-automatic-upgrades

text "Print user cleanup file:"
cat /usr/share/os2borgerpc/bin/user-cleanup.bash

text "Check permissions on files in /usr/share/os2borgerpc/bin/"
ls -l /usr/share/os2borgerpc/bin/

text "Print a list of programs/files on the desktop:"
ls -l /home/user/Skrivebord/

text "Verify this matches what's in the user template (after logout):"
ls -l /home/.skjult/Skrivebord/

text "Check the contents of /home/.skjult/"
ls -la /home/.skjult/

text "Check the contents of /home/.skjult/.config/"
ls -la /home/.skjult/.config/

text "Check the contents of /home/.skjult/.local/"
ls -la /home/.skjult/.local/

text "Print the list of programs in the launcher:"
cat /etc/dconf/db/os2borgerpc.d/02-launcher-favorites

text "Print info about the current background image:"
cat /etc/dconf/db/os2borgerpc.d/00-background

text "Check the crontab"
crontab -l
crontab -u user -l

text "Check the inactive logout file"
cat /usr/share/os2borgerpc/bin/inactive_logout.sh

### CHROME / CHROMIUM RELATED INFO ###

header "Print Chrome/Chromium related info"

# Gathers information about Google Chrome on a machine:
# Contents of .desktop files, which versions of Chrome are in path (e.g. snap or not),
# ...and which desktop file the launcher is using.

which google-chrome-stable
which google-chrome
google-chrome --version

text "Check chrome policies"
cat /etc/opt/chrome/policies/managed/os2borgerpc-defaults.json

USER=".skjult"
DESKTOP_FILE_1=/usr/share/applications/google-chrome.desktop
# In case they've also added Chrome to their desktop
DESKTOP_FILE_2=/home/$USER/Skrivebord/google-chrome.desktop
# In case they've run chrome_autostart.sh.
# The name is no mistake, that one is not called google-chrome.desktop
DESKTOP_FILE_3=/home/$USER/.config/autostart/chrome.desktop
DESKTOP_FILE_4=/home/$USER/.local/share/applications/google-chrome.desktop

text "File at $DESKTOP_FILE_1:"
cat "$DESKTOP_FILE_1"
text "File at $DESKTOP_FILE_2:"
cat "$DESKTOP_FILE_2"
text "File at $DESKTOP_FILE_3:"
cat "$DESKTOP_FILE_3"
text "File at $DESKTOP_FILE_4:"
cat "$DESKTOP_FILE_4"

# Launch from TTY
# su --login user --command "export DISPLAY=:0 google-chrome-stable"

# Always exit successfully as some of these files may not exist simply because the related
# scripts haven't been run, so it's not an error
exit 0