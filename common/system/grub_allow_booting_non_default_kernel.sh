#! /usr/bin/env sh

# Handle whether the GRUB entries besides the default options are available without a password prompt
#
# By default all other entries except the first is password protected by our grub_set_password script. Even if
# it's set as default, it will prompt for username and password!
# Therefore we need to set both the "Advanced options" menu + the entry itself to have unrestricted access.
# Still edit and console remain password protected, and the menu style remains hidden and the timeout 0
#
# This script isn't relevant on Kiosk unless you've run grub_set_password on it.

UNRESTRICT_GRUB_ENTRIES_BESIDES_DEFAULT="$1"

GRUB_CONFIG_ENTRIES="/etc/grub.d/10_linux"

set -x

echo "Show the relevant lines before making changes:"
grep "menuentry" $GRUB_CONFIG_ENTRIES

if [ "$UNRESTRICT_GRUB_ENTRIES_BESIDES_DEFAULT" = "True" ]; then
  # Ensure the entry can be selected without a password prompt, by appending "--unrestricted" to the entries

  # Unrestrict "Advanced options"
  # Line to match: echo "submenu '$(gettext_printf "Advanced options for %s" "${OS}" | grub_quote)' \$menuentry_id_option 'gnulinux-advanced-$boot_device_id' {"

  if ! grep --quiet 'echo "submenu.* --unrestricted' $GRUB_CONFIG_ENTRIES; then  # Idempotency check
    sed --in-place --regexp-extended 's/(echo "submenu.*) \{"/\1 --unrestricted \{"/' $GRUB_CONFIG_ENTRIES
  fi

  # Unretrict entries within Advanced options
  # Line to match: echo "menuentry '$(echo "$title" | grub_quote)' ${CLASS} \$menuentry_id_option 'gnulinux-$version-$type-$boot_device_id' {" | sed "s/^/$submenu_indentation/"
  # shellcheck disable=SC2016 # We don't want the $ expanded
  if ! grep --quiet 'menuentry '\''\$(echo "\$title.* --unrestricted' $GRUB_CONFIG_ENTRIES; then  # Idempotency check
    sed --in-place --regexp-extended 's/(menuentry '\''\$\(echo "\$title.*) (\{".*)/\1 --unrestricted \2/' $GRUB_CONFIG_ENTRIES
  fi

else
  # Restore restrictions on selecting anything but the default, by removing "--unrestricted" from the entries

  # Restrict "Advanced options"
  sed --in-place --regexp-extended 's/(echo "submenu.*) --unrestricted \{"/\1 \{"/' $GRUB_CONFIG_ENTRIES

  # Restrict entries within advanced options
  # shellcheck disable=SC2016 # We don't want the $ expanded
  sed --in-place --regexp-extended 's/(menuentry '\''\$\(echo "\$title.*) --unrestricted (\{.*)/\1 \2/' $GRUB_CONFIG_ENTRIES
fi

echo "Show the full, relevant GRUB config file after:"
cat $GRUB_CONFIG_ENTRIES

# Now update GRUB's actual configuration with the new settings
update-grub

echo "Show the full grub.cfg after the update"
cat /boot/grub/grub.cfg
