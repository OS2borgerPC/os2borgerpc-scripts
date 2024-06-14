#! /usr/bin/env sh

# Author: Marcus Funch (mfm@magenta.dk)
# License: GPL

ACTIVATE="$1"

SKELETON_USER=".skjult"
SUPERUSER="superuser"
MONITOR_SETTINGS_FILE_SUPERUSER="/home/$SUPERUSER/.config/monitors.xml"
MONITOR_SETTINGS_FILE_SKELETON="/home/$SKELETON_USER/.config/monitors.xml"
MONITOR_SCRIPT="/usr/share/os2borgerpc/bin/monitor-settings-superuser-copy.sh"
MONITOR_SUDOERS_SCRIPT="/etc/sudoers.d/monitor-script-nopasswd"

DESKTOP=$(basename "$(runuser -u $SUPERUSER xdg-user-dir DESKTOP)")

MONITOR_SCRIPT_DESKTOP_FILE="/home/superuser/$DESKTOP/os2borgerpc-monitor-settings-superuser-copy.desktop"

set -x

mkdir --parents "$(dirname $MONITOR_SETTINGS_FILE_SKELETON)"

if [ "$ACTIVATE" = "True" ]; then
cat << EOF > $MONITOR_SCRIPT
#! /usr/bin/env sh

# Support three different languages
MSG_SUCCESS_EN="Monitor settings updated to reflect superuser's. Logout and in again, and the changes should take effect."
MSG_SUCCESS_DA="Skærmindstillingerne er opdateret til at matche superusers. Logud og ind igen, og derefter burde ændringerne tage effekt."
MSG_SUCCESS_SV="Skärminställningarna har uppdaterats för att matcha superuser. Logga ut och in igen, och sedan bör ändringarna träda i kraft."
MSG_ERROR_EN="Couldn't find the monitor settings file for superuser. You must first make changes to the monitor settings for superuser before running this script."
MSG_ERROR_DA="Kunne ikke finde skærmindstillingsfilen for superuser. Inden kørsel af dette script skal du først lave ændringer i skærmindstillingerne for superuser."
MSG_ERROR_SV="Kunde inte hitta skärminställningsfil för superuser. Innan du kör det här skriptet måste du först göra ändringar i skärminställningarna för superuser."

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
    # Really the only command needing root access
    cp $MONITOR_SETTINGS_FILE_SUPERUSER $MONITOR_SETTINGS_FILE_SKELETON
    # Since this is now run as root we can't successfully call zenity directly...
    runuser -u $SUPERUSER -- zenity --info --text "\$MSG_SUCCESS"
else
    runuser -u $SUPERUSER -- zenity --info --text "\$MSG_ERROR"
fi
EOF

cat << EOF > "$MONITOR_SCRIPT_DESKTOP_FILE"
[Desktop Entry]
Name=Copy monitor settings to user
Name[da]=Kopier skærmindstillinger til Borger
Name[sv]=Kopiera skärminställningar till Medborgar
Type=Application
Icon=preferences-desktop-display
Exec=sudo $MONITOR_SCRIPT
EOF

# Make the desktop shortcut launchable
runuser -u $SUPERUSER dbus-launch gio set "$MONITOR_SCRIPT_DESKTOP_FILE" metadata::trusted true

cat << EOF > $MONITOR_SUDOERS_SCRIPT
$SUPERUSER ALL = (root) NOPASSWD: $MONITOR_SCRIPT
EOF

chown superuser:superuser "$MONITOR_SCRIPT" "$MONITOR_SCRIPT_DESKTOP_FILE"
# Regarding the desktop file:
# This is partially done to update the timestamp of the desktop file file so gio realizes its changed. We've tried touch for this, but sometimes, strangely,
# that hasn't been enough
chmod 500 $MONITOR_SCRIPT "$MONITOR_SCRIPT_DESKTOP_FILE"
chmod 440 $MONITOR_SUDOERS_SCRIPT
else
    rm --force "$MONITOR_SETTINGS_FILE_SKELETON" "$MONITOR_SCRIPT" "$MONITOR_SCRIPT_DESKTOP_FILE" "$MONITOR_SUDOERS_SCRIPT"
fi
