#!/bin/sh

# DESCRIPTION
# This script will enable running scripts when lightdm reaches greeter-setup
# All scripts in the SCRIPT_DIR will be run.
#
# PARAMETERS
# 1. Checkbox. Enables or disables the whole running of scripts at greeter-setup
# 2. Checkbox. If checked empties the SCRIPT_DIR

LIGHTDM_DIR="/etc/lightdm"
FILE_PATH="$LIGHTDM_DIR""/lightdm.conf"
SCRIPT_DIR="$LIGHTDM_DIR""/greeter-setup-scripts"

sed -i "/greeter-setup-script=*/d" $FILE_PATH

if [ "$2" = "True" ]; then
    rm -r "$SCRIPT_DIR"
    echo Emptied directory "$SCRIPT_DIR"
fi

mkdir -p "$SCRIPT_DIR"

if [ "$1" != "True" ]; then
    echo Disabled running of scripts on lightdm greeter-setup
    exit 0
fi

# This script executes all scripts in SCRIPT_DIR when called
cat << EOF > "$LIGHTDM_DIR"/greeter_setup_script.sh
#!/bin/sh
if [ \$(ls -A "$SCRIPT_DIR"/) ]; then
    for file in "$SCRIPT_DIR"/*
    do
        sh "\$file"
    done
fi
EOF

echo "greeter-setup-script=/bin/sh /etc/lightdm/greeter_setup_script.sh" >> $FILE_PATH

echo "Enabled running of scripts in $SCRIPT_DIR on lightdm greeter-setup"
