#! /usr/bin/env sh

echo "Print info about the i915 (intel video driver) module:"
modinfo i915

echo "Find all instances of modules called i915* under /lib/modules (in case there's more than one):"
find /lib/modules -iname "i915*"

echo "List devices and their drivers"
ubuntu-drivers devices
