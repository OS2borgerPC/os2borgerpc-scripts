#! /usr/bin/env sh

set -ex

ENABLE="$1"

CONFIG="/etc/default/grub"
DEFAULT_VALUE="quiet splash" # This is the default for Ubuntu 20.04 and 22.04, at least
REBOOT_COUNTER="/etc/os2borgerpc/flicker-counter.txt"
MAXIMUM_CONSECUTIVE_REBOOTS=4
SCRIPT_DIR="/etc/lightdm/greeter-setup-scripts"
SCRIPT="$SCRIPT_DIR/handle_display_bug.sh"

echo "WARNING: This script changes how the machine boots, and as such it may make it unable to do so, if the settings cause issues."

# If run with "False": Reset the value to its default. Please update this default in this script if it changes in new versions of Ubuntu.
if [ "$ENABLE" = "False" ]; then
  sed --in-place "s/\(GRUB_CMDLINE_LINUX_DEFAULT=\"\).*/\1$DEFAULT_VALUE\"/" $CONFIG
  rm $SCRIPT $REBOOT_COUNTER
else
  KERNEL_PARAMETERS="drm.debug=0xe log_buf_len=4M"
  if ! grep "$KERNEL_PARAMETERS" $CONFIG; then
    sed --in-place "s/\(GRUB_CMDLINE_LINUX_DEFAULT=\"$DEFAULT_VALUE\)/\1 $KERNEL_PARAMETERS/" $CONFIG
  else
    echo "Warning: The specified kernel parameters seem to already be set?"
  fi

  # Set the initial state for the counter
  echo "0" > $REBOOT_COUNTER

  cat << EOF > $SCRIPT
#! /usr/bin/env sh

# This script attempts to detect a flicker error:
# 1. If it detects flicker it increments a counter and reboots if the counter is less than $MAXIMUM_CONSECUTIVE_REBOOTS
# 2. If it does not detect flicker it resets the counter to zero and nothing else.
# This is to prevent infinitely looping reboots in case Intel changes the log output so the relevant line is never there

if ! dmesg | grep --quiet "HDMI infoframe: Source Product Description"; then
  COUNT=\$(cat $REBOOT_COUNTER)
  COUNT=\$((COUNT+1))
  echo \$COUNT > $REBOOT_COUNTER
  if [ \$COUNT -le $MAXIMUM_CONSECUTIVE_REBOOTS ]; then
    reboot
  fi
else
  # If it boots correctly, reset the counter
  echo "0" > $REBOOT_COUNTER
fi
EOF

chmod u+x $SCRIPT

fi

echo "Consider manually checking if the contents of $CONFIG look correct after the change:"
cat $CONFIG

echo "If the config above looks wrong, please don't reboot the machine, but instead rerun this script with the correct argument, or with \"False\" to reset the boot line to its default."

echo "About to update the GRUB configuration to make it use the new boot options, including the updated kernel parameters."
update-grub

echo "This script takes effect only after a restart. Before restarting we highly recommend removing or setting the password for GRUB, because this will be necessary for manual recovery."
