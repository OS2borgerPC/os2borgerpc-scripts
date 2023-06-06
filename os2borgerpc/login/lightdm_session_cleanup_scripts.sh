#!/bin/sh

# DESCRIPTION
# This script will enable running multiple scripts when lightdm reaches session cleanup
# All scripts in the SCRIPT_DIR will be run.
#
# PARAMETERS
# 1. Checkbox. If checked empties the SCRIPT_DIR

CLEANUP_LIGHTDM_SESSION_CLEANUP_SCRIPTS_DIR=$1

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

LIGHTDM_DIR="/etc/lightdm"
LIGHTDM_CONF="$LIGHTDM_DIR/lightdm.conf"
SCRIPT_DIR="$LIGHTDM_DIR/session-cleanup-scripts"

mkdir --parents "$SCRIPT_DIR"

# This script executes all scripts in SCRIPT_DIR when called
SESSION_CLEANUP_SCRIPT="$LIGHTDM_DIR/session_cleanup_script.sh"
cat << EOF > $SESSION_CLEANUP_SCRIPT
#! /bin/sh

# ALWAYS run user-cleanup.bash
/usr/share/os2borgerpc/bin/user-cleanup.bash

if [ \$(ls -A "$SCRIPT_DIR"/) ]; then
    for file in "$SCRIPT_DIR"/*
    do
        ./"\$file" &
    done
fi
EOF

if [ "$CLEANUP_LIGHTDM_SESSION_CLEANUP_SCRIPTS_DIR" = "True" ]; then
    rm -r "$SCRIPT_DIR"
    echo Emptied directory "$SCRIPT_DIR"
    exit 0
fi

# Set the correct permissions
chown lightdm:lightdm $SESSION_CLEANUP_SCRIPT
chmod u+x $SESSION_CLEANUP_SCRIPT
chown --recursive lightdm:lightdm "$SCRIPT_DIR"
chmod --recursive u+x "$SCRIPT_DIR"

# Idempotency: First delete any line with session-cleanup-script
sed --in-place "/session-cleanup-script=*/d" $LIGHTDM_CONF
echo "session-cleanup-script=$SESSION_CLEANUP_SCRIPT" >> $LIGHTDM_CONF

echo "Enabled running of scripts in $SCRIPT_DIR on lightdm session cleanup"
