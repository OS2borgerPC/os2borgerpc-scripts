#!/bin/bash

set -x

SSID="$1"
IFNAME="$2"
KEYMGMT="$3"
AUTHALG="$4"
EAP="$5"
PHASE2AUTH="$6"
USERNAME="$7"
PASSWORD="$8"

# Cleanup earlier connection attempts
nmcli connection delete "$SSID"

# Create network configuration
nmcli connection add \
con-name "$SSID" \
type wifi \
ifname "$IFNAME" \
ssid "$SSID" \
wifi-sec.key-mgmt "$KEYMGMT" \
wifi-sec.auth-alg "$AUTHALG" \
802-1x.eap "$EAP" \
802-1x.phase2-auth "$PHASE2AUTH" \
802-1x.identity "$USERNAME" \
802-1x.password "$PASSWORD"

# Connect to network
nmcli connection up "$SSID"