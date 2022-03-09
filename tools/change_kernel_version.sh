#! /usr/bin/env sh

# This script is related to:
# https://ubuntu.com/security/CVE-2022-0847
# https://dirtypipe.cm4all.com/
# Specifically the current major version of the linux kernel is 5,
# and for minor versions of that above 7 it installs and switches to
# the kernel specified in VERSION_TO_INSTALL
# ...which should be unaffected by exploit.
#
# The script takes zero arguments.

set -x

VERSION_TO_INSTALL=5.4.0-99-generic
export DEBIAN_FRONTEND=noninteractive

CURRENT_KERNEL_MINOR_VERSION=$(uname --kernel-release | cut --delimiter '.' --fields 2)

# Don't change kernel versions older than when the bug was introduced
if [ "$CURRENT_KERNEL_MINOR_VERSION" -gt 7 ]; then

  apt-get --assume-yes update
  apt-get install --assume-yes linux-image-$VERSION_TO_INSTALL linux-headers-$VERSION_TO_INSTALL

  # if grub_set_password.py was run we need special handling to be able to change default grub entry
  # It's not run by default on kiosk currently, but it is in borgerpc
  if grep --quiet "superuser" /etc/grub.d/40_custom; then
    GRUB_SET_PASSWORD=1
  fi

  # Deactivate a couple of files preventing us from changing the default grub entry
  if [ -n "$GRUB_SET_PASSWORD" ]; then
    cd /etc/grub.d/ || exit 1
    mv 40_custom 10_linux /tmp/
    mv 10_linux.orig 10_linux
    # It's not picked up by update-grub currently, maybe it needs executable rights, or read rights
    # for world?!
    chmod 766 10_linux
  fi

  #sed --in-place --regexp-extended "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=\"Ubuntu, med Linux $VERSION_TO_INSTALL\"/" /etc/default/grub
  PREEXISTING_GRUB_DEFAULT=$(grep -r 'GRUB_DEFAULT' /etc/default/grub | cut --delimiter '=' --fields 2)
  sed --in-place --regexp-extended "s@GRUB_DEFAULT=.*@GRUB_DEFAULT=\"Avancerede indstillinger for Ubuntu>Ubuntu, med Linux $VERSION_TO_INSTALL\"@" /etc/default/grub

  #grub-editenv - set saved_entry="Ubuntu, med Linux $VERSION_TO_INSTALL"
  update-grub

  # RESTORE FILES TO HOW THEY WERE

  # Restore the files preventing us from changing the default grub entry
  # for the next "update-grub" run
  if [ -n "$GRUB_SET_PASSWORD" ]; then
    mv 10_linux 10_linux.orig
    mv /tmp/40_custom /tmp/10_linux .
    # Restore permissions to what they were
    chmod 600 10_linux.orig
  fi
  # Restore default grub entry for next update-grub run
  sed --in-place "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=$PREEXISTING_GRUB_DEFAULT/" /etc/default/grub
fi
