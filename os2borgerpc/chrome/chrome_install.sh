#! /usr/bin/env sh

# This script:
# 1. Install google-chrome
# 2. Add a Google Chrome policy that:
#    - prevents Google Chrome from asking if it should be default browser and about browser metrics
#    - prevents the user logging in to the browser
#    - disables the remember password prompt feature.
# 3. Add a launch option to Chrome that prevents it
#    from checking for updates and showing it's out of date to whoever
#
# Author: Carsten Agger, Marcus Funch Mogensen

set -x

export DEBIAN_FRONTEND=noninteractive
DESKTOP_FILE_PATH=/usr/share/applications/google-chrome.desktop
# In case they've also added Chrome to their desktop
DESKTOP_FILE_PATH2=/home/$USER/Skrivebord/google-chrome.desktop
# In case they've run chrome_autostart.sh
DESKTOP_FILE_PATH3=/home/$USER/.config/autostart/chrome.desktop
FILES="$DESKTOP_FILE_PATH $DESKTOP_FILE_PATH2 $DESKTOP_FILE_PATH3"

# Takes a parameter to add to Chrome and a list of .desktop files to add it to
add_to_desktop_files() {
  PARAMETER="$1"
  shift # Now remove the parameter so we can loop over what remains: The files
  for FILE in "$@"; do
    # Only continue if the particular file exists
    if [ -f "$FILE" ]; then
      # Don't add the parameter multiple times
      if ! grep -q -- "$PARAMETER" "$FILE"; then
        # Note: Using a different delimiter here than in the maximized script,
        # as "," is part of the string
        sed -i "s@\(Exec=/usr/bin/google-chrome-stable\)\(.*\)@\1 $PARAMETER\2@" "$FILE"
      fi
    fi
  done
}

wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update --assume-yes
apt-get install --assume-yes google-chrome-stable

# Cleanup our previous policies if they're around (except the homepage)
OLD_POLICY_1="/etc/opt/chrome/policies/managed/os2borgerpc-default-hp.json"
OLD_POLICY_2="/etc/opt/chrome/policies/managed/os2borgerpc-login.json"
[ -f "$OLD_POLICY_1" ] && rm "$OLD_POLICY_1"
[ -f "$OLD_POLICY_2" ] && rm "$OLD_POLICY_2"

# Create the new policies
POLICY="/etc/opt/chrome/policies/managed/os2borgerpc-defaults.json"

if [ ! -d "$(dirname "$POLICY")" ]; then
    mkdir --parents "$(dirname "$POLICY")"
fi

# Additional info on the many policies that can be set:
# https://support.google.com/chrome/a/answer/187202?hl=en
cat > "$POLICY" <<- END
		{
		    "DefaultBrowserSettingEnabled": false,
		    "MetricsReportingEnabled": false,
		    "BrowserSignin": 0,
		    "PasswordManagerEnabled": false
		}
END

# Chrome: Disable its own check for updates
# Add this launch argument to all desktop files in case the customer's
# already have e.g. a desktop shortcut for it, which would otherwise launch
# Chrome without disabling its check for updates
# shellcheck disable=SC2086 # We want to split the files back into separate arguments
add_to_desktop_files "--simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT'" $FILES
dconf update # Extra insurance that the change takes effect
