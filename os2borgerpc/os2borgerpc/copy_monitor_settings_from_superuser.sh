#! /usr/bin/env sh

SKELETON_USER=".skjult"
SUPERUSER="superuser"

ACTIVATE="$1"

MONITOR_SETTINGS_FILE_SUPERUSER="/home/$SUPERUSER/.config/monitors.xml"
MONITOR_SETTINGS_FILE_SKELETON="/home/$SKELETON_USER/.config/monitors.xml"

mkdir --parents "$(dirname $MONITOR_SETTINGS_FILE_SKELETON)"

if [ "$ACTIVATE" = "True" ]; then
    if [ -f $MONITOR_SETTINGS_FILE_SUPERUSER ]; then
        cp $MONITOR_SETTINGS_FILE_SUPERUSER $MONITOR_SETTINGS_FILE_SKELETON
        echo "Settings updated to reflect superuser's monitor settings. Logout and in again, and the changes should take effect."
    else
        echo "Couldn't find the monitor settings file for superuser. You must first make changes to the monitor settings for superuser before running this script."
        exit 1
    fi
else
    rm --force $MONITOR_SETTINGS_FILE_SKELETON
fi
