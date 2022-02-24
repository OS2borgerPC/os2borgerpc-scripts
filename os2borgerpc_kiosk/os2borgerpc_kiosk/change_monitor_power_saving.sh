#! /usr/bin/env sh
#
# Changes monitor power saving.
# A special usecase for this is as a fix for touchscreens that refuse to 
# wake up on touch.
#
# Arguments:
# false/falsk/no/nej turns monitor power saving off - anything else turns it on
#
# Author: mfm@magenta.dk

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"

FILE="/home/chrome/.xinitrc"

if [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] && \
   [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then
    printf '%s\n' 'Slår automatisk skærmslukning ved inaktivitet TIL'
    sed -i "/xset -dpms/d" "$FILE"
else

    printf '%s\n' 'Slår automatisk skærmslukning ved inaktivitet FRA'

    if ! grep -q "\-dpms" "$FILE"; then
        sed -i "s/\(xset s noblank\)/\1\nxset -dpms/" "$FILE"
    fi
fi
