#!/bin/sh

# DESCRIPTION
# Requires "lightdm_greeter_setup_scripts" to be run and enabled to take effect.
#
# This script will install numlockx and enable it when the pc reaches the login screen.
# Any changes made requires a reboot to take effect.
#
# PARAMETERS
# 1. Checkbox. Enables or disables the script and unchecked will remove it.

ENABLE_NUMLOCK=$1

SCRIPT_DIR="/etc/lightdm/greeter-setup-scripts"
SCRIPT="$SCRIPT_DIR/enable_numlock.sh"

if [ "$ENABLE_NUMLOCK" = "True" ]; then

    # Removing the older numlock policy to prevent redundancy if the older script was run
    rm --force /etc/xdg/autostart/os2borgerpc-numlock.desktop

    mkdir -p "$SCRIPT_DIR"
    apt-get update -qq
    apt-get install -yqq numlockx
    cat << EOF > "$SCRIPT"
#!/bin/sh

numlockx on
EOF
    echo "Added the script to $SCRIPT"
else
    rm --force "$SCRIPT"
    apt-get remove -yqq numlockx
    echo "Removed the script $SCRIPT"
fi
