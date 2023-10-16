#! /usr/bin/env sh

SET_KERNEL_VERSION_TO_X="$1"
HOLD_KERNEL_VERSION="$2"
KERNEL_VERSION="5.15.0-84-generic"  # Make this script general purpose by making this a parameter

GRUB_CONFIG="/etc/default/grub"

set -x

echo "The currently active kernel is:"
uname -a

echo "Listing available kernels:"
dpkg -l | grep ^ii | grep --invert-match linux-image-generic | grep linux-image

echo "Show relevant setting before changing it:"
grep "GRUB_DEFAULT=" $GRUB_CONFIG

if [ "$SET_KERNEL_VERSION_TO_X" = "True" ]; then
  if dpkg -l | grep ^ii | grep --quiet "$KERNEL_VERSION"; then  # Only set the kernel to this version if its installed on the system
    # This 1 below assumes "Advanced options" is the second item in the list (it's zero indexed)
    # The default language of our GRUB appears to be Danish in 20.04 and English in 22.04, and this affects what the
    # menu entries are called, so using indexes works regardless of locale
    sed --in-place "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=\"1>Ubuntu, med Linux $KERNEL_VERSION\"/" $GRUB_CONFIG

  else
    echo "It appears the computer doesn't have the kernel $KERNEL_VERSION available? Exiting without making changes."
    exit 1
  fi
else
  echo "Resetting the auto-selected kernel to be the system default (ie. the one most recent version available)."
  sed --in-place "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=0/" $GRUB_CONFIG
fi

echo "Show full GRUB config after:"
cat $GRUB_CONFIG

# Now update GRUB with the new settings
update-grub

if [ "$HOLD_KERNEL_VERSION" = "True" ]; then
  # Also make apt hold the relevant packages for the kernel so it isn't automatically deleted during future updates
  apt-mark hold linux-image-$KERNEL_VERSION linux-modules-extra-$KERNEL_VERSION
else
  apt-mark unhold linux-image-$KERNEL_VERSION linux-modules-extra-$KERNEL_VERSION
fi
