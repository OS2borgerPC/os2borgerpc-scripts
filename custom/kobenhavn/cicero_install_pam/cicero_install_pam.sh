#! /usr/bin/env sh

# Arguments:
#   1: Whether to enable or disable Cicero login. 'yes' enables, 'no' disables.
#
# Prerequisites:
# 1. Run the script: user_automatic_login.sh --disable
#
# You may need to restart for it to take effect.

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"

export DEBIAN_FRONTEND=noninteractive
LIGHTDM_PAM=/etc/pam.d/lightdm
# Put our module where PAM modules normally are
PAM_PYTHON_MODULE=/usr/lib/x86_64-linux-gnu/security/os2borgerpc-cicero-pam-module.py
# shellcheck disable=SC2034   # It exists in the included file
LOGOUT_TIMER_CONF=/usr/share/os2borgerpc/logout_timer.conf
CICERO_INTERFACE_PYTHON3=/usr/share/os2borgerpc/bin/cicero_interface_python3.py

if [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] && \
   [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then
  apt-get update --assume-yes
  if ! apt-get install --assume-yes libpam-python; then
    echo "Error installing dependencies."
    exit 1
  fi

  # Two blocks to ensure:
  # Idempotency: Don't add it multiple times if run multiple times
  if ! grep -q "pam_python" "$LIGHTDM_PAM"; then
    # 1. User skips regular login and only uses Cicero.
    sed -i '/common-auth/i# OS2borgerPC Cicero\nauth [success=4 default=ignore] pam_succeed_if.so user = user' $LIGHTDM_PAM

    # 2. All other users use regular login and conversely skip Cicero
    sed -i "/include common-account/i# OS2borgerPC Cicero\nauth [success=1 default=ignore] pam_succeed_if.so user != user\nauth required pam_python.so $PAM_PYTHON_MODULE" $LIGHTDM_PAM
  fi

  # Separated out because pam_python is python2 while our client is python3
cat << EOF > $CICERO_INTERFACE_PYTHON3
#! /usr/bin/env python3

import sys
from subprocess import check_output
import os2borgerpc.client.admin_client as admin_client
import socket


def cicero_validate(cicero_user, cicero_pass):

    host_address = (
        check_output(["get_os2borgerpc_config", "admin_url"]).decode().strip()
    )
    # Example URL:
    # host_address = "https://os2borgerpc-admin.magenta.dk/admin-xml/"

    # For local testing with VirtualBox
    # host_address = "http://10.0.2.2:9999/admin-xml/"

    # Obtain the site and convert from bytes to regular string
    # and remove the trailing newline
    site = check_output(["get_os2borgerpc_config", "site"]).decode().strip()

    # Values it can return - see cicero_login here:
    # https://github.com/OS2borgerPC/admin-site/blob/master/admin_site/system/rpc.py
    # For reference:
    #   r < 0: User is quarantined and may login in -r minutes
    #   r = 0: Unable to authenticate.
    #   r > 0: The user is allowed r minutes of login time.
    admin = admin_client.OS2borgerPCAdmin(host_address + "/admin-xml/")
    try:
        time = admin.citizen_login(cicero_user, cicero_pass, site)
    except (socket.gaierror, TimeoutError):
        time = ""

    # Time is received in minutes
    return time


if __name__ == "__main__":
    print(cicero_validate(sys.argv[1], sys.argv[2]))
EOF

  chmod u+x $CICERO_INTERFACE_PYTHON3

  # Note: pam_python currently runs on python 2.7.18, not python3!
cat << EOF > $PAM_PYTHON_MODULE
#! /usr/bin/env python2
# -*- coding: utf-8 -*-

from subprocess import check_output


def pam_sm_authenticate(pamh, flags, argv):

    # print(pamh.fail_delay)
    # http://pam-python.sourceforge.net/doc/html/
    username_msg = pamh.Message(pamh.PAM_PROMPT_ECHO_OFF, "Lånernummer eller CPR")
    password_msg = pamh.Message(pamh.PAM_PROMPT_ECHO_OFF, "Kodeord")
    # Note: Response object also contains a ret_code
    username_response = pamh.conversation(username_msg)
    password_response = pamh.conversation(password_msg)
    cicero_user = username_response.resp
    cicero_pass = password_response.resp

    cicero_response = check_output(
        ["$CICERO_INTERFACE_PYTHON3", cicero_user, cicero_pass]
    ).strip()

    if not cicero_response:
        result_msg = pamh.Message(
            pamh.PAM_ERROR_MSG, "Forbindelse kunne ikke oprettes. Proev igen senere."
        )
        pamh.conversation(result_msg)
        return pamh.PAM_AUTH_ERR

    time = int(cicero_response)

    if time > 0:
        with open('$LOGOUT_TIMER_CONF', 'w') as f:
            f.write("TIME_MINUTES=" + str(time))
        return pamh.PAM_SUCCESS
    elif time == 0:
        result_msg = pamh.Message(pamh.PAM_ERROR_MSG, "Login mislykkedes.")
        pamh.conversation(result_msg)
        return pamh.PAM_AUTH_ERR
    elif time < 0:
        time_pos = abs(time)
        hours = str(time_pos // 60)
        minutes = str(time_pos % 60)
        result_msg = pamh.Message(
            pamh.PAM_ERROR_MSG,
            "Du kan logge ind igen om " + hours + ":" + minutes
        )
        pamh.conversation(result_msg)
        return pamh.PAM_AUTH_ERR


# TODO: Maybe these other functions could be removed?
def pam_sm_setcred(pamh, flags, argv):
    return pamh.PAM_SUCCESS


def pam_sm_acct_mgmt(pamh, flags, argv):
    return pamh.PAM_SUCCESS


def pam_sm_open_session(pamh, flags, argv):
    return pamh.PAM_SUCCESS


def pam_sm_close_session(pamh, flags, argv):
    return pamh.PAM_SUCCESS


def pam_sm_chauthtok(pamh, flags, argv):
    return pamh.PAM_SUCCESS
EOF

else # Cleanup and remove the Cicero integration
  # Remove Cicero interegration from /etc/pam.d/ files
  sed -i '/pam_succeed_if.so user = user/d' $LIGHTDM_PAM
  sed -i '/# OS2borgerPC Cicero/d' $LIGHTDM_PAM
  sed -i '/pam_succeed_if.so user != user/d' $LIGHTDM_PAM
  sed -i "\@auth required pam_python.so@d" $LIGHTDM_PAM

  rm $CICERO_INTERFACE_PYTHON3 $PAM_PYTHON_MODULE

  # Possibly remove libpam-python as we don't need it anymore
  # - at least this functionality no longer does
  # apt-get remove --assume-yes libpam-python
fi
