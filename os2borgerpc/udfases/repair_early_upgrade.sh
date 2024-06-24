#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    repair_early_upgrade.sh
#%
#% DESCRIPTION
#%    Repairs OS2borgerPC machines where the prompt to upgrade to Ubuntu 22.04 was accepted.
#%    Introduces the same settings as the upgrade scripts.
#%
#================================================================
#- IMPLEMENTATION
#-    version         repair_early_upgrade.sh 0.0.1
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

if ! lsb_release -d | grep --quiet 22; then
  echo "Denne maskine er ikke blevet opgraderet til Ubuntu 22.04. Dette script vil ikke have nogen effekt."
  exit 1
fi
# Fix dpkg settings to avoid interactivity.
cat << EOF > /etc/apt/apt.conf.d/local
Dpkg::Options {
   "--force-confdef";
   "--force-confold";
};
Dpkg::Lock {Timeout "300";};
EOF

apt-get --assume-yes update

# If user access to settings was removed at the time of the upgrade to Ubuntu 22.04
if [ -f "/usr/bin/gnome-control-center.real" ] && ! grep --quiet "zenity" /usr/bin/gnome-control-center; then
  # Remove the permissions override and manually reset permissions to defaults
  # Suppress error to prevent set -e exiting in case the override no longer exists
  dpkg-statoverride --remove /usr/bin/gnome-control-center.real || true
  # Delete the old gnome-control-center, which is called real
  rm -f /usr/bin/gnome-control-center.real
  # Remove user access to settings (restore default state)
  if [ ! -f "/usr/bin/gnome-control-center.real" ]; then
    dpkg-divert --rename --divert  /usr/bin/gnome-control-center.real --add /usr/bin/gnome-control-center
    dpkg-statoverride --update --add superuser root 770 /usr/bin/gnome-control-center.real
  fi
  cat << EOF > /usr/bin/gnome-control-center
#!/bin/bash

USER=\$(id -un)

if [ \$USER == "user" ]; then
  zenity --info --text="Systemindstillingerne er ikke tilgængelige for publikum.\n\n Kontakt personalet, hvis der er problemer."
else
  /usr/bin/gnome-control-center.real
fi
EOF

  chmod +x /usr/bin/gnome-control-center

# If user access to settings was removed at the time of the upgrade and they then tried to remove it again
elif grep --quiet "zenity" /usr/bin/gnome-control-center && ! /usr/bin/gnome-control-center.real --version | grep 41.7; then
  # Remove the permissions override and manually reset permissions to defaults
  # Suppress error to prevent set -e exiting in case the override no longer exists
  dpkg-statoverride --remove /usr/bin/gnome-control-center.real || true
  chown root:root /usr/bin/gnome-control-center.real
  chmod 755 /usr/bin/gnome-control-center.real
  # Remove the shell script that prints the error message
  rm /usr/bin/gnome-control-center
  # Remove location override and restore gnome-control-center.real back to gnome-control-center
  dpkg-divert --remove --no-rename /usr/bin/gnome-control-center
  # dpkg-divert can --rename it itself, but the problem with doing that is that in some images
  # dpkg-divert is not used, it was simply moved/copied, so that won't restore it, leaving you
  # with no gnome-control-center
  mv /usr/bin/gnome-control-center.real /usr/bin/gnome-control-center
  # Update gnome-control-center to the newest version
  apt-get install --assume-yes gnome-control-center
  # Remove user access to settings (restore default state)
  if [ ! -f "/usr/bin/gnome-control-center.real" ]; then
    dpkg-divert --rename --divert  /usr/bin/gnome-control-center.real --add /usr/bin/gnome-control-center
    dpkg-statoverride --update --add superuser root 770 /usr/bin/gnome-control-center.real
  fi
  cat << EOF > /usr/bin/gnome-control-center
#!/bin/bash

USER=\$(id -un)

if [ \$USER == "user" ]; then
  zenity --info --text="Systemindstillingerne er ikke tilgængelige for publikum.\n\n Kontakt personalet, hvis der er problemer."
else
  /usr/bin/gnome-control-center.real
fi
EOF

  chmod +x /usr/bin/gnome-control-center

# If user access to settings was removed at the time of the upgrade and they then tried to restore access
elif [ ! -f "/usr/bin/gnome-control-center.real" ] && ! /usr/bin/gnome-control-center --version | grep 41.7; then
  # Update gnome-control-center to the newest version
  apt-get install --assume-yes gnome-control-center
fi

# Make sure that the extension responsible for handling desktop icons is installed correctly
apt install gnome-shell-extension-desktop-icons-ng

# Remove the old client
NEW_CLIENT="/usr/local/lib/python3.10/dist-packages/os2borgerpc/client/jobmanager.py"
if [ -f $NEW_CLIENT ]; then
  rm -rf /usr/local/lib/python3.8/
fi

# Restore firefox startpage(s) settings if any had been set
FIREFOX_POLICY_FILE=/usr/lib/firefox/distribution/policies.json
NEW_FIREFOX_POLICY_FILE=/etc/firefox/policies/policies.json
if [ ! -d "/etc/firefox/policies" ]; then
  mkdir -p /etc/firefox/policies
fi
if [ -f "$FIREFOX_POLICY_FILE" ] && [ ! -f "$NEW_FIREFOX_POLICY_FILE" ]; then
  mv $FIREFOX_POLICY_FILE /etc/firefox/policies/
fi

# Replace possible firefox desktop shortcuts with the snap version
if [ -f "/home/.skjult/Skrivebord/firefox.desktop" ]; then
  rm /home/.skjult/Skrivebord/firefox.desktop
  cp "/var/lib/snapd/desktop/applications/firefox_firefox.desktop" /home/.skjult/Skrivebord/
fi

# Remove the old version of firefox
rm -f /usr/share/applications/firefox.desktop
# Rename possible firefox favorite to the name of the snap
FAVORITES_FILE="/etc/dconf/db/os2borgerpc.d/02-launcher-favorites"
sed -i "s/'firefox.desktop'/'firefox_firefox.desktop'/" $FAVORITES_FILE

# Change the release-upgrade prompt back to never.
# This should prevent future popups regarding updates
release_upgrades_file=/etc/update-manager/release-upgrades
sed -i "s/Prompt=.*/Prompt=never/" $release_upgrades_file

# Enable FSCK automatic fixes
sed --in-place "s/FSCKFIX=no/FSCKFIX=yes/" /lib/init/vars.sh

# Restore default browser settings
# The upgrade changes firefox to a snap called firefox_firefox.desktop so rename the related entry if it exists
FILE="/usr/share/applications/defaults.list"
if grep --quiet 'x-scheme-handler/https=firefox' $FILE; then
  sed -i "s/=firefox.desktop/=firefox_firefox.desktop/" $FILE
fi

# Remove lightdm access to network settings and restore user access to network settings, if they had been given
NETWORK_FILE=/etc/NetworkManager/NetworkManager.conf
NETWORK_FILE2=/var/lib/polkit-1/localauthority/50-local.d/networkmanager.pkla
if ! grep --quiet "unix-user:lightdm" $NETWORK_FILE2; then
  cat << EOF >> $NETWORK_FILE2
[NetworkManager3]
Identity=unix-user:lightdm
Action=org.freedesktop.NetworkManager.*
ResultAny=no
ResultInactive=no
ResultActive=no

EOF
fi
if grep --quiet "auth-polkit=false" $NETWORK_FILE; then
  sed --in-place '/unix-group:user/{ n; n; n; n; s/ResultActive=no/ResultActive=yes/ }' $NETWORK_FILE2
fi

# Fix any potential desktop logout buttons with prompts
DESKTOP_LOGOUT_FILE="/home/.skjult/Skrivebord/logout.desktop"
OLD_DESKTOP_LOGOUT_FILE="/home/.skjult/Skrivebord/Logout.desktop"
if [ -f $DESKTOP_LOGOUT_FILE ] && ! grep --quiet "no-prompt" $DESKTOP_LOGOUT_FILE; then
  sed --in-place 's/Exec=gnome-session-quit --logout/Exec=sh -c "sleep 0.1 \&\& gnome-session-quit --logout"/' $DESKTOP_LOGOUT_FILE
elif [ -f $OLD_DESKTOP_LOGOUT_FILE ] && ! grep --quiet "no-prompt" $OLD_DESKTOP_LOGOUT_FILE; then
  sed --in-place 's/Exec=gnome-session-quit --logout/Exec=sh -c "sleep 0.1 \&\& gnome-session-quit --logout"/' $OLD_DESKTOP_LOGOUT_FILE
fi

# Overwrite the desktop icons policy file with the new expected format
DESKTOP_ICONS_POLICY_FILE="/etc/dconf/db/os2borgerpc.d/01-desktop-icons"
cat > "$DESKTOP_ICONS_POLICY_FILE" <<-END
[org/gnome/shell/extensions/ding]
show-home=false
show-trash=false
start-corner='top-left'
END

# Hide unnecessary dock elements
DOCK_SETTINGS_FILE="/etc/dconf/db/os2borgerpc.d/03-dock-settings"
cat > "$DOCK_SETTINGS_FILE" <<-END
[org/gnome/shell/extensions/dash-to-dock]
show-trash=false
END

dconf update

# Run security-related scripts
BRANCH="master"
SCRIPT_DIR="os2borgerpc-scripts-$BRANCH"
rm --recursive --force "$SCRIPT_DIR"
wget https://github.com/OS2borgerPC/os2borgerpc-scripts/archive/refs/heads/$BRANCH.zip
unzip $BRANCH.zip
rm $BRANCH.zip

# Lock the left-hand menu
"$SCRIPT_DIR/os2borgerpc/sikkerhed/dconf_gnome_lock_menu_editing.sh" True

# Remove lock from the menu
"$SCRIPT_DIR/os2borgerpc/desktop/dconf_disable_lock_menu.sh" True

# Remove switch user from the menu
"$SCRIPT_DIR/os2borgerpc/desktop/dconf_disable_user_switching.sh" True

# Setup a script to activate the desktop shortcuts for user on login
"$SCRIPT_DIR/os2borgerpc/desktop/desktop_activate_shortcuts.sh"

# Remove user write access to desktop
"$SCRIPT_DIR/os2borgerpc/sikkerhed/desktop_toggle_writable.sh" True

# Set "user" as the default user
"$SCRIPT_DIR/os2borgerpc/login/set_user_as_default_lightdm_user.sh" True

# Enable running scripts at login
"$SCRIPT_DIR/os2borgerpc/login/lightdm_greeter_setup_scripts.sh" True False

# Disable the run prompt
"$SCRIPT_DIR/os2borgerpc/sikkerhed/dconf_run_prompt_toggle.sh" True

# Fix /etc/hosts
"$SCRIPT_DIR/os2borgerpc/os2borgerpc/fix_etc_hosts.sh"

# Disable suspend from the menu unless they've explicitly set their own policy for this
POWER_POLICY="/etc/polkit-1/localauthority/90-mandatory.d/10-os2borgerpc-no-user-shutdown.pkla"
if [ ! -f $POWER_POLICY ]; then
  "$SCRIPT_DIR/os2borgerpc/desktop/polkit_policy_shutdown_suspend.sh" True False
fi

# Enable universal access menu by default
"$SCRIPT_DIR/os2borgerpc/desktop/dconf_a11y.sh" True

# Add the new firefox policies, if they don't have them
NEW_FIREFOX_POLICY_FILE=/etc/firefox/policies/policies.json
if [ ! -f $NEW_FIREFOX_POLICY_FILE ]; then
  "$SCRIPT_DIR/os2borgerpc/firefox/firefox_global_policies.sh" https://borger.dk
elif ! grep --quiet "DisableDeveloperTools" $NEW_FIREFOX_POLICY_FILE; then
  MAIN_URL=$(grep "URL" $NEW_FIREFOX_POLICY_FILE | cut --delimiter ' ' --fields 8)
  MAIN_URL=${MAIN_URL:1:-2}
  EXTRA_URLS=$(grep "Additional" $NEW_FIREFOX_POLICY_FILE | cut --delimiter '[' --fields 2)
  EXTRA_URLS=${EXTRA_URLS:1:-3}
  EXTRA_URLS=${EXTRA_URLS//\", \"/|}
  "$SCRIPT_DIR/os2borgerpc/firefox/firefox_global_policies.sh" "$MAIN_URL" "$EXTRA_URLS"
fi

# Disable libreoffice Tip of the day
MS_FILE_FORMAT=False
if grep --quiet "MS Word 2007" /home/.skjult/.config/libreoffice/4/user/registrymodifications.xcu; then
  MS_FILE_FORMAT=True
fi
"$SCRIPT_DIR/os2borgerpc/libreoffice/overwrite_libreoffice_config.sh" True $MS_FILE_FORMAT

# Make sure the client settings are up to date
"$SCRIPT_DIR/common/system/upgrade_client_and_settings.sh"

# Remove cloned script repository
rm --recursive "$SCRIPT_DIR"

# Update distribution to show ubuntu22.04
set_os2borgerpc_config distribution ubuntu22.04

os2borgerpc_push_config_keys distribution

apt-get --assume-yes update

# Remove unnecessary applications
apt-get --assume-yes remove --purge remmina transmission-gtk apport whoopsie

apt-get --assume-yes autoremove

apt-get --assume-yes clean
