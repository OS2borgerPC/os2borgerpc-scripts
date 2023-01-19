#!/usr/bin/env sh

# Gathers information about Google Chrome on a machine:
# Contents of .desktop files, which versions of Chrome are in path (e.g. snap or not),
# ...and which desktop file the launcher is using.
# Feel very free to add steps that gather additional, relevant information!

set -x

USER=".skjult"
DESKTOP_FILE_1=/usr/share/applications/google-chrome.desktop
# In case they've also added Chrome to their desktop
DESKTOP_FILE_2=/home/$USER/Skrivebord/google-chrome.desktop
# In case they've run chrome_autostart.sh.
# The name is no mistake, that one is not called google-chrome.desktop
DESKTOP_FILE_3=/home/$USER/.config/autostart/chrome.desktop
DESKTOP_FILE_4=/home/$USER/.local/share/applications/google-chrome.desktop

echo "File at $DESKTOP_FILE_1:"
cat "$DESKTOP_FILE_1"
echo "File at $DESKTOP_FILE_2:"
cat "$DESKTOP_FILE_2"
echo "File at $DESKTOP_FILE_3:"
cat "$DESKTOP_FILE_3"
echo "File at $DESKTOP_FILE_4:"
cat "$DESKTOP_FILE_4"

which google-chrome-stable
which google-chrome
google-chrome --version

cat /etc/dconf/db/os2borgerpc.d/02-launcher-favorites

exit

# dconf update

# Update google-chrome:
# apt-get update -y
# apt-get install google-chrome-stable

# Launch from TTY
# su --login user --command "export DISPLAY=:0 google-chrome-stable"
