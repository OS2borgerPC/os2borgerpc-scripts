#!/bin/bash

: << 'COMMENT'
Policy-script developed by Magenta ApS for Aarhus Municipal.
Learn more about Firefox "Policy Names" here:
https://github.com/mozilla/policy-templates/blob/master/README.md
There is only possible to have ONE policy-file, so this script
will have to evolve to be more dynamic if we want to be able to, e.g. 
use the same script accross machines and group policies. 
Author: Heini L. Ovason
COMMENT

set -x

STARTPAGE="$1"
ADDITIONAL_PAGES="$2"

POLICIES_DIR="/etc/firefox/policies"
POLICY="policies.json"

if [ -z "$STARTPAGE" ]; then
  echo "WARNING: Missing <URL> argument. Not able to set Firefox startpage."
  exit 1
fi

PAGES_STRING=""
if [ -n "$ADDITIONAL_PAGES" ]; then
  IFS='|' read -ra PAGES_ARRAY <<< "$ADDITIONAL_PAGES"

  PAGES_STRING="\"Additional\": [" # start array-string
  for PAGE in "${PAGES_ARRAY[@]}"
  do
      PAGES_STRING+="\"$PAGE\","
  done
  PAGES_STRING=${PAGES_STRING::-1} # remove comma at end of list
  PAGES_STRING+="]," # finish array-string
fi

cat << EOF > "$POLICIES_DIR/$POLICY"
{
  "policies": {
    "Homepage": {
      "URL": "$STARTPAGE",
      "Locked": true,
      $PAGES_STRING
      "StartPage": "homepage"
    },
    "OverrideFirstRunPage": "",
    "OverridePostUpdatePage": "",
    "Preferences": {
      "datareporting.policy.dataSubmissionPolicyBypassNotification": true
    }
  }
}

EOF
