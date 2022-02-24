#! /usr/bin/env sh

NEW_URL="$1"

CHROMIUM_SCRIPT='/usr/share/os2borgerpc/bin/start_chromium.sh'
sed --in-place --regexp-extended "s%(IURL=\").*%\1$NEW_URL\"%" $CHROMIUM_SCRIPT
