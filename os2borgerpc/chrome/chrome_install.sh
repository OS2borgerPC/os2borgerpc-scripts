#! /usr/bin/env sh

# This script:
# 1. Install google-chrome
# 2. Add a Google Chrome policy that:
#    - prevents Google Chrome from asking if it should be default browser and about browser metrics
#    - prevents the user logging in to the browser
#    - disables the remember password prompt feature.
# 3. Add a launch option to Chrome that prevents it
#    from checking for updates and showing it's out of date to whoever

# Authors: Carsten Agger, Heini Leander Ovason, Marcus Funch Mogensen
#
# DEVELOPER NOTES:
#
# > POLICIES:
#
# The policies we set and why
#
# Lockdown:
# BrowserAddPersonAvailable: Make it impossible to add a new Profile. Doesn't lock down editing a Profile, but it gets some of the way.
# BrowserSignin: Disable sync/login with own google account
# DeveloperToolsAvailable: Disables access to developer tools, where someone could make changes to a website
# EnableMediaRouter: Disable Chrome Cast support
# ExtensionInstallBlocklist: With the argument * it blocks installing any extension
# ForceEphemeralProfiles: Clear Profiles on browser close automatically, for privacy reasons
#
# Start page:
# HomepageIsNewTabPage: Don't allow someone to override the homepage with the new tab page
# HomepageLocation: Sets the page the HomeButton links to, if visible. Confusingly this does not set the homepage that Chrome opens on startup!
# RestoreOnStartup: Controls what happens on startup. Also prevents users from changing the startup URLs when reopening the browser without logging out of the OS first. Possibly not needed with Guest mode, incognito or ephemeral.
# RestoreOnStartupURLs: This is, confusingly, what can actually control the homepage, but only if RestoreOnStartup is set to "4".
#
# Various:
# BrowserGuestModeEnabled: Allow people to start a guest session, if they want, so history isn't even temporarily recorded. Not crucial.
# DefaultBrowserSettingEnabled: Don't check if it's default browser. Irrelevant for visitors, and maybe you want Firefox as default.
# MetricsReportingEnabled: Disable some of Googles metrics, for privacy reasons
# PasswordManagerEnabled: Don't try to save passwords on a public machine used by many people
# ShowHomeButton: A button to go back to the home page. Not crucial.

# Additional info on the many policies that can be set:
# https://support.google.com/chrome/a/answer/187202?hl=en

set -ex

export DEBIAN_FRONTEND=noninteractive
DESKTOP_FILE_PATH_1=/usr/share/applications/google-chrome.desktop
# In case a Chrome shortcut has been added to the desktop
DESKTOP_FILE_PATH_2=/home/$USER/Skrivebord/google-chrome.desktop
# In case chrome_autostart.sh has been executed
DESKTOP_FILE_PATH_3=/home/$USER/.config/autostart/chrome.desktop
FILES="$DESKTOP_FILE_PATH_1 $DESKTOP_FILE_PATH_2 $DESKTOP_FILE_PATH_3"

# Takes a parameter to add to Chrome and a list of .desktop files to add it to
add_to_desktop_files() {
  PARAMETER="$1"
  shift # Now remove the parameter so we can loop over what remains: The files
  for FILE in "$@"; do
    # Only continue if the particular file exists
    if [ -f "$FILE" ]; then
      # Don't add the parameter multiple times (idempotency)
      if ! grep -q -- "$PARAMETER" "$FILE"; then
        # Note: Using a different delimiter here than in the maximized script,
        # as "," is part of the string
        sed -i "s@\(Exec=/usr/bin/google-chrome-stable\)\(.*\)@\1 $PARAMETER\2@" "$FILE"
      fi
    fi
  done
}

wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update --assume-yes
# If the package manager is in an inconsistent state fix that first
apt-get install --assume-yes --fix-broken
apt-get install --assume-yes google-chrome-stable

# Cleanup our previous policies if they're around (except the homepage)
rm --force /etc/opt/chrome/policies/managed/os2borgerpc-default-hp.json /etc/opt/chrome/policies/managed/os2borgerpc-login.json

# Create the new policies
POLICY="/etc/opt/chrome/policies/managed/os2borgerpc-defaults.json"

if [ ! -d "$(dirname "$POLICY")" ]; then
    mkdir --parents "$(dirname "$POLICY")"
fi

cat > "$POLICY" <<- END
{
    "BrowserAddPersonEnabled": false,
    "BrowserGuestModeEnabled": true,
    "BrowserSignin": 0,
    "DefaultBrowserSettingEnabled": false,
    "DeveloperToolsAvailability": 2,
    "EnableMediaRouter": false,
    "ExtensionInstallBlocklist": [
      "*"
    ],
    "ForceEphemeralProfiles": true,
    "HomepageIsNewTabPage": false,
    "HomepageLocation": "https://borger.dk",
    "MetricsReportingEnabled": false,
    "PasswordManagerEnabled": false,
    "RestoreOnStartup": 4,
    "RestoreOnStartupURLs": [
        "https://borger.dk"
    ],
    "ShowHomeButton": true,
    "URLBlocklist": [
      "chrome://*"
    ]
}
END

# Chrome: Disable its own check for updates
# It would be more elegant to control this via a policy, but unfortunately that does not seem to be possible currently
# Add this launch argument to all desktop files in case the customer's
# already have e.g. a desktop shortcut for it, which would otherwise launch
# Chrome without disabling its check for updates
# shellcheck disable=SC2086 # We want to split the files back into separate arguments
add_to_desktop_files "--simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT'" $FILES
dconf update # Extra insurance that the change takes effect
