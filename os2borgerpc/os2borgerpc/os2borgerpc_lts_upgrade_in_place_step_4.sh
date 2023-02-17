#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    lts_upgrade_in_place_4.sh
#%
#% DESCRIPTION
#%    Step four of the upgrade from 20.04 to 22.04.
#%
#================================================================
#- IMPLEMENTATION
#-    version         lts_upgrade_in_place_step_4.sh 0.0.1
#-    author          Andreas Poulsen
#-    copyright       Copyright 2022, Magenta Aps
#-    license         BSD/MIT
#-    email           info@magenta.dk
#-
#================================================================
#  HISTORY
#     2021/04/14 : ap : Moved this to a new step.
#
#================================================================
# END_OF_HEADER
#================================================================

set -ex

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
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

# Run security-related scripts
BRANCH="master"
wget https://github.com/OS2borgerPC/os2borgerpc-scripts/archive/refs/heads/$BRANCH.zip
unzip $BRANCH.zip
rm $BRANCH.zip

SCRIPT_DIR="os2borgerpc-scripts-$BRANCH"

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
  "$SCRIPT_DIR/os2borgerpc/desktop/polkit_policy_shutdown.sh" True False
fi

# Enable universal access menu by default
"$SCRIPT_DIR/os2borgerpc/desktop/dconf_policy_a11y.sh" True

# Make sure the client and its settings are up to date
"$SCRIPT_DIR/common/system/upgrade_client_and_settings.sh"

# Remove cloned script repository
rm --recursive "$SCRIPT_DIR"

# Restore crontab and reenable potential wake plans
TMP_CRON=/etc/os2borgerpc/tmp_cronfile
crontab $TMP_CRON
rm -f $TMP_CRON
if [ -f /etc/os2borgerpc/plan.json ]; then
  systemctl enable --now os2borgerpc-set_on-off_schedule.service
fi
