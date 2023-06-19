#! /usr/bin/env sh

set -x

header() {
  MSG=$1
  printf "\n\n\n%s\n\n\n" "### $MSG ###"
}

text() {
  MSG=$1
  printf "\n%s\n" "### $MSG ###"
}

header "Information about the computer model:"
dmidecode --type 1

header "Info about devices and drivers"
lshw

header "List kernel modules currently loaded (fx. drivers)"
lsmod

header "Info about printers"
lpinfo -v

header "Info about scanners"
scanimage -L


header "=== DRIVER RELATED ==="

text "Show all devices which need drivers, and which packages..." # From $ ubuntu-drivers --help
ubuntu-drivers devices

text "Show all OEM enablement packages which apply to this system" # From $ ubuntu-drivers --help
ubuntu-drivers list-oem

text "Show all driver packages which apply to the current system" # From $ ubuntu-drivers --help
ubuntu-drivers list


header "=== FIRMWARE RELATED ==="

text "Download the latest firmware metadata"
fwupdmgr refresh

text "Get all devices that support firmware updates" # From $ fwupdmgr --help
# yes skips two interactive prompts
yes 'n\nN' | fwupdmgr get-devices

text "Display the available updates for any devices on the system" # From $ fwupdmgr --help
# yes skips two interactive prompts
yes 'n\nN' | fwupdmgr get-updates


header "=== NETWORK RELATED ==="

text "Gather information about network interfaces and their IP adresses"
ip a

text "Gather information about routes / default gateway"
ip route
