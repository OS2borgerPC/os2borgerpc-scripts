#!/bin/sh

# DESCRIPTION
# Requires "lightdm_greeter_setup_scripts" to be run and enabled to take effect.
#
# This script will install numlockx and enable it when the pc reaches the login screen.
# Any changes made requires a reboot to take effect.
#
# PARAMETERS
# 1. Checkbox. Enables or disables numlock

set -ex

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

NUMLOCK_ON=$1

SCRIPT_DIR="/etc/lightdm/greeter-setup-scripts"
SCRIPT="$SCRIPT_DIR/enable_numlock.sh"
POLICY="/etc/xdg/autostart/os2borgerpc-numlock.desktop"
# Stop Debconf from doing anything
export DEBIAN_FRONTEND=noninteractive

if [ "$NUMLOCK_ON" = "True" ]; then
    if [ ! -f "/usr/bin/numlockx" ]; then
        apt-get update -qq > /dev/null
        apt-get -yqq install numlockx
    fi

    mkdir -p "$SCRIPT_DIR"

    cat << EOF > "$SCRIPT"
#!/bin/sh

numlockx on
EOF
    # Set the correct permissions on the file, so it can be executed by lightdm
    chmod 700 "$SCRIPT"
    echo "Added the script: $SCRIPT"


    cat > "$POLICY" <<END
[Desktop Entry]
Type=Application
Name=OS2borgerPC - Set NumLock state
Name[da]=OS2borgerPC - Sæt NumLock-tilstand
Exec=/usr/bin/numlockx on
Terminal=False
NoDisplay=true
END
    echo "Added the numlock policy as: $POLICY"

else
    if [ -f "/usr/bin/numlockx" ]; then
        apt-get remove -yqq numlockx
    fi
    rm -f "$POLICY" "$SCRIPT"
    echo "Removed $POLICY, $SCRIPT and numlockx"
fi
