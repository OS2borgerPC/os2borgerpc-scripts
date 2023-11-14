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
# The first sed in each case handles our own desktop logout buttons
# The second sed in each case handles custom logout buttons used by e.g. Århus
DESKTOP_LOGOUT_FILE="/home/.skjult/Skrivebord/logout.desktop"
OLD_DESKTOP_LOGOUT_FILE="/home/.skjult/Skrivebord/Logout.desktop"
if [ -f $DESKTOP_LOGOUT_FILE ] && ! grep --quiet "no-prompt" $DESKTOP_LOGOUT_FILE; then
  sed --in-place 's/Exec=gnome-session-quit --logout/Exec=sh -c "sleep 0.1 \&\& gnome-session-quit --logout"/' $DESKTOP_LOGOUT_FILE
  sed --in-place 's/Exec=gnome-session-quit/Exec=sh -c "sleep 0.1 \&\& gnome-session-quit"/' $DESKTOP_LOGOUT_FILE
elif [ -f $OLD_DESKTOP_LOGOUT_FILE ] && ! grep --quiet "no-prompt" $OLD_DESKTOP_LOGOUT_FILE; then
  sed --in-place 's/Exec=gnome-session-quit --logout/Exec=sh -c "sleep 0.1 \&\& gnome-session-quit --logout"/' $OLD_DESKTOP_LOGOUT_FILE
  sed --in-place 's/Exec=gnome-session-quit/Exec=sh -c "sleep 0.1 \&\& gnome-session-quit"/' $OLD_DESKTOP_LOGOUT_FILE
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

# Prevent the scanner program from asking for superuser password
# if network printer search is disabled
if systemctl status avahi-daemon | grep masked; then
  POLKIT_POLICY="/etc/polkit-1/localauthority/10-vendor.d/01-os2borgerpc-deny-user-managing-units.pkla"
  cat <<- EOF > $POLKIT_POLICY
[User shan't manage units, to prevent simple-scan/saned from prompting for password trying to start avahi-daemon]
Identity=unix-user:user
Action=org.freedesktop.systemd1.manage-units
ResultAny=no
ResultInactive=no
ResultActive=no
EOF
fi

# Run security-related scripts

# Lock the left-hand menu
LAUNCHER_POLICY_LOCK_FILE=/etc/dconf/db/os2borgerpc.d/locks/02-launcher-favorites
cat <<- EOF > $LAUNCHER_POLICY_LOCK_FILE
/org/gnome/shell/favorite-apps
EOF

# Remove lock from the menu
POLICY_PATH="org/gnome/desktop/lockdown"
POLICY="disable-lock-screen"
POLICY_VALUE="true"

POLICY_FILE="/etc/dconf/db/os2borgerpc.d/00-$POLICY"
POLICY_LOCK_FILE="/etc/dconf/db/os2borgerpc.d/locks/00-$POLICY"

mkdir --parents "$(dirname $POLICY_FILE)" "$(dirname $POLICY_LOCK_FILE)"

cat > "/etc/dconf/profile/user" <<-END
user-db:user
system-db:os2borgerpc
END

cat > "$POLICY_FILE" <<-END
[$POLICY_PATH]
$POLICY=$POLICY_VALUE
END

touch "$(dirname "$POLICY_FILE")"

cat > "$POLICY_LOCK_FILE" <<-END
/$POLICY_PATH/$POLICY
END

# Remove switch user from the menu
POLICY2="disable-user-switching"

POLICY_FILE2="/etc/dconf/db/os2borgerpc.d/00-$POLICY2"
POLICY_LOCK_FILE2="/etc/dconf/db/os2borgerpc.d/locks/00-$POLICY2"

cat > "$POLICY_FILE2" <<-END
[$POLICY_PATH]
$POLICY2=$POLICY_VALUE
END

touch "$(dirname "$POLICY_FILE2")"

cat > "$POLICY_LOCK_FILE2" <<-END
/$POLICY_PATH/$POLICY2
END

# Setup a script to activate the desktop shortcuts for user on login
USERNAME="user"
SHADOW=.skjult
GIO_LAUNCHER=/usr/share/os2borgerpc/bin/gio-fix-desktop-file-permissions.sh
GIO_SCRIPT=/usr/share/os2borgerpc/bin/gio-dbus.sh
USER_CLEANUP=/usr/share/os2borgerpc/bin/user-cleanup.bash

# Cleanup if they've run previous versions of this script. Suppress deletion errors.
rm --force /home/$SHADOW/.config/autostart/gio-fix-desktop-file-permissions.desktop

# Script that actually runs gio as the user and kills the dbus session it creates to do so
# afterwards
cat << EOF > "$GIO_SCRIPT"
#! /usr/bin/env sh

# gio needs to run as the user + dbus-launch, we have this script to create it and kill it afterwards
export \$(dbus-launch)
DBUS_PROCESS=\$\$

# Determine the name of the user desktop directory. This can be done simply
# because this file is run as user during the execution of GIO_LAUNCHER
# which already makes sure that /home/user/.config/user-dirs.dirs exists
DESKTOP=\$(xdg-user-dir DESKTOP)

for FILE in \$DESKTOP/*.desktop; do
  gio set "\$FILE" metadata::trusted true
done

kill \$DBUS_PROCESS
EOF

# Script to activate programs on the desktop
# (equivalent to right-click -> Allow Launching)
cat << EOF > "$GIO_LAUNCHER"
#! /usr/bin/env sh

# Determine the name of the user desktop directory. This is done via xdg-user-dir,
# which checks the /home/user/.config/user-dirs.dirs file. To ensure this file exists,
# we run xdg-user-dirs-update, which generates it based on the environment variable
# LANG. This variable is empty in lightdm so we first export it
# based on the value stored in /etc/default/locale
export \$(grep LANG= /etc/default/locale | tr -d '"')
runuser -u user xdg-user-dirs-update
DESKTOP=\$(runuser -u $USERNAME xdg-user-dir DESKTOP)

# Gio expects the user to own the file so temporarily change that
for FILE in \$DESKTOP/*.desktop; do
  chown $USERNAME:$USERNAME \$FILE
done

su --login user --command $GIO_SCRIPT

# Now set the permissions back to their restricted form
for FILE in \$DESKTOP/*.desktop; do
  chown root:$USERNAME "\$FILE"
  # In order for gio changes to take effect, it is necessary to update the file time stamp
  # This can be done with many commands such as chmod or simply touch
  # However, in some cases the files might not have execute permission so we add it with chmod
  chmod ug+x "\$FILE"
done
EOF

chmod u+x "$GIO_LAUNCHER"
chmod +x "$GIO_SCRIPT"

# Cleanup if there are previous entries of the gio fix script in the file
sed --in-place "\@$GIO_LAUNCHER@d" $USER_CLEANUP

# Make sure to insert this line before the desktop is made immutable
# in case desktop_toggle_writable has already been run
sed -i "/chown -R \$USERNAME:\$USERNAME \/home\/\$USERNAME/a $GIO_LAUNCHER" $USER_CLEANUP

# Remove user write access to desktop
export "$(grep LANG= /etc/default/locale | tr -d '"')"
runuser -u $USERNAME xdg-user-dirs-update
DESKTOP="$(runuser -u $USERNAME xdg-user-dir DESKTOP)"
USER_CLEANUP=/usr/share/os2borgerpc/bin/user-cleanup.bash
COMMENT="# Make the desktop read only to user"

make_desktop_writable() {
	# All of the matched lines are deleted. This function thus serves to undo write access removal
	# shellcheck disable=SC2016
	sed --in-place --expression "/chattr [-+]i/d" --expression "/chown -R root:/d" \
		  --expression "/$COMMENT/d" --expression '/runuser/d' --expression '/export/d' \
		  --expression "/chown \$USERNAME/d" --expression "/.config/d" --expression "/The exact cause/d" \
		  --expression "/The lines below/d" --expression "/login issues/d" $USER_CLEANUP
	chattr -i "$DESKTOP"
}

# Make sure that DESKTOP dir exists under .skjult as otherwise this script will not work correctly
mkdir --parents "/home/.skjult/$(basename "$DESKTOP")"

# Undo write access removal - always do this to prevent adding the same lines multiple times (idempotency)
make_desktop_writable

sed -i "/USERNAME=\"$USERNAME\"/a \
export \$(grep LANG= \/etc\/default\/locale | tr -d \'\"\')\n\
runuser -u $USERNAME xdg-user-dirs-update\n\
DESKTOP=\$(runuser -u $USERNAME xdg-user-dir DESKTOP)\n\
chattr -i \$DESKTOP" $USER_CLEANUP

# Append setting the more restrictive permissions
cat <<- EOF >> $USER_CLEANUP
$COMMENT
chown -R root:\$USERNAME \$DESKTOP
chattr +i \$DESKTOP
# The exact cause is unclear, but xdg-user-dir will rarely fail in such
# a way that DESKTOP=/home/user. The lines below prevent this error
# from causing login issues.
chattr -i /home/user/
chown \$USERNAME:\$USERNAME /home/\$USERNAME
chown -R \$USERNAME:\$USERNAME /home/\$USERNAME/.config /home/\$USERNAME/.local
EOF

# Set "user" as the default user
USER=user
FILE=/var/lib/lightdm/.cache/unity-greeter/state

cat <<- EOF > "$FILE"
[greeter]
last-user=$USER
EOF
chattr +i $FILE

# Enable running scripts at login
LIGHTDM_DIR="/etc/lightdm"
FILE_PATH="$LIGHTDM_DIR""/lightdm.conf"
SCRIPT_DIR="$LIGHTDM_DIR""/greeter-setup-scripts"

sed --in-place "/greeter-setup-script=*/d" $FILE_PATH

mkdir --parents "$SCRIPT_DIR"

cat << EOF > "$LIGHTDM_DIR"/greeter_setup_script.sh
#!/bin/sh
if [ \$(ls -A "$SCRIPT_DIR"/) ]; then
    for file in "$SCRIPT_DIR"/*
    do
        bash "\$file" &
    done
fi
EOF

echo "greeter-setup-script=/bin/sh /etc/lightdm/greeter_setup_script.sh" >> $FILE_PATH

# Disable the run prompt
POLICY_PATH="org/gnome/desktop/wm/keybindings"
POLICY="panel-run-dialog"
POLICY_VALUE_NO_BIND="@as []"

POLICY_FILE="/etc/dconf/db/os2borgerpc.d/05-run-prompt"
POLICY_LOCK_FILE="/etc/dconf/db/os2borgerpc.d/locks/05-run-prompt"

cat > "$POLICY_FILE" <<-END
[$POLICY_PATH]
$POLICY=$POLICY_VALUE_NO_BIND
END

touch "$(dirname "$POLICY_FILE")"

cat > "$POLICY_LOCK_FILE" <<-END
/$POLICY_PATH/$POLICY
END

# Fix /etc/hosts
HOSTS=/etc/hosts

# Don't add 127.0.1.1 if it isn't already there
if grep --quiet 127.0.1.1 $HOSTS; then
  sed --in-place /127.0.1.1/d $HOSTS
  sed --in-place "2i 127.0.1.1	$(hostname)" $HOSTS
fi

# Disable suspend from the menu unless they've explicitly set their own policy for this
POLICY="/etc/polkit-1/localauthority/90-mandatory.d/10-os2borgerpc-no-user-shutdown.pkla"
if [ ! -f $POLICY ]; then
  if [ ! -d "$(dirname "$POLICY")" ]; then
    mkdir -p "$(dirname "$POLICY")"
  fi
  cat > "$POLICY" <<END
[Restrict system shutdown]
Identity=unix-user:user;unix-user:lightdm
Action=org.freedesktop.login1.hibernate*;org.freedesktop.login1.suspend*;org.freedesktop.login1.lock-sessions
ResultAny=no
ResultActive=no
ResultInactive=no
END
fi

# Enable universal access menu by default
POLICY_PATH="org/gnome/desktop/a11y"
POLICY="always-show-universal-access-status"
POLICY_VALUE="true"

POLICY_FILE="/etc/dconf/db/os2borgerpc.d/00-accessibility"
POLICY_LOCK_FILE="/etc/dconf/db/os2borgerpc.d/locks/accessibility"

cat > "$POLICY_FILE" <<-END
[$POLICY_PATH]
$POLICY=$POLICY_VALUE
END

touch "$(dirname "$POLICY_FILE")"

cat > "$POLICY_LOCK_FILE" <<-END
/$POLICY_PATH/$POLICY
END

# Add the new firefox policies, if they don't have them
NEW_FIREFOX_POLICY_FILE=/etc/firefox/policies/policies.json
if [ ! -f $NEW_FIREFOX_POLICY_FILE ]; then
  STARTPAGE="https://borger.dk"
  ADDITIONAL_PAGES=""
else
  STARTPAGE=$(grep "URL" $NEW_FIREFOX_POLICY_FILE | cut --delimiter ' ' --fields 8)
  STARTPAGE=${STARTPAGE:1:-2}
  ADDITIONAL_PAGES=$(grep "Additional" $NEW_FIREFOX_POLICY_FILE | cut --delimiter '[' --fields 2)
  ADDITIONAL_PAGES=${ADDITIONAL_PAGES:1:-3}
  ADDITIONAL_PAGES=${ADDITIONAL_PAGES//\", \"/|}
fi

POLICY_DIR="/etc/firefox/policies"
POLICY_FILE="policies.json"

mkdir -p "$POLICY_DIR";

PAGES_STRING=""
if [ -n "$ADDITIONAL_PAGES" ]; then
  IFS='|' read -ra PAGES_ARRAY <<< "$ADDITIONAL_PAGES"

  PAGES_STRING="\"Additional\": [" # start array-string
  for PAGE in "${PAGES_ARRAY[@]}"
  do
      PAGES_STRING+="\"$PAGE\","
  done
  PAGES_STRING=${PAGES_STRING::-1} # remove comma at end of list
  PAGES_STRING+="]," # finish array-string
fi

cat << EOF > "$POLICY_DIR/$POLICY_FILE"
{
  "policies": {
    "Homepage": {
      "URL": "$STARTPAGE",
      "Locked": true,
      $PAGES_STRING
      "StartPage": "homepage"
    },
    "DisableFirefoxAccounts": true,
    "InstallAddonsPermission": {
      "Default": false
    },
    "OverrideFirstRunPage": "",
    "OverridePostUpdatePage": "",
    "Preferences": {
      "datareporting.policy.dataSubmissionPolicyBypassNotification": true
    },
    "BlockAboutAddons": true,
	  "BlockAboutConfig": true,
	  "BlockAboutProfiles": true,
	  "BlockAboutSupport": true,
    "DownloadDirectory": "/home/user/Hentet",
    "PromptForDownloadLocation": false,
	  "DisableFirefoxAccounts": true,
	  "DisableFormHistory": true,
	  "DisableProfileImport": true,
    "OfferToSaveLogins": false,
	  "OfferToSaveLoginsDefault": false,
	  "PasswordManagerEnabled": false,
	  "SanitizeOnShutdown": {
      "Cache": true,
      "Cookies": true,
      "Downloads": false,
      "FormData": true,
      "History": true,
      "Sessions": true,
      "SiteSettings": true,
      "OfflineApps": true,
      "Locked": true
    },
    "SearchEngines": {
      "PreventInstalls": true
    },
    "EnableTrackingProtection": {
      "Value": true,
      "Locked": true,
      "Cryptomining": true,
      "Fingerprinting": true
    },
    "DisableDeveloperTools": true
  }
}

EOF

# Attempting to remove policy from former standard location.
OLD_POLICY="/usr/lib/firefox/distribution/policies.json"
if [ -f "$OLD_POLICY" ]; then
    rm -f "$OLD_POLICY"
fi

# Disable libreoffice Tip of the day
MS_FILE_FORMAT=False
if grep --quiet "MS Word 2007" /home/.skjult/.config/libreoffice/4/user/registrymodifications.xcu; then
  MS_FILE_FORMAT=True
fi
CONFIG_DIR="/home/.skjult/.config/libreoffice/4/user/"
FILE_PATH=$CONFIG_DIR"registrymodifications.xcu"

mkdir -p $CONFIG_DIR

rm -f $FILE_PATH

cat << EOF >> $FILE_PATH
<?xml version="1.0" encoding="UTF-8"?>
<oor:items xmlns:oor="http://openoffice.org/2001/registry" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
EOF

cat << EOF >> $FILE_PATH
<item oor:path="/org.openoffice.Office.Common/Misc"><prop oor:name="ShowTipOfTheDay" oor:op="fuse"><value>false</value></prop></item>
<item oor:path="/org.openoffice.Setup/Product"><prop oor:name="ooSetupLastVersion" oor:op="fuse"><value>30.0</value></prop></item>
EOF

if [ "$MS_FILE_FORMAT" == "True" ]; then
cat << EOF >> $FILE_PATH
<item oor:path="/org.openoffice.Setup/Office/Factories/org.openoffice.Setup:Factory['com.sun.star.text.TextDocument']"><prop oor:name="ooSetupFactoryDefaultFilter" oor:op="fuse"><value>MS Word 2007 XML</value></prop></item>
<item oor:path="/org.openoffice.Setup/Office/Factories/org.openoffice.Setup:Factory['com.sun.star.sheet.SpreadsheetDocument']"><prop oor:name="ooSetupFactoryDefaultFilter" oor:op="fuse"><value>Calc MS Excel 2007 XML</value></prop></item>
<item oor:path="/org.openoffice.Setup/Office/Factories/org.openoffice.Setup:Factory['com.sun.star.presentation.PresentationDocument']"><prop oor:name="ooSetupFactoryDefaultFilter" oor:op="fuse"><value>Impress MS PowerPoint 2007 XML</value></prop></item>
EOF
fi

printf "</oor:items>"  >> $FILE_PATH

# Enable automatic security updates if they have never run the related script before
UNATTENDED_UPGRADES_FILE="/etc/apt/apt.conf.d/90os2borgerpc-automatic-upgrades"
if [ ! -f "$UNATTENDED_UPGRADES_FILE" ]; then
  export DEBIAN_FRONTEND=noninteractive
  CONF="/etc/apt/apt.conf.d/90os2borgerpc-automatic-upgrades"
  if ! dpkg -s unattended-upgrades > /dev/null 2>&1; then
    apt-get -y install unattended-upgrades
  fi
  cat > "$CONF" <<-END
APT::Periodic::Enable "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Update-Package-Lists "1";
END
  cat >> "$CONF" <<-END
#clear Unattended-Upgrade::Allowed-Origins;
Unattended-Upgrade::Allowed-Origins {
	"\${distro_id}:\${distro_codename}-security"
	; "\${distro_id}ESM:\${distro_codename}"
	; "Google LLC:stable"
END
  cat >> "$CONF" <<-END
};
END
fi

dconf update

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

# Update chrome policies
# This is done without running chrome_install to reduce the possible points of failure
CHROME_POLICY="/etc/opt/chrome/policies/managed/os2borgerpc-defaults.json"
if [ -f "$CHROME_POLICY" ]; then
  rm --force /etc/opt/chrome/policies/managed/os2borgerpc-default-hp.json /etc/opt/chrome/policies/managed/os2borgerpc-login.json
  cat > "$CHROME_POLICY" <<- END
{
    "AutofillAddressEnabled": false,
    "AutofillCreditCardEnabled": false,
    "BrowserAddPersonEnabled": false,
    "BrowserGuestModeEnabled": true,
    "BrowserSignin": 0,
    "BrowsingDataLifetime": [
      {
        "data_types": [
          "autofill",
          "browsing_history",
          "cached_images_and_files",
          "download_history",
          "hosted_app_data",
          "site_settings"
        ],
        "time_to_live_in_hours": 1
      }
    ],
    "DefaultBrowserSettingEnabled": false,
    "DeveloperToolsAvailability": 2,
    "EnableMediaRouter": false,
    "ExtensionInstallBlocklist": [
      "*"
    ],
    "ForceEphemeralProfiles": true,
    "MetricsReportingEnabled": false,
    "PasswordManagerEnabled": false,
    "PaymentMethodQueryEnabled": false,
    "URLBlocklist": [
      "chrome://accessibility",
      "chrome://extensions",
      "chrome://flags"
    ]
}
END
fi

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
