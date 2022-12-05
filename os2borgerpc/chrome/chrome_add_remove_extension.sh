#! /bin/bash

# Ref: https://chromeenterprise.google/policies/#ExtensionSettings

# This script can:
# 1. Create an ExtensionSettings policy if none exists.
# 2. Adds/remove a list(1..*) of Chrome Extensions to/from the ExtensionSettings file.
# 3. Remove the ExtensionSettings policy.

# Authors: Heini Leander Ovason

set -x

ACTIVATE=$1
EXTENSIONS_ARRAY=$2

POLICIES_DIR="/etc/opt/chrome/policies/managed"
POLICY_FILE="os2borgerpc-extension-settings.json"

if [ "$ACTIVATE" = 'True' ]; then

  if [ ! -d "$(dirname "$POLICY_FILE")" ]; then
    mkdir --parents "$(dirname "$POLICY_FILE")"
  fi

  EXTENSIONS_DICT=""
  if [ -n "$EXTENSIONS_ARRAY" ]; then
    IFS=',' read -ra EXTENSIONS_ARRAY <<< "$EXTENSIONS_ARRAY"

    for EXTENSION in "${EXTENSIONS_ARRAY[@]}"
    do
      DICT_TEMPLATE="\"$EXTENSION\": {
      \"installation_mode\": \"force_installed\",
      \"toolbar_pin\": \"force_pinned\",
      \"update_url\":
      \"https://clients2.google.com/service/update2/crx\"
    }"
      EXTENSIONS_DICT+="$DICT_TEMPLATE,"
    done
    EXTENSIONS_DICT=${EXTENSIONS_DICT::-1} # remove comma at end
  fi

  cat << EOF > "$POLICIES_DIR/$POLICY_FILE"
{
  "ExtensionSettings": {
    $EXTENSIONS_DICT
  }
}
EOF

else
    rm "$POLICIES_DIR/$POLICY_FILE"
fi
