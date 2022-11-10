#!/bin/bash

set -x

ACTIVATE="$1"
POLICY="/etc/opt/chrome/policies/managed/os2borgerpc-block-user-login.json"

if [ "$ACTIVATE" = "True" ]; then

  cat << EOF > "$POLICY"
{
  "BrowserSignin": 0
}
EOF

else
  rm -f "$POLICY"
fi