#! /usr/bin/env sh

# This script:
# 1. Installs Microsoft Edge
# 2. Adds assorted policies listed below
# 3. Adds a launch option that prevents it
#    from checking for updates and showing it's out of date to whoever

set -ex

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

INSTALL="$1"

export DEBIAN_FRONTEND=noninteractive
POLICY="/etc/opt/edge/policies/managed/os2borgerpc-defaults.json"

setup_policies() {
  # DEVELOPER NOTES:
  #
  # > POLICIES:
  #
  # The policies we set and why
  #
  # Lockdown:
  # AutofillAddressEnabled: Disable Autofill of addresses
  # AutofillCreditCardEnabled: Disable Autofill of payment methods
  # BrowserAddProfileEnabled: Make it impossible to add a new Profile.                          # Note: Different name in Edge compared to Chrome/Chromium!
  # BrowserSignin: Disable sync/login with own account
  # DeveloperToolsAvailability: Disables access to developer tools, where someone could make changes to a website
  # EditFavoritesEnabled: Disable editing favourites, especially to prevent a nagging message about it
  # EnableMediaRouter: Disable Chrome Cast support
  # ExtensionInstallBlocklist: With the argument * it blocks installing any extension
  # ForceEphemeralProfiles: Clear Profiles on browser close automatically, for privacy reasons
  # PaymentMethodQueryEnabled: Prevent websites from checking if the user has saved payment methods
  #
  # Various:
  # AutoUpdateCheckPeriodMinutes: Don't check for updates and prompt various users about it.    # Note: Not in Chrome/Chromium
  # BrowserGuestModeEnabled: Allow people to start a guest session, if they want, so history isn't even temporarily recorded. Not crucial.
  # BrowsingDataLifetime: Continuously remove all browsing data after 1 hour (the minimum possible),
  #   except "cookies_and_other_site_data" and "password_signin",
  #   because the visitor might be at the computer and still signed in to something.
  # DefaultBrowserSettingEnabled: Don't check if it's default browser. Irrelevant for visitors, and maybe you want Firefox as default.
  # HideFirstRunExperience: Otherwise this will be shown after every login                      # Note: Not in Chrome/Chromium
  # MetricsReportingEnabled: Disable some of Googles metrics, for privacy reasons
  # PasswordManagerEnabled: Don't try to save passwords on a public machine used by many people

  # Additional info on the many policies that can be set:
  # https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies
  #
  # Blocked URLs
  # edge://accessibility: It seems to have what's essentially a builtin keylogger?!
  # edge://extensions: Extension settings can be changed here, and extensions enabled/disabled
  # edge://flags: Experimental features can be enabled/disabled here.

  # Create the new policies

  mkdir --parents "$(dirname "$POLICY")"

  cat > "$POLICY" << END
{
    "AutofillAddressEnabled": false,
    "AutofillCreditCardEnabled": false,
    "AutoUpdateCheckPeriodMinutes": 0,
    "BrowserAddProfileEnabled": false,
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
    "EditFavoritesEnabled": false,
    "EnableMediaRouter": false,
    "ExtensionInstallBlocklist": [
      "*"
    ],
    "ForceEphemeralProfiles": true,
    "HideFirstRunExperience": true,
    "ImportFavorites": false,
    "MetricsReportingEnabled": false,
    "PasswordManagerEnabled": false,
    "PaymentMethodQueryEnabled": false,
    "URLBlocklist": [
      "edge://accessibility",
      "edge://extensions",
      "edge://flags"
    ]
}
END
}

PACKAGE="microsoft-edge-stable"

if [ "$INSTALL" = "True" ]; then

  # Fetch the keyring, put it in the right place with the right permissions and make the source point to that key
  curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/microsoft-edge.gpg # Should have root:root 644 permissions
  echo 'deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main' > /etc/apt/sources.list.d/microsoft-edge.list

  apt-get update --assume-yes
  # If the package manager is in an inconsistent state fix that first
  apt-get install --assume-yes --fix-broken
  apt-get install --assume-yes $PACKAGE

  setup_policies

  # TODO: Haven't added the same "don't check for updates" because ideally the policy AutoUpdateCheckPeriodMinutes
  # should handle that: https://learn.microsoft.com/en-us/deployedge/microsoft-edge-update-policies#autoupdatecheckperiodminutes
else
  # Remove the browser. Leave the desktop files?
  apt-get remove --assume-yes $PACKAGE
  rm $POLICY
fi
