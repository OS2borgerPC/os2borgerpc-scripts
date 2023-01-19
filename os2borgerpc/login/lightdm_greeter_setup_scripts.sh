#!/bin/sh

# DESCRIPTION
# This script will enable running scripts when lightdm reaches greeter-setup
# All scripts in the SCRIPT_DIR will be run.
#
# PARAMETERS
# 1. Checkbox. Enables or disables the whole running of scripts at greeter-setup
# 2. Checkbox. If checked empties the SCRIPT_DIR

ENABLE_LIGHTDM_GREETER_SETUP_SCRIPTS=$1
CLEANUP_LIGHTDM_GREETER_SETUP_SCRIPTS_DIR=$2

LIGHTDM_DIR="/etc/lightdm"
FILE_PATH="$LIGHTDM_DIR""/lightdm.conf"
SCRIPT_DIR="$LIGHTDM_DIR""/greeter-setup-scripts"

sed --in-place "/greeter-setup-script=*/d" $FILE_PATH

if [ "$CLEANUP_LIGHTDM_GREETER_SETUP_SCRIPTS_DIR" = "True" ]; then
    rm -r "$SCRIPT_DIR"
    echo Emptied directory "$SCRIPT_DIR"
fi

mkdir --parents "$SCRIPT_DIR"

if [ "$ENABLE_LIGHTDM_GREETER_SETUP_SCRIPTS" != "True" ]; then
    echo "Disabled running of scripts on lightdm greeter-setup"
    exit 0
fi

# This script executes all scripts in SCRIPT_DIR when called
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

echo "Enabled running of scripts in $SCRIPT_DIR on lightdm greeter-setup"
