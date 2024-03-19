#!/usr/bin/env bash

# SYNOPSIS
#    chrome_policy_homepage.sh [URL]
#
# DESCRIPTION
#    This script adds a Google Chrome policy that defines a homepage, adds
#    the "Home" button to the main browser bar, and causes the homepage to
#    be opened automatically when the browser starts.
#
#    Adding a Google Chrome policy does not require that Google Chrome is
#    already installed, although obviously the policy won't take effect
#    until it has been.
#
#    It takes one optional parameter: the URL to set as the homepage. If
#    this parameter is missing or empty, the existing policy will be
#    deleted, if there is one.
#
# IMPLEMENTATION
#    version         chrome_policy_homepage.sh (magenta.dk) 1.0.0
#    author          Alexander Faithfull
#    copyright       Copyright 2019, Magenta ApS
#    license         GNU General Public License
#    email           af@magenta.dk
#
# DEVELOPER NOTES
#    The policies we set and why:
#
#    ShowHomeButton: A button to go back to the home page. Not crucial.
#    HomepageIsNewTabPage: Don't allow someone to override the homepage with the new tab page
#    HomepageLocation: Sets the page the HomeButton links to, if visible. Confusingly this does not set the homepage that Chrome opens on startup!
#    RestoreOnStartup: Controls what happens on startup. Also prevents users from changing the startup URLs when reopening the browser without logging out of the OS first. Possibly not needed with Guest mode, incognito or ephemeral.
#    RestoreOnStartupURLs: This is, confusingly, what can actually control the homepage, but only if RestoreOnStartup is set to "4".

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

HOMEPAGE_POLICY="/etc/opt/chrome/policies/managed/os2borgerpc-homepage.json"
mkdir --parents "$(dirname "$HOMEPAGE_POLICY")"

STARTPAGE="$1"
ADDITIONAL_PAGES="$2"

PAGES_STRING=""
if [ -n "$ADDITIONAL_PAGES" ]; then
  IFS='|' read -ra PAGES_ARRAY <<< "$ADDITIONAL_PAGES"

  for PAGE in "${PAGES_ARRAY[@]}"
  do
      PAGES_STRING+="\"$PAGE\","
  done
fi

cat > "$HOMEPAGE_POLICY" <<END
{
    "ShowHomeButton": true,
    "HomepageIsNewTabPage": false,
    "HomepageLocation": "$STARTPAGE",

    "RestoreOnStartup": 4,
    "RestoreOnStartupURLs": [
        "$STARTPAGE",$PAGES_STRING
    ]
}
END
