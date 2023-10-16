#! /usr/bin/env sh

GRUB_MENU_ACCESSIBLE="$1"
WAIT_HOW_LONG="$2"  # set to -1 to wait forever

GRUB_CONFIG="/etc/default/grub"

set -x

echo "Show relevant settings before:"
grep "TIMEOUT_STYLE" $GRUB_CONFIG
grep "GRUB_TIMEOUT=" $GRUB_CONFIG

if [ "$GRUB_MENU_ACCESSIBLE" = "True" ]; then
  sed --in-place "s/GRUB_TIMEOUT_STYLE=hidden/GRUB_TIMEOUT_STYLE=menu/" $GRUB_CONFIG
  sed --in-place "s/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=$WAIT_HOW_LONG/" $GRUB_CONFIG
else
  sed --in-place "s/GRUB_TIMEOUT_STYLE=menu/GRUB_TIMEOUT_STYLE=hidden/" $GRUB_CONFIG
  sed --in-place "s/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/" $GRUB_CONFIG
fi

echo "Show full GRUB config after:"
cat $GRUB_CONFIG

# Now update GRUB's actual configuration with the new settings
update-grub
