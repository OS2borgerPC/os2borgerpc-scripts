#! /usr/bin/env sh

# This script:
# 1. Install Chromium
# 2. Add a Chromium policy that:
#    - prevents Chromium from asking if it should be default browser and about browser metrics
#    - prevents the user logging in to the browser
#    - disables the remember password prompt feature.

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
#
# Blocked URLs
#
# chrome://accessibility: It seems to have what's essentially a builtin keylogger?!
# chrome://extensions: Extension settings can be changed here, and extensions enabled/disabled
# chrome://flags: Experimental features can be enabled/disabled here.

set -ex

ACTIVATE=$1

# We refer to Chrome policies here because we're trying to share the policies between Chrome and Chromium
CHROME_POLICIES_PATH="/etc/opt/chrome/policies"
CHROMIUM_POLICIES_PATH="/var/snap/chromium/current/policies"

mkdir --parents "$(dirname $CHROMIUM_POLICIES_PATH)"

# This function is shared between chrome_install.sh and chromium_install.sh
setup_policies() {
  # Cleanup our previous policies if they're around (except the homepage)
  rm --force /etc/opt/chrome/policies/managed/os2borgerpc-default-hp.json /etc/opt/chrome/policies/managed/os2borgerpc-login.json

  # Create the new policies
  MAIN_POLICY="/etc/opt/chrome/policies/managed/os2borgerpc-defaults.json"
  HOMEPAGE_POLICY="/etc/opt/chrome/policies/managed/os2borgerpc-homepage.json"

  if [ ! -d "$(dirname "$MAIN_POLICY")" ]; then
      mkdir --parents "$(dirname "$MAIN_POLICY")"
  fi

	cat > "$MAIN_POLICY" <<- END
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
		    "MetricsReportingEnabled": false,
		    "PasswordManagerEnabled": false,
		    "URLBlocklist": [
		      "chrome://accessibility",
		      "chrome://extensions",
		      "chrome://flags"
		    ]
		}
	END

  # This entire policy file is overwritten if you later run the script to change the homepage
  # We set it here too so all machines have a startpage set, to prevent someone from manually setting the homepage to
  # some malicious site
	cat > "$HOMEPAGE_POLICY" <<- END
		{
		    "HomepageLocation": "https://borger.dk",
		    "RestoreOnStartup": 4,
		    "ShowHomeButton": true,
		    "HomepageIsNewTabPage": false,
		    "RestoreOnStartupURLs": [
		        "https://borger.dk"
		    ]
		}
	END
}

if [ "$ACTIVATE" = "True" ]; then
  # Fails if /var/snap/chromium/current already exists, which it will be if it's already installed.
  if ! which chromium > /dev/null; then
    snap install chromium
  fi
  ln --symbolic --force $CHROME_POLICIES_PATH $CHROMIUM_POLICIES_PATH

  setup_policies
else
  snap remove chromium
  # Remove chromium symlink
  rm $CHROMIUM_POLICIES_PATH
fi
