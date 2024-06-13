#! /usr/bin/env sh

# This script:
# 1. Installs google-chrome
# 2. Adds assorted policies listed below
# 3. Adds a launch option that prevents it
#    from checking for updates and showing it's out of date to whoever

# Authors: Carsten Agger, Heini Leander Ovason, Marcus Funch Mogensen

set -ex

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

INSTALL="$1"

export DEBIAN_FRONTEND=noninteractive

### START SHARED BLOCK BETWEEN CHROMIUM BROWSERS: CHROMIUM, CHROME ###
setup_policies() {
  #
  # DEVELOPER NOTES:
  #
  # > POLICIES:
  #
  # The policies we set and why
  #
  # Lockdown:
  # AutofillAddressEnabled: Disable Autofill of addresses
  # AutofillCreditCardEnabled: Disable Autofill of payment methods
  # BrowserAddPersonEnabled: Make it impossible to add a new Profile. Doesn't lock down editing a Profile, but it gets some of the way.
  # BrowserSignin: Disable sync/login with own google account
  # DeveloperToolsAvailability: Disables access to developer tools, where someone could make changes to a website
  # EnableMediaRouter: Disable Chrome Cast support
  # ExtensionInstallBlocklist: With the argument * it blocks installing any extension
  # ForceEphemeralProfiles: Clear Profiles on browser close automatically, for privacy reasons
  # PaymentMethodQueryEnabled: Prevent websites from checking if the user has saved payment methods
  #
  # Various:
  # BrowserGuestModeEnabled: Allow people to start a guest session, if they want, so history isn't even temporarily recorded. Not crucial.
  # BrowsingDataLifetime: Continuously remove all browsing data after 1 hour (the minimum possible),
  # except "cookies_and_other_site_data" and "password_signin",
  # because the visitor might be at the computer and still signed in to something.
  # DefaultBrowserSettingEnabled: Don't check if it's default browser. Irrelevant for visitors, and maybe you want Firefox as default.
  # MetricsReportingEnabled: Disable some of Googles metrics, for privacy reasons
  # PasswordManagerEnabled: Don't try to save passwords on a public machine used by many people
  # PrivacySandboxPromptEnabled: Don't prompt about enabling (some) ad tracking
  # PrivacySandboxSiteEnabledAdsEnabled: Disable (some) ad tracking

  # Additional info on the many policies that can be set:
  # https://support.google.com/chrome/a/answer/187202?hl=en
  #
  # Blocked URLs
  #
  # chrome://accessibility: It seems to have what's essentially a builtin keylogger?!
  # chrome://extensions: Extension settings can be changed here, and extensions enabled/disabled
  # chrome://flags: Experimental features can be enabled/disabled here.

  # Cleanup our previous policies if they're around (except the homepage)
  rm --force /etc/opt/chrome/policies/managed/os2borgerpc-default-hp.json /etc/opt/chrome/policies/managed/os2borgerpc-login.json

  # Create the new policies
  POLICY="/etc/opt/chrome/policies/managed/os2borgerpc-defaults.json"

  mkdir --parents "$(dirname "$POLICY")"

  cat > "$POLICY" << END
{
    "AutofillAddressEnabled": false,
    "AutofillCreditCardEnabled": false,
    "BrowserAddPersonEnabled": false,
    "BrowserGuestModeEnabled": true,
    "BrowserSignin": 0,
    "BrowsingDataLifetime": [
      {
        "data_types": [
          "autofill",
          "browsing_history",
          "cached_images_and_files",
          "download_history",
          "hosted_app_data",
          "site_settings"
        ],
        "time_to_live_in_hours": 1
      }
    ],
    "DefaultBrowserSettingEnabled": false,
    "DeveloperToolsAvailability": 2,
    "EnableMediaRouter": false,
    "ExtensionInstallBlocklist": [
      "*"
    ],
    "ForceEphemeralProfiles": true,
    "MetricsReportingEnabled": false,
    "PasswordManagerEnabled": false,
    "PaymentMethodQueryEnabled": false,
    "PrivacySandboxPromptEnabled": false,
    "PrivacySandboxSiteEnabledAdsEnabled": false,
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
  HOMEPAGE_POLICY="/etc/opt/chrome/policies/managed/os2borgerpc-homepage.json"
  if [ ! -f $HOMEPAGE_POLICY ]; then
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
  fi

  # Set the default search provider to Google so Chrome stops asking every time
  # the browser is opened.
  # Chrome will default to using Google if we leave DefaultSearchProviderSearchURL
  # blank
  SEARCH_POLICY="/etc/opt/chrome/policies/managed/os2borgerpc-search-provider.json"
  if [ ! -f "$SEARCH_POLICY" ]; then
    cat > "$SEARCH_POLICY" <<- END
{
    "DefaultSearchProviderEnabled": true,
    "DefaultSearchProviderSearchURL": ""
}
END
  fi
}
### END SHARED BLOCK BETWEEN CHROMIUM BROWSERS: CHROMIUM, CHROME ###

# Takes a parameter to add to Chrome and a list of .desktop files to add it to
add_to_desktop_files() {
  PARAMETER="$1"
  shift # Now remove the parameter so we can loop over what remains: The files
  for FILE in "$@"; do
    # Only continue if the particular file exists
    if [ -f "$FILE" ]; then
      # Don't add the parameter multiple times (idempotency)
      if ! grep --quiet -- "$PARAMETER" "$FILE"; then
        # Note: Using a different delimiter here than in the maximized script,
        # as "," is part of the string
        sed --in-place "s@\(Exec=/usr/bin/google-chrome-stable\)\(.*\)@\1 $PARAMETER\2@" "$FILE"
      fi
    fi
  done
}

# Determine the name of the user desktop directory. This is done via xdg-user-dir,
# which checks the /home/user/.config/user-dirs.dirs file. To ensure this file exists,
# we run xdg-user-dirs-update, which generates it based on the environment variable
# LANG. This variable is empty in lightdm so we first export it
# based on the value stored in /etc/default/locale
export "$(grep LANG= /etc/default/locale | tr -d '"')"
runuser -u user xdg-user-dirs-update
DESKTOP=$(basename "$(runuser -u user xdg-user-dir DESKTOP)")

DESKTOP_FILE_PATH_1=/usr/share/applications/google-chrome.desktop
# In case a Chrome shortcut has been added to the desktop
DESKTOP_FILE_PATH_2=/home/$USER/$DESKTOP/google-chrome.desktop
# In case chrome_autostart.sh has been executed
DESKTOP_FILE_PATH_3=/home/$USER/.config/autostart/chrome.desktop
FILES="$DESKTOP_FILE_PATH_1 $DESKTOP_FILE_PATH_2 $DESKTOP_FILE_PATH_3"

PACKAGE="google-chrome-stable"

if [ "$INSTALL" = "True" ]; then

  wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
  echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
  apt-get update --assume-yes
  # If the package manager is in an inconsistent state fix that first
  apt-get install --assume-yes --fix-broken
  apt-get install --assume-yes $PACKAGE

  setup_policies

  # Chrome: Disable its own check for updates
  # It would be more elegant to control this via a policy, but unfortunately that does not seem to be possible currently
  # Add this launch argument to all desktop files in case the customer's
  # already have e.g. a desktop shortcut for it, which would otherwise launch
  # Chrome without disabling its check for updates
  # shellcheck disable=SC2086 # We want to split the files back into separate arguments
  add_to_desktop_files "--simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT'" $FILES
  dconf update # Extra insurance that the change takes effect
else
  # Not removing the policies because Chromium may use them, and rerunning Chrome - Install overwrites them anyway.
  apt-get remove --assume-yes $PACKAGE
fi
