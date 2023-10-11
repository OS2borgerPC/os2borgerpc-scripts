#! /usr/bin/env sh

GRUB_MENU_ACCESSIBLE="$1"

set -x

GRUB_CONFIG="/etc/default/grub"

echo "Show full GRUB config before"
cat $GRUB_CONFIG

if [ "$GRUB_MENU_ACCESSIBLE" = "True" ]; then
    sed --in-place "s/GRUB_TIMEOUT_STYLE=hidden/GRUB_TIMEOUT_STYLE=menu/" $GRUB_CONFIG
    sed --in-place "s/GRUB_TIMEOUT=0/GRUB_TIMEOUT=40/" $GRUB_CONFIG
else
    sed --in-place "s/GRUB_TIMEOUT_STYLE=menu/GRUB_TIMEOUT_STYLE=hidden/" $GRUB_CONFIG
    sed --in-place "s/GRUB_TIMEOUT=30/GRUB_TIMEOUT=0/" $GRUB_CONFIG
fi

echo "Show relevant settings after:"
grep "TIMEOUT_STYLE" $GRUB_CONFIG
grep "GRUB_TIMEOUT=" $GRUB_CONFIG

# Now update GRUB with the new settings
update-grub
