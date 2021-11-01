#! /usr/bin/env sh

# This script:
# 1. Install google-chrome
# 2. Add a Google Chrome policy that:
#    - prevents Google Chrome from asking if it should be default browser and about browser metrics
#    - prevents the user logging in to the browser
#    - disables the remember password prompt feature.
#    - disable automatic updates including checks for them
#
# Author: Carsten Agger, Marcus Funch Mogensen

set -x

wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update --assume-yes
apt-get install --assume-yes google-chrome-stable

# Cleanup our previous policies if they're around (except the homepage)
OLD_POLICY_1="/etc/opt/chrome/policies/managed/os2borgerpc-default-hp.json"
OLD_POLICY_2="/etc/opt/chrome/policies/managed/os2borgerpc-login.json"
if [ -f "$OLD_POLICY_1" ]; then
  rm "$OLD_POLICY_1"
fi
if [ -f "$OLD_POLICY_2" ]; then
  rm "$OLD_POLICY_2"
fi

# Create the new policies
POLICY="/etc/opt/chrome/policies/managed/os2borgerpc-defaults.json"

if [ ! -d "$(dirname "$POLICY")" ]; then
    mkdir --parents "$(dirname "$POLICY")"
fi

# Additional info on the many policies that can be set:
# https://support.google.com/chrome/a/answer/187202?hl=en
cat > "$POLICY" <<- END
		{
		    "DefaultBrowserSettingEnabled": true,
		    "MetricsReportingEnabled": false,
		    "BrowserSignin": 0,
		    "PasswordManagerEnabled": false
		}
END
