#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    os2borgerpc_lts_upgrade_in_place_step_4.sh
#%
#% DESCRIPTION
#%    Step four of the upgrade from 20.04 to 22.04.
#%    Designed for regular OS2borgerPC machines
#%
#================================================================
#- IMPLEMENTATION
#-    version         os2borgerpc_lts_upgrade_in_place_step_4.sh 0.0.1
#-    author          Andreas Poulsen
#-    copyright       Copyright 2022, Magenta Aps
#-    license         BSD/MIT
#-    email           info@magenta.dk
#-
#================================================================
#  HISTORY
#     2022/09/15 : ap : Script creation.
#
#================================================================
# END_OF_HEADER
#================================================================

set -ex

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

PREVIOUS_STEP_DONE="/etc/os2borgerpc/third_upgrade_step_done"
if [ ! -f "$PREVIOUS_STEP_DONE" ]; then
  echo "22.04 opgradering - Opgradering til Ubuntu 22.04 trin 3 er ikke blevet gennemført."
  exit 1
fi

# Make double sure that the crontab has been emptied
TMP_ROOTCRON=/etc/os2borgerpc/tmp_rootcronfile
if [ -f "$TMP_ROOTCRON" ]; then
  crontab -r || true
fi

# Reset jobmanager timeout to default value
set_os2borgerpc_config job_timeout 900

os2borgerpc_push_config_keys job_timeout

# Update distribution to show ubuntu22.04
set_os2borgerpc_config distribution ubuntu22.04

os2borgerpc_push_config_keys distribution

# Change the release-upgrade prompt back to never.
# This should prevent future popups regarding updates
release_upgrades_file=/etc/update-manager/release-upgrades
sed -i "s/Prompt=.*/Prompt=never/" $release_upgrades_file

# Enable FSCK automatic fixes
sed --in-place "s/FSCKFIX=no/FSCKFIX=yes/" /lib/init/vars.sh

# Remove the old client
NEW_CLIENT="/usr/local/lib/python3.10/dist-packages/os2borgerpc/client/jobmanager.py"
if [ -f $NEW_CLIENT ]; then
  rm -rf /usr/local/lib/python3.8/
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

if [ -f "/usr/bin/gnome-control-center.real" ] && ! grep --quiet "zenity" /usr/bin/gnome-control-center; then
  rm /usr/bin/gnome-control-center.real
fi

# Remove user access to settings
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

# Fix any potential desktop logout buttons with prompts
DESKTOP_LOGOUT_FILE="/home/.skjult/Skrivebord/logout.desktop"
OLD_DESKTOP_LOGOUT_FILE="/home/.skjult/Skrivebord/Logout.desktop"
if [ -f $DESKTOP_LOGOUT_FILE ] && ! grep --quiet "no-prompt" $DESKTOP_LOGOUT_FILE; then
  sed --in-place 's/Exec=gnome-session-quit --logout/Exec=sh -c "sleep 0.1 \&\& gnome-session-quit --logout"/' $DESKTOP_LOGOUT_FILE
elif [ -f $OLD_DESKTOP_LOGOUT_FILE ] && ! grep --quiet "no-prompt" $OLD_DESKTOP_LOGOUT_FILE; then
  sed --in-place 's/Exec=gnome-session-quit --logout/Exec=sh -c "sleep 0.1 \&\& gnome-session-quit --logout"/' $OLD_DESKTOP_LOGOUT_FILE
fi

# Maintain default browser settings
# The upgrade changes firefox to a snap called firefox_firefox.desktop so rename the related entry if it exists
FILE="/usr/share/applications/defaults.list"
if grep --quiet 'x-scheme-handler/https=firefox' $FILE; then
  sed -i "s/=firefox.desktop/=firefox_firefox.desktop/" "$FILE"
fi

# Remove lightdm access to network settings and maintain user access to network settings, if they had been given
# Also make paths to polkit files consistent, so they aren't divided between /etc/ and /var/lib
NETWORK_FILE=/etc/NetworkManager/NetworkManager.conf
NM_POLKIT_OLD=/var/lib/polkit-1/localauthority/50-local.d/networkmanager.pkla
NM_POLKIT_NEW=/etc/polkit-1/localauthority/50-local.d/networkmanager.pkla
mkdir --parents "$(dirname $NM_POLKIT_NEW)"

if [ -f $NM_POLKIT_OLD ]; then
  mv $NM_POLKIT_OLD $NM_POLKIT_NEW
fi

if ! grep --quiet "unix-user:lightdm" $NM_POLKIT_NEW; then
  cat << EOF >> $NM_POLKIT_NEW
[NetworkManager3]
Identity=unix-user:lightdm
Action=org.freedesktop.NetworkManager.*
ResultAny=no
ResultInactive=no
ResultActive=no

EOF
fi
if grep --quiet "auth-polkit=false" $NETWORK_FILE; then
  sed --in-place '/unix-group:user/{ n; n; n; n; s/ResultActive=no/ResultActive=yes/ }' $NM_POLKIT_NEW
fi

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
"$SCRIPT_DIR/os2borgerpc/os2borgerpc/disable_lock_menu_dconf.sh" True

# Remove switch user from the menu
"$SCRIPT_DIR/os2borgerpc/os2borgerpc/disable_user_switching_dconf.sh" True

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
"$SCRIPT_DIR/os2borgerpc/desktop/dconf_policy_a11y.sh" True

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

# Enable automatic security updates if they have never run the related script before
UNATTENDED_UPGRADES_FILE="/etc/apt/apt.conf.d/90os2borgerpc-automatic-upgrades"
if [ ! -f "$UNATTENDED_UPGRADES_FILE" ]; then
  "$SCRIPT_DIR/common/system/apt_periodic_control.sh" security
fi

# Make sure the client settings are up to date
rm --force /etc/os2borgerpc/security/securityevent.csv

for j in /var/lib/os2borgerpc/jobs/*; do
  if [ "$(cat "$j"/status)" = "DONE" ] || [ "$(cat "$j"/status)" = "FAILED" ]; then
      rm --force "$j/parameters.json"
  fi
done

chmod --recursive 700 /var/lib/os2borgerpc

chmod -R 700 /home/superuser
chown -R superuser:superuser /home/superuser/Skrivebord

# Remove cloned script repository
rm --recursive "$SCRIPT_DIR"

# Fix dpkg settings
cat << EOF > /etc/apt/apt.conf.d/local
Dpkg::Options {
   "--force-confdef";
   "--force-confold";
};
Dpkg::Lock {Timeout "300";};
EOF

# Restore crontab and reenable potential wake plans
TMP_ROOTCRON=/etc/os2borgerpc/tmp_rootcronfile
TMP_USERCRON=/etc/os2borgerpc/tmp_usercronfile
if [ -f "$TMP_ROOTCRON" ]; then
  crontab $TMP_ROOTCRON
  crontab -u user $TMP_USERCRON
  rm -f $TMP_ROOTCRON $TMP_USERCRON
fi
if [ -f /etc/os2borgerpc/plan.json ]; then
  systemctl enable --now os2borgerpc-set_on-off_schedule.service
fi

rm --force $PREVIOUS_STEP_DONE
