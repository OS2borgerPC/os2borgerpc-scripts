#! /usr/bin/env sh

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "This script has not been designed to be run on a Kiosk-machine. Exiting."
  exit 1
fi

LOGIN_DATA="$1"

POLICY="/etc/opt/chrome/policies/managed/os2borgerpc-defaults.json"
SKELETON=".skjult"
CHROME_PROFILE_PATH="/home/$SKELETON/.config/google-chrome/Default"

set -x

[ ! -f $POLICY ] && echo "This script should be run after Chrome has been installed! Exiting." && exit 1

# ForceEphemeralProfiles causes issues for saving logins ("Default" is sometimes deleted, or it uses
# different profile names), so remove that policy first.
sed --in-place "/ForceEphemeral/d" $POLICY

mkdir --parents $CHROME_PROFILE_PATH
chmod -R 700 "$(dirname $CHROME_PROFILE_PATH)"

cp "$LOGIN_DATA" "$CHROME_PROFILE_PATH/Login Data"
chmod 600 "$CHROME_PROFILE_PATH/Login Data"
