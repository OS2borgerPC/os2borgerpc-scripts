#! /usr/bin/env sh

# General information script for OS2borgerPC, useful for debugging
# Feel very free to add steps that gather additional, relevant information and commit the changes!

USER="user"
SKELETON=".skjult"

header() {
  MSG=$1
  printf "\n\n\n%s\n\n\n" "### $MSG: ###"
}

text() {
  MSG=$1
  printf "\n%s\n" "### $MSG: ###"
}

# Determine the name of the user desktop directory. This is done via xdg-user-dir,
# which checks the /home/user/.config/user-dirs.dirs file. To ensure this file exists,
# we run xdg-user-dirs-update, which generates it based on the environment variable
# LANG. This variable is empty in lightdm so we first export it
# based on the value stored in /etc/default/locale
export "$(grep LANG= /etc/default/locale | tr -d '"')"
runuser -u $USER xdg-user-dirs-update
DESKTOP=$(basename "$(runuser -u $USER xdg-user-dir DESKTOP)")

header "General info"

text "Information about the computer model"
dmidecode --type 1

text "LAN or Wi-Fi?"
ip link

text "OS2borgerPC configuration file"
cat /etc/os2borgerpc/os2borgerpc.conf

text "OS2borgerPC client version"
pip3 list installed | grep os2borgerpc-client

text "Info on lightdm, the display manager"
cat /etc/lightdm/lightdm.conf

text "Info on automatic updates"
cat /etc/apt/apt.conf.d/90os2borgerpc-automatic-upgrades

text "User cleanup file contents"
cat /usr/share/os2borgerpc/bin/user-cleanup.bash

text "Check permissions on files in /usr/share/os2borgerpc/bin/"
ls -l /usr/share/os2borgerpc/bin/

text "List programs/files on the desktop"
ls -l /home/$USER/"$DESKTOP"/

text "Verify this matches what's in the user template (after logout)"
ls -l /home/$SKELETON/"$DESKTOP"/

text "Check the contents of /home/$SKELETON/"
ls -la /home/$SKELETON/

text "Check the contents of /home/$SKELETON/.config/"
ls -la /home/$SKELETON/.config/

text "Check the contents of /home/$SKELETON/.local/"
ls -la /home/$SKELETON/.local/

text "List programs in the launcher:"
cat /etc/dconf/db/os2borgerpc.d/02-launcher-favorites

text "Info about the current background image"
cat /etc/dconf/db/os2borgerpc.d/00-background

text "Check the crontab"
crontab -l
crontab -u $USER -l

text "Check the inactive logout file"
cat /usr/share/os2borgerpc/bin/inactive_logout.sh

text "Info about Apt sources"
find /etc/apt/sources.list.d/ -mindepth 1 -print -exec cat {} \; -printf "\n"


header "Info about kernel, devices and drivers"

text "List currently active kernel version"
uname -a

text "List all installed kernels"
dpkg --get-selections | grep --invert-match deinstall | grep linux-image

text "List kernel modules currently loaded (fx. drivers)"
lsmod

text "List info on connected hardware"
lshw

text "Info about printers"
lpinfo -v

text "Info about scanners"
scanimage -L


# Firefox related

header "Firefox related info"

text "Firefox version"
snap list | grep firefox

text "Firefox policies (if any)"
cat /etc/firefox/policies/policies.json

### CHROME / CHROMIUM RELATED INFO ###

header "Chrome/Chromium related info"

# Gathers information about Google Chrome on a machine:
# Contents of .desktop files, which versions of Chrome are in path (e.g. snap or not),
# ...and which desktop file the launcher is using.

which google-chrome-stable
which google-chrome
google-chrome --version

text "Check chrome policies"
cat /etc/opt/chrome/policies/managed/os2borgerpc-defaults.json

DESKTOP_FILE_1="/usr/share/applications/google-chrome.desktop"
# In case they've also added Chrome to their desktop
DESKTOP_FILE_2="/home/$SKELETON/$DESKTOP/google-chrome.desktop"
# In case they've run chrome_autostart.sh.
# The name is no mistake, that one is unfortunately not called google-chrome.desktop
DESKTOP_FILE_3="/home/$SKELETON/.config/autostart/chrome.desktop"
DESKTOP_FILE_4="/home/$SKELETON/.local/share/applications/google-chrome.desktop"

text "File at $DESKTOP_FILE_1"
cat "$DESKTOP_FILE_1"
text "File at $DESKTOP_FILE_2"
cat "$DESKTOP_FILE_2"
text "File at $DESKTOP_FILE_3"
cat "$DESKTOP_FILE_3"
text "File at $DESKTOP_FILE_4"
cat "$DESKTOP_FILE_4"

# Launch from TTY
# su --login user --command "export DISPLAY=:0 google-chrome-stable"

# Always exit successfully as some of these files may not exist simply because the related
# scripts haven't been run, so it's not an error
exit 0
