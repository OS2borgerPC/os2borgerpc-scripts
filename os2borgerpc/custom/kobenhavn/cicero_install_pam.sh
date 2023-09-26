#! /usr/bin/env sh

# Arguments:
#   1: Whether to enable or disable Cicero login. 'yes' enables, 'no' disables.
#
# Prerequisites:
#   1. Run the script: user_automatic_login.sh --disable
#
# You may need to restart for it to take effect.

set -x

ACTIVATE=$1

export DEBIAN_FRONTEND=noninteractive
LIGHTDM_PAM=/etc/pam.d/lightdm
# Put our module where PAM modules normally are
PAM_PYTHON_MODULE=/usr/lib/x86_64-linux-gnu/security/os2borgerpc-cicero-pam-module.py
# Keep this in sync with the extensions name as given in the os2borgerpc-gnome-extensions repo!
# shellcheck disable=SC2034   # It exists in an included file
EXTENSION_NAME='logout-timer@os2borgerpc.magenta.dk'
# shellcheck disable=SC2034   # It exists in an included file
LOGOUT_TIMER_CONF="/usr/share/gnome-shell/extensions/$EXTENSION_NAME/config.json"
CICERO_INTERFACE_PYTHON3=/usr/share/os2borgerpc/bin/cicero_interface_python3.py
CITIZEN_HASH_FILE="/etc/os2borgerpc/citizen_hash.txt"
CICERO_LOGOUT_SCRIPT="/etc/lightdm/greeter-setup-scripts/cicero_logout.py"
CICERO_LOGOUT_SERVICE="/etc/systemd/system/cicero_logout.service"
GREETER_SETUP_SCRIPT="/etc/lightdm/greeter_setup_script.sh"
GREETER_SETUP_DIR="/etc/lightdm/greeter-setup-scripts"

if [ "$ACTIVATE" = 'True' ]; then
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

# Separated out because the pam module cannot run if you import the admin_client
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
        time, citizen_hash = admin.citizen_login(cicero_user, cicero_pass, site, prevent_dual_login=True)
    except (socket.gaierror, TimeoutError, ConnectionError):
        time = ""
        citizen_hash = ""

    # Time is received in minutes
    return time, citizen_hash


if __name__ == "__main__":
    print(cicero_validate(sys.argv[1], sys.argv[2]))
EOF

  chmod u+x $CICERO_INTERFACE_PYTHON3

# Ensure that the greeter_setup_script has the correct form
# and that the relevant directory exists
mkdir --parents $GREETER_SETUP_DIR
cat << EOF > $GREETER_SETUP_SCRIPT
#!/bin/sh
greeter_setup_scripts=\$(find $GREETER_SETUP_DIR -mindepth 1)
for file in \$greeter_setup_scripts
do
    ./"\$file" &
done
EOF

chmod 700 $GREETER_SETUP_SCRIPT

cat << EOF > $CICERO_LOGOUT_SCRIPT
#! /usr/bin/env python3

from subprocess import check_output
import os2borgerpc.client.admin_client as admin_client
from os.path import exists
import socket

def cicero_logout():
    if exists("$CITIZEN_HASH_FILE"):
        with open("$CITIZEN_HASH_FILE", "r") as f:
            citizen_hash = f.read()
        host_address = (
            check_output(["get_os2borgerpc_config", "admin_url"]).decode().strip()
        )
        admin = admin_client.OS2borgerPCAdmin(host_address + "/admin-xml/")
        try:
            result = admin.citizen_logout(citizen_hash)
        except (socket.gaierror, TimeoutError, ConnectionError):
            result = ""


if __name__ == "__main__":
    cicero_logout()
EOF

  chmod 700 "$CICERO_LOGOUT_SCRIPT"

# This service ensures that the citizen is logged out
# even if they shut down or reboot the machine
cat << EOF > $CICERO_LOGOUT_SERVICE
[Unit]
Description=Cicero logout service
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=simple
ExecStart=$CICERO_LOGOUT_SCRIPT

[Install]
WantedBy=halt.target reboot.target shutdown.target
EOF

systemctl enable "$(basename $CICERO_LOGOUT_SERVICE)"

cat << EOF > $PAM_PYTHON_MODULE
#! /usr/bin/env python3
# -*- coding: utf-8 -*-

from subprocess import check_output
import json
from os.path import exists

CONF_TIME_VALUE = "timeMinutes"


def pam_sm_authenticate(pamh, flags, argv):
    # print(pamh.fail_delay)
    # http://pam-python.sourceforge.net/doc/html/
    username_msg = pamh.Message(pamh.PAM_PROMPT_ECHO_OFF, "Lånernummer eller CPR")
    password_msg = pamh.Message(pamh.PAM_PROMPT_ECHO_OFF, "Pinkode")
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
            pamh.PAM_ERROR_MSG, "Forbindelse kunne ikke oprettes. Prøv senere."
        )
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

    # cicero_response is a binary string containing (time, 'citizen_hash')
    # This format determines the necessary commands to extract time and citizen_hash
    time = int(cicero_response.split(b", ")[0][1:])
    citizen_hash = str(cicero_response.split(b", ")[1][:-1])[1:-1]

    if citizen_hash == "logged_in":
        result_msg = pamh.Message(
            pamh.PAM_ERROR_MSG,
            "Du er allerede logget ind på en anden maskine."
        )
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

    if time > 0:

        # Only remember the logged in citizen if login succeeds, i.e. time > 0
        with open("$CITIZEN_HASH_FILE", "w") as f:
            f.write(citizen_hash)

        # They may not be using any of the timer scripts
        if exists("$LOGOUT_TIMER_CONF"):

            # Set the countdown time for the timers
            with open("$LOGOUT_TIMER_CONF", "r+") as f:
                # Read the current config, update it, then overwrite it with the updated contents
                conf = json.loads(f.read())
                conf[CONF_TIME_VALUE] = time

                f.seek(0)
                f.truncate()

                f.write(json.dumps(conf, indent=2))

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
            "Du kan først logge ind igen om " + hours + "t " + minutes + "m.",
        )
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

# This function needs to be here for the module to work
def pam_sm_setcred(pamh, flags, argv):
    return pamh.PAM_SUCCESS
EOF

else # Cleanup and remove the Cicero integration
  # Remove Cicero interegration from /etc/pam.d/ files
  sed -i '/pam_succeed_if.so user = user/d' $LIGHTDM_PAM
  sed -i '/# OS2borgerPC Cicero/d' $LIGHTDM_PAM
  sed -i '/pam_succeed_if.so user != user/d' $LIGHTDM_PAM
  sed -i "\@auth required pam_python.so@d" $LIGHTDM_PAM

  systemctl disable "$(basename $CICERO_LOGOUT_SERVICE)"

  rm --force $CICERO_INTERFACE_PYTHON3 $PAM_PYTHON_MODULE \
  $CICERO_LOGOUT_SCRIPT $CITIZEN_HASH_FILE $CICERO_LOGOUT_SERVICE

  # Possibly remove libpam-python as we don't need it anymore
  # - at least this functionality no longer does
  # apt-get remove --assume-yes libpam-python
fi
