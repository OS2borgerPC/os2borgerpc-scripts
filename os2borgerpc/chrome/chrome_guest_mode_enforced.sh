#!/bin/bash

set -x

ACTIVATE="$1"
POLICY="/etc/opt/chrome/policies/managed/os2borgerpc-guestmode-enforced.json"

if [ "$ACTIVATE" = "True" ]; then

  cat << EOF > "$POLICY"
{
  "BrowserGuestModeEnforced": true
}
EOF

else
  rm -f "$POLICY"
fi