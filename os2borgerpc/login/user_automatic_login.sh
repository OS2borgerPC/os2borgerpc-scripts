#!/usr/bin/env bash
#
#   Takes two boolean parameters.
#     1. True will enable automatic login while an unchecked one will disable it.
#     2. If the first argument is True, this determines if OUR_USER is required to type in their password or not.

set -ex

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

LIGHTDM_CONFIG="/etc/lightdm/lightdm.conf"
OUR_USER="user"

ACTIVATE="$1"
REQUIRE_PASSWORD="$2"

adduser $OUR_USER nopasswdlogin

if [ "$ACTIVATE" = "False" ]; then
    if [ "$REQUIRE_PASSWORD" = "True" ]; then
        # Require password for User
        if id --name --groups $OUR_USER | grep --quiet --word-regexp nopasswdlogin; then
            # Remove the user from nopasswdlogin group
            deluser $OUR_USER nopasswdlogin
        fi
    fi
    # Disable autmatic login
    sed --in-place "/autologin-user/d" $LIGHTDM_CONFIG
else # Enable automatic login incl. not requiring password from user on manual login before the timeout
    # Idempotency check
    if ! grep --quiet -- "autologin-user=$OUR_USER" $LIGHTDM_CONFIG; then
			cat <<- EOF >> $LIGHTDM_CONFIG
				autologin-user-timeout=10
				autologin-user=$OUR_USER
			EOF
    fi
fi
