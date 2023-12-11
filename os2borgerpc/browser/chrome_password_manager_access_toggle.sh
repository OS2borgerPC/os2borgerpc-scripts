#! /usr/bin/env sh

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "This script has not been designed to be run on a Kiosk-machine. Exiting."
  exit 1
fi

ALLOW_PASSWORD_MANAGER="$1"

POLICY_FILE="/etc/opt/chrome/policies/managed/os2borgerpc-defaults.json"
POLICY="PasswordManagerEnabled"

set -x

if [ "$ALLOW_PASSWORD_MANAGER" = "True" ]; then
  sed --in-place "/$POLICY/d" $POLICY_FILE
else
  # Idempotency check
  if ! grep "$POLICY" $POLICY_FILE; then
    sed --in-place "/MetricsReportingEnabled/a\ \ \ \ \"$POLICY\": false," $POLICY_FILE
  fi
fi
