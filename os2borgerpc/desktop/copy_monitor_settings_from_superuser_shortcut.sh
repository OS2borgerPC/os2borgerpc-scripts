#! /usr/bin/env sh

ACTIVATE="$1"

SKELETON_USER=".skjult"
SUPERUSER="superuser"
MONITOR_SETTINGS_FILE_SUPERUSER="/home/$SUPERUSER/.config/monitors.xml"
MONITOR_SETTINGS_FILE_SKELETON="/home/$SKELETON_USER/.config/monitors.xml"
MONITOR_SCRIPT="/usr/share/os2borgerpc/bin/monitor-settings-superuser-copy.sh"
MONITOR_SUDOERS_SCRIPT="/etc/sudoers.d/monitor-script-nopasswd"

# Determine the name of the user desktop directory. This is done via xdg-user-dir,
# which checks the /home/user/.config/user-dirs.dirs file. To ensure this file exists,
# we run xdg-user-dirs-update, which generates it based on the environment variable
# LANG. This variable is empty in lightdm so we first export it
# based on the value stored in /etc/default/locale
export "$(grep LANG= /etc/default/locale | tr -d '"')"
runuser -u $SUPERUSER xdg-user-dirs-update
DESKTOP=$(basename "$(runuser -u $SUPERUSER xdg-user-dir DESKTOP)")

MONITOR_SCRIPT_DESKTOP_FILE="/home/superuser/$DESKTOP/os2borgerpc-monitor-settings-superuser-copy.desktop"

set -x

mkdir --parents "$(dirname $MONITOR_SETTINGS_FILE_SKELETON)"

if [ "$ACTIVATE" = "True" ]; then
cat << EOF > $MONITOR_SCRIPT
#! /usr/bin/env sh

# Support three different languages
MSG_SUCCESS_EN="Monitor settings updated to reflect superuser's. Logout and in again, and the changes should take effect. Press Enter."
MSG_SUCCESS_DA="Skærmindstillingerne er opdateret til at matche superusers. Logud og ind igen, og derefter burde ændringerne tage effekt. Tryk Enter."
MSG_SUCCESS_SV="Skärminställningarna har uppdaterats för att matcha superuser. Logga ut och in igen, och sedan bör ändringarna träda i kraft. Tryck Enter."
MSG_ERROR_EN="Couldn't find the monitor settings file for superuser. You must first make changes to the monitor settings for superuser before running this script. Press Enter."
MSG_ERROR_DA="Kunne ikke finde skærmindstillingsfilen for superuser. Inden kørsel af dette script skal du først lave ændringer i skærmindstillingerne for superuser. Tryk Enter."
MSG_ERROR_SV="Kunde inte hitta skärminställningsfil för superuser. Innan du kör det här skriptet måste du först göra ändringar i skärminställningarna för superuser. Tryck Enter."

if echo \$LANG | grep --quiet sv; then
    MSG_SUCCESS=\$MSG_SUCCESS_SV
    MSG_ERROR=\$MSG_ERROR_SV
elif echo \$LANG | grep --quiet da; then
    MSG_SUCCESS=\$MSG_SUCCESS_DA
    MSG_ERROR=\$MSG_ERROR_DA
else
    MSG_SUCCESS=\$MSG_SUCCESS_EN
    MSG_ERROR=\$MSG_ERROR_EN
fi

if [ -f $MONITOR_SETTINGS_FILE_SUPERUSER ]; then
    sudo cp $MONITOR_SETTINGS_FILE_SUPERUSER $MONITOR_SETTINGS_FILE_SKELETON
    echo "\$MSG_SUCCESS"
else
    echo "\$MSG_ERROR"
fi
# Press enter to continue logic, so the user can see the echo message. Considered notify-send instead, but it cuts off the message.
# Zenity could be an alternative, but we need sudo from the terminal anyway (unless we add the script to sudoers with no password), soooo.
read _
EOF

cat << EOF > "$MONITOR_SCRIPT_DESKTOP_FILE"
[Desktop Entry]
Name=Copy monitor settings to user
Name[da]=Kopier skærmindstillinger til Borger
Name[sv]=Kopiera skärminställningar till Medborgar
Type=Application
Terminal=true
Icon=preferences-desktop-display
Exec=$MONITOR_SCRIPT
EOF

runuser -u $SUPERUSER dbus-launch gio set "$MONITOR_SCRIPT_DESKTOP_FILE" metadata::trusted true

cat << EOF > $MONITOR_SUDOERS_SCRIPT
$SUPERUSER ALL = (root) NOPASSWD: $MONITOR_SCRIPT
EOF

chown superuser:superuser "$MONITOR_SCRIPT" "$MONITOR_SCRIPT_DESKTOP_FILE"
chmod 500 $MONITOR_SCRIPT
# This is partially done to update the timestamp of the desktop file file so gio realizes its changed. We've tried touch for this, but sometimes, strangely,
# that hasn't been enough
chmod 500 "$MONITOR_SCRIPT_DESKTOP_FILE"
chmod 440 $MONITOR_SUDOERS_SCRIPT
else
    rm --force "$MONITOR_SETTINGS_FILE_SKELETON" "$MONITOR_SCRIPT" "$MONITOR_SCRIPT_DESKTOP_FILE" "$MONITOR_SUDOERS_SCRIPT"
fi
