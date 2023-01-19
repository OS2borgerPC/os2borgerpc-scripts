#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    lts_upgrade_in_place_4.sh
#%
#% DESCRIPTION
#%    Step three of the upgrade from 16.04 to 20.04.
#%
#================================================================
#- IMPLEMENTATION
#-    version         lts_upgrade_in_place_step_3.sh 0.0.1
#-    author          Carsten Agger, Marcus Funch Mogensen
#-    copyright       Copyright 2020, Magenta Aps
#-    license         BSD/MIT
#-    email           info@magenta.dk
#-
#================================================================
#  HISTORY
#     2021/04/14 : carstena : Moved this to a new step.
#
#================================================================
# END_OF_HEADER
#================================================================

OUR_USER=chrome

set -ex


apt-get update
export DEBIAN_FRONTEND=noninteractive
apt-get install -y python3-pip

rm -r /usr/local/lib/python2.7
rm -r /usr/local/bin/*bibos*

pip3 install os2borgerpc-client
ln -s /var/lib/bibos /var/lib/os2borgerpc
ln -s /etc/bibos /etc/os2borgerpc


# xrandr and some other utilities "fall off" in the upgrade process.
apt install x11-xserver-utils

### MIGRATE OS2DISPLAY SETUP WITH CHROMIUM ###

# Another solution would be copying over xinitrc first, making a new one and
# restoring the proper one afterwards.

# Fetch the line executing chromium before we remove it
LAUNCH_CHROMIUM_LINE=$(grep '^exec chromium' /home/$OUR_USER/.xinitrc)

SCRIPT_PATH="/home/$OUR_USER/migrate-os2display.sh"

# As the script below appends to .xinitrc OUR_USER needs write access to
# .xinitrc
chown $OUR_USER:$OUR_USER /home/$OUR_USER/.xinitrc

cat << EOF > $SCRIPT_PATH

  # Launch chromium so the proper directories / files are created
  chromium &
  sleep 5
  # Note: Confusingly it can be launched with 'chromium' or 'chromium-browser', 
  # but the binary once running is called 'chrome'
  killall chrome

  # Migrate the OS2Display settings
  cp -r /home/$OUR_USER/.config/chromium/ /home/chrome/snap/chromium/common

  # Change xinitrc back to how it was
  sed -i "s@$SCRIPT_PATH@@" /home/$OUR_USER/.xinitrc
  echo "$LAUNCH_CHROMIUM_LINE" >> /home/$OUR_USER/.xinitrc

  # Delete yourself
  rm "$SCRIPT_PATH"

  # Now launch chromium normally - or just restart
  eval "$LAUNCH_CHROMIUM_LINE"
  #reboot
EOF

chmod u+x "$SCRIPT_PATH"
# OUR_USER needs better access to the script to be able to cleanup and delete it
chown $OUR_USER:$OUR_USER "$SCRIPT_PATH"

# Don't autostart chromium on the next run
sed -i "s@$LAUNCH_CHROMIUM_LINE@@" /home/$OUR_USER/.xinitrc

# ...but instead run the script above
echo "$SCRIPT_PATH" >> /home/$OUR_USER/.xinitrc
