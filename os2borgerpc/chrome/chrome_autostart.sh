#!/usr/bin/env sh
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    chrome_autostart - args[fullscreen(Ja/Nej/Fjern)]
#%
#% DESCRIPTION
#%    This script sets Google Chrome to autostart in fullscreen or normal screen size.
#%
#================================================================
#- IMPLEMENTATION
#-    version         chrome_autostart (magenta.dk) 0.0.4
#-    author          Danni Als
#-    copyright       Copyright 2019, Magenta Aps"
#-    license         GNU General Public License
#-    email           danni@magenta.dk
#================================================================
# END_OF_HEADER
#================================================================

set -x

autostart_text="[Desktop Entry]\nType=Application\nExec=google-chrome-stable --password-store=basic --start-fullscreen\nHidden=false\nNoDisplay=false\nX-GNOME-Autostart-enabled=true\nName[en_US]=Chrome\nName=Chrome\nComment[en_US]=run the Google-chrome webbrowser at startup\nComment=run the Google-chrome webbrowser at startup\nName[en]=Chrome\n"
desktop_file="/home/.skjult/.config/autostart/google-chrome.desktop"

# The previous name of this desktop file should be deleted
rm --force "/home/.skjult/.config/autostart/chrome.desktop"

if [ "$1" = "Nej" ]
then
    autostart_text=$(echo "$autostart_text" | sed -e "s/ --start-fullscreen//g")
elif [ "$1" = "Fjern" ]
then
    printf  "%s\n" "Removing chrome from autostart"
    rm "$desktop_file"
    printf "%s\n" "Done."
    exit 0
fi

printf "%s\n" "Adding chrome to autostart"
mkdir --parents /home/.skjult/.config/autostart
# shellcheck disable=SC2059 # We want it to interpret the escape sequences and create newlines
printf "$autostart_text" > "$desktop_file"
printf  "%s\n" "Done."
