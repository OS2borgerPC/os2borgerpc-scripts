#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    os2borgerpc_lts_upgrade_in_place_step_3.sh
#%
#% DESCRIPTION
#%    Step three of the upgrade from 20.04 to 22.04.
#%    Designed for regular OS2borgerPC machines
#%
#================================================================
#- IMPLEMENTATION
#-    version         os2borgerpc_lts_upgrade_in_place_step_3.sh 0.0.1
#-    author          Andreas Poulsen
#-    copyright       Copyright 2022, Magenta Aps
#-    license         BSD/MIT
#-    email           info@magenta.dk
#-
#================================================================
#  HISTORY
#     2022/09/15 : ap : Script creation
#
#================================================================
# END_OF_HEADER
#================================================================

set -ex

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

# Make double sure that the crontab has been emptied
TMP_ROOTCRON=/etc/os2borgerpc/tmp_rootcronfile
if [ -f "$TMP_ROOTCRON" ]; then
  crontab -r || true
  crontab -u user -r || true
fi

# Preserve firefox startpage(s) settings if any have been set
FIREFOX_POLICY_FILE=/usr/lib/firefox/distribution/policies.json
NEW_FIREFOX_POLICY_FILE=/etc/firefox/policies/policies.json
if [ ! -d "/etc/firefox/policies" ]; then
  mkdir -p /etc/firefox/policies
fi
if [ -f "$FIREFOX_POLICY_FILE" ] && [ ! -f "$NEW_FIREFOX_POLICY_FILE" ]; then
  mv $FIREFOX_POLICY_FILE /etc/firefox/policies/
fi

# Reset settings access to default to avoid issues with the upgrade
if grep --quiet 'zenity' /usr/bin/gnome-control-center; then
  # Remove the permissions override and manually reset permissions to defaults
  # Suppress error to prevent set -e exiting in case the override no longer exists
  dpkg-statoverride --remove /usr/bin/gnome-control-center.real || true
  chown root:root /usr/bin/gnome-control-center.real
  chmod 755 /usr/bin/gnome-control-center.real
  # Remove the shell script that prints the error message
  rm /usr/bin/gnome-control-center
  # Remove location override and restore gnome-control-center.real back to gnome-control-center
  dpkg-divert --remove /usr/bin/gnome-control-center
  # dpkg-divert can --rename it itself, but the problem with doing that is that in some images
  # dpkg-divert is not used, it was simply moved/copied, so that won't restore it, leaving you
  # with no gnome-control-center
  mv /usr/bin/gnome-control-center.real /usr/bin/gnome-control-center
fi


# Make sure release-upgrade prompt is not never so that the upgrade can run
# Also set the prompt to lts so that the upgrader will only look for lts releases
release_upgrades_file=/etc/update-manager/release-upgrades

sed -i "s/Prompt=.*/Prompt=lts/" $release_upgrades_file

# Perform the actual upgrade with some error handling
ERRORS="False"
do-release-upgrade -f DistUpgradeViewNonInteractive > /var/log/os2borgerpc_upgrade_1.log || ERRORS="True"

# Make sure that jobmanager can still find the client
pip install -q os2borgerpc_client

if [ "$ERRORS" == "True" ]; then
  apt-get --assume-yes --fix-broken install
  apt-get --assume-yes autoremove
  apt-get --assume-yes clean
fi

if ! lsb_release -d | grep --quiet 22; then
  echo "Opgraderingen er ikke blevet gennemført. Prøv at genstarte computeren og køre dette script igen."
  exit 1
fi

# Make sure that the extension responsible for handling desktop icons is installed correctly
apt install gnome-shell-extension-desktop-icons-ng

# Replace possible firefox desktop shortcuts with the snap version
if [ -f "/home/.skjult/Skrivebord/firefox.desktop" ]; then
  rm /home/.skjult/Skrivebord/firefox.desktop
  cp "/var/lib/snapd/desktop/applications/firefox_firefox.desktop" /home/.skjult/Skrivebord/
fi

# Remove the old version of firefox
rm -f /usr/share/applications/firefox.desktop
# Rename possible firefox favorite to the name of the snap
FAVORITES_FILE="/etc/dconf/db/os2borgerpc.d/02-launcher-favorites"
sed -i "s/'firefox.desktop'/'firefox_firefox.desktop'/" "$FAVORITES_FILE"
# sed -i "s/NoDisplay=true/NoDisplay=false/" /usr/share/applications/firefox.desktop

touch /etc/os2borgerpc/third_upgrade_step_done
