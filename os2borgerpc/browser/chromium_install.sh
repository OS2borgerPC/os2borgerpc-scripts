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

set -ex

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

ACTIVATE=$1

# We refer to Chrome policies here because we're trying to share the policies between Chrome and Chromium
CHROME_POLICIES_PATH="/etc/opt/chrome/policies"
CHROMIUM_POLICIES_PATH="/var/snap/chromium/current/policies"

mkdir --parents "$(dirname $CHROMIUM_POLICIES_PATH)"

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
