#! /usr/bin/env sh
#
# Toggles kiosk and/or incognito mode for OS2borgerPC Kiosk Chromium
# Why incognito?: If kiosk is disabled the browser will begin to remember
# cookies after restart. If you don't want that you can enable incognito.
#
# Arguments:
# 1: KIOSK: 'True' enables maximizing by default, 'False' disables it.
# 2: INCOG: 'True' enables incognito by default. 'False' disables it.
#
# Author: mfm@magenta.dk

set -ex

KIOSK=$1
INCOG=$2

LAUNCH_FILE="/usr/share/os2borgerpc/bin/start_chromium.sh"
POLICY_FILE_DEFAULT="/var/snap/chromium/current/policies/managed/os2borgerpc-defaults.json"
POLICY_FILE_INCOG="/var/snap/chromium/current/policies/managed/os2borgerpc-incognito.json"
ENVIRONMENT_FILE="/etc/environment"

if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en regulær OS2borgerPC-maskine."
  exit 1
fi

# Backwards compatibility
if grep --quiet "KIOSK=" $LAUNCH_FILE; then
  sed --in-place "/KIOSK=/d" $LAUNCH_FILE
  sed --in-place "s/KIOSK/BPC_KIOSK/" $LAUNCH_FILE
  echo 'BPC_KIOSK="--kiosk"' >> $ENVIRONMENT_FILE
fi

if [ "$KIOSK" = 'True' ]; then
  sed --in-place 's/BPC_KIOSK=.*/BPC_KIOSK="--kiosk"/' $ENVIRONMENT_FILE
else
  sed --in-place 's/BPC_KIOSK=.*/BPC_KIOSK=""/' $ENVIRONMENT_FILE
fi

# Backwards compatibility
sed --in-place "/IncognitoModeAvailability/d" $POLICY_FILE_DEFAULT

if [ "$INCOG" = 'True' ]; then
  cat << EOF > $POLICY_FILE_INCOG
{
  "IncognitoModeAvailability": 2
}
EOF
else
  rm --force $POLICY_FILE_INCOG
fi
