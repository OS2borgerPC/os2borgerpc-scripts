#! /usr/bin/env sh

# General information script for OS2borgerPC Kiosk, useful for debugging
# Please add more commands to this script as needed and commit the changes

USER=chrome

header() {
  MSG=$1
  printf "\n\n\n%s\n\n\n" "### $MSG ###"
}

text() {
  MSG=$1
  printf "\n%s\n" "### $MSG ###"
}


header "General information from only a basic setup"

text "Information about the computer model:"
dmidecode --type 1

text "Files under /usr/share/os2borgerpc/bin"
ls -la /usr/share/os2borgerpc/bin/

text "OS2borgerPC configuration file:"
cat /etc/os2borgerpc/os2borgerpc.conf

text "OS2borgerPC client version:"
pip3 list installed | grep os2borgerpc-client


header "Chromium / Xorg info"

text "Is Chromium running?:"
pgrep --list-full chrome  # yes, the binary is called 'chrome'

text "The version of Chromium:"
chromium-browser --version

text "Contents of chrome's home directory:"
ls -la /home/$USER/

text ".xinitrc contents:"
cat /home/$USER/.xinitrc

header "List assorted device info"
lshw

header "List kernel modules currently loaded (fx. drivers)"
lsmod

header "Information about monitors"

text "rotate_screen.sh's permissions:"
# This file really ought to be in /usr/share/os2borgerpc/bin...:
ls -l /usr/local/bin/rotate_screen.sh

text "rotate_screen.sh's contents:"
cat /usr/local/bin/rotate_screen.sh

text "Run xrandr to get info about monitors:"
export DISPLAY=:0
export XAUTHORITY=/home/$USER/.Xauthority
xrandr


header "Information for those running the onboard keyboard, possibly including the button to hide it"

text "bspwmrc contents"
cat /home/$USER/.config/bspwm/bspwmrc

text "start_chromium.sh contents"
cat /usr/share/os2borgerpc/bin/start_chromium.sh

ls -la /usr/share/os2borgerpc/bin/keyboard-button/

text "bspwm_add_button.sh contents:"
cat /usr/share/os2borgerpc/bin/keyboard-button/bspwn_add_button.sh


header "Print Xorg.log excerpt (fx. if Xorg fails to start)"
tail --lines=250 /home/$USER/.local/share/xorg/Xorg.0.log

# Always exit successfully as some of these files may not exist simply because the related
# scripts haven't been run, so it's not an error
exit 0
