#! /usr/bin/env sh

# Change the automatic login timeout. Default is 15 seconds.

# Author: mfm@magenta.dk

# Needs to be an integer
NEW_TIMEOUT_IN_SECONDS=$1

sed -i "s/\(autologin-user-timeout=\).*/\1$NEW_TIMEOUT_IN_SECONDS/" /etc/lightdm/lightdm.conf
