#! /usr/bin/env sh
#
# Changes monitor power saving.
# A special use case for this is as a fix for touchscreens that refuse to
# wake up on touch.
#
# Arguments:
# 1: ACTIVATE: 'True' turns monitor power saving on. False turns it 'off'.
#
# Author: mfm@magenta.dk

set -ex

ACTIVATE=$1

FILE="/home/chrome/.xinitrc"

if [ "$ACTIVATE" = 'True' ]; then
    printf '%s\n' 'Slår automatisk skærmslukning ved inaktivitet TIL'
    sed -i "/xset -dpms/d" "$FILE"
else

    printf '%s\n' 'Slår automatisk skærmslukning ved inaktivitet FRA'

    if ! grep -q "\-dpms" "$FILE"; then
        sed -i "s/\(xset s noblank\)/\1\nxset -dpms/" "$FILE"
    fi
fi
