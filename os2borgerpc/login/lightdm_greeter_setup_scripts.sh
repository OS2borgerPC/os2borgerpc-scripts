#!/bin/sh

# DESCRIPTION
# This script will enable running scripts when lightdm reaches greeter setup
# All scripts in the SCRIPT_DIR will be run.
#
# PARAMETERS
# 1. Checkbox. If checked empties the SCRIPT_DIR

CLEANUP_LIGHTDM_GREETER_SETUP_SCRIPTS_DIR=$1

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

LIGHTDM_DIR="/etc/lightdm"
LIGHTDM_CONF="$LIGHTDM_DIR/lightdm.conf"
SCRIPT_DIR="$LIGHTDM_DIR/greeter-setup-scripts"

mkdir --parents "$SCRIPT_DIR"

# This script executes all scripts in SCRIPT_DIR when called
GREETER_SETUP_SCRIPT="$LIGHTDM_DIR/greeter_setup_script.sh"
cat << EOF > $GREETER_SETUP_SCRIPT
#!/bin/sh
greeter_setup_scripts=\$(find $SCRIPT_DIR -mindepth 1)
for file in \$greeter_setup_scripts
do
    ./"\$file" &
done
EOF

# Set the correct permissions
chmod 700 $GREETER_SETUP_SCRIPT
chmod --recursive 700 "$SCRIPT_DIR"

if [ "$CLEANUP_LIGHTDM_GREETER_SETUP_SCRIPTS_DIR" = "True" ]; then
    rm --force "$SCRIPT_DIR"/*
    echo Emptied directory "$SCRIPT_DIR"
fi

# Idempotency: First delete any line with session-cleanup-script
sed --in-place "/greeter-setup-script=*/d" $LIGHTDM_CONF
echo "greeter-setup-script=$GREETER_SETUP_SCRIPT" >> $LIGHTDM_CONF

echo "Enabled running of scripts in $SCRIPT_DIR on lightdm greeter setup"
