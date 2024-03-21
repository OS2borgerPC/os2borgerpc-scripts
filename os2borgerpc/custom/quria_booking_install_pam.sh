#! /usr/bin/env sh

# Arguments:
#   1: Whether to enable or disable Quria login. 'yes' enables, 'no' disables.
#
#
# You may need to restart for it to take effect.

set -x

ACTIVATE=$1
REQUIRE_BOOKING=$2
BOOK_SPECIFIC_PC=$3
ALLOW_IDLE_LOGIN=$4
LOGIN_DURATION=${5:-None}
QUARANTINE_DURATION=${6:-None}
SAVE_LOG=$7

if [ "$BOOK_SPECIFIC_PC" = "False" ]; then
  ALLOW_IDLE_LOGIN=False
fi

LOANER_NUMBER_MIN_LENGTH=8
LOANER_PIN_LENGTH=4

export DEBIAN_FRONTEND=noninteractive
LIGHTDM_PAM=/etc/pam.d/lightdm
# Put our module where PAM modules normally are
PAM_PYTHON_MODULE=/usr/lib/x86_64-linux-gnu/security/os2borgerpc-custom-login-pam-module.py
# Keep this in sync with the extensions name as given in the os2borgerpc-gnome-extensions repo!
# shellcheck disable=SC2034   # It exists in an included file
EXTENSION_NAME='logout-timer@os2borgerpc.magenta.dk'
# shellcheck disable=SC2034   # It exists in an included file
LOGOUT_TIMER_CONF="/usr/share/gnome-shell/extensions/$EXTENSION_NAME/config.json"
QURIA_LOGIN_INTERFACE_PYTHON3=/usr/share/os2borgerpc/bin/quria_login_interface_python3.py
CITIZEN_HASH_FILE="/etc/os2borgerpc/citizen_hash.txt"
LOG_ID_FILE="/etc/os2borgerpc/login_log_id.txt"
LOGOUT_SCRIPT="/etc/lightdm/greeter-setup-scripts/general_citizen_logout.py"
LOGOUT_SERVICE="/etc/systemd/system/general_citizen_logout.service"
GREETER_SETUP_SCRIPT="/etc/lightdm/greeter_setup_script.sh"
GREETER_SETUP_DIR="/etc/lightdm/greeter-setup-scripts"
LIGHTDM_CONFIG="/etc/lightdm/lightdm.conf"

if [ "$ACTIVATE" = 'True' ]; then
  apt-get update --assume-yes
  if ! apt-get install --assume-yes libpam-python; then
    echo "Error installing dependencies."
    exit 1
  fi

  # Two blocks to ensure:
  # Idempotency: Don't add it multiple times if run multiple times
  if ! grep -q "pam_python" "$LIGHTDM_PAM"; then
    # 1. User skips regular login and only uses Quria.
    sed -i '/common-auth/i# OS2borgerPC custom login\nauth [success=4 default=ignore] pam_succeed_if.so user = user' $LIGHTDM_PAM

    # 2. All other users use regular login and conversely skip Quria
    sed -i "/include common-account/i# OS2borgerPC custom login\nauth [success=1 default=ignore] pam_succeed_if.so user != user\nauth required pam_python.so $PAM_PYTHON_MODULE" $LIGHTDM_PAM
  fi

  # Disable automatic login
  deluser user nopasswdlogin
  sed --in-place "/autologin-user/d" $LIGHTDM_CONFIG

# Separated out because the pam module cannot run if you import the admin_client or re
cat << EOF > $QURIA_LOGIN_INTERFACE_PYTHON3
#! /usr/bin/env python3

import sys
from subprocess import check_output
import os2borgerpc.client.admin_client as admin_client
import socket
import re

book_specific_pc = $BOOK_SPECIFIC_PC
require_booking = $REQUIRE_BOOKING
allow_idle_login = $ALLOW_IDLE_LOGIN
login_duration = $LOGIN_DURATION
quarantine_duration = $QUARANTINE_DURATION
save_log = $SAVE_LOG

def quria_validate(loaner_number, pincode):

    # The pincode should only contain digits
    if not re.fullmatch(f"^\d+$", pincode):
        return 0, "invalid_pin", ""

    host_address = (
        check_output(["get_os2borgerpc_config", "admin_url"]).decode().strip()
    )
    # Example URL:
    # host_address = "https://os2borgerpc-admin.magenta.dk"

    # For local testing with VirtualBox
    # host_address = "http://10.0.2.2:9999"

    # Obtain the pc_uid and convert from bytes to regular string
    # and remove the trailing newline
    pc_uid = check_output(["get_os2borgerpc_config", "uid"]).decode().strip()

    # If booking a specific PC is required, obtain the name of this PC,
    # convert from bytes to regular string and remove the trailing newline
    if book_specific_pc:
        pc_name = check_output(["get_os2borgerpc_config", "hostname"]).decode().strip()
    else:
        pc_name = None

    value_dict = {"citizen_identifier":loaner_number,"pincode":pincode,"pc_name":pc_name}
    # For some values, it only matters whether they are present in the dictionary or not
    # When present, these values are simply set to 1 to indicate True in a minimal way
    if require_booking:
        value_dict["require_booking"] = 1
    if allow_idle_login:
        value_dict["allow_idle_login"] = 1
    if login_duration:
        value_dict["login_duration"] = login_duration
    if quarantine_duration:
        value_dict["quarantine_duration"] = quarantine_duration
    if save_log:
        value_dict["save_log"] = 1

    # Values it can return - see general_citizen_login here:
    # https://github.com/OS2borgerPC/admin-site/blob/master/admin_site/system/rpc.py
    # For reference:
    #   time < 0: User is quarantined and may login in -time minutes. Alternatively,
    #             the next booking starts in -time minutes (theirs or anothers)
    #   time = 0: Unable to authenticate.
    #   time > 0: The user is allowed r minutes of login time.
    admin = admin_client.OS2borgerPCAdmin(host_address + "/admin-xml/")
    try:
        time, citizen_hash_note, log_id = admin.general_citizen_login(pc_uid, "quria", value_dict)
    except (socket.gaierror, TimeoutError, ConnectionError):
        return ""

    # Time is received in minutes
    return time, citizen_hash_note, log_id


if __name__ == "__main__":
    print(quria_validate(sys.argv[1], sys.argv[2]))
EOF

  chmod u+x $QURIA_LOGIN_INTERFACE_PYTHON3

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

cat << EOF > $LOGOUT_SCRIPT
#! /usr/bin/env python3

from subprocess import check_output
import os2borgerpc.client.admin_client as admin_client
from os.path import exists
from os import remove
import socket

def quria_logout():
    if exists("$CITIZEN_HASH_FILE") or exists("$LOG_ID_FILE"):
        citizen_hash = ""
        log_id = ""
        if exists("$CITIZEN_HASH_FILE"):
            with open("$CITIZEN_HASH_FILE", "r") as f:
                citizen_hash = f.read()
            remove("$CITIZEN_HASH_FILE")
        if exists("$LOG_ID_FILE"):
            with open("$LOG_ID_FILE", "r") as f:
                log_id = f.read()
            remove("$LOG_ID_FILE")
        host_address = (
            check_output(["get_os2borgerpc_config", "admin_url"]).decode().strip()
        )
        admin = admin_client.OS2borgerPCAdmin(host_address + "/admin-xml/")
        try:
            result = admin.general_citizen_logout(citizen_hash, log_id)
        except (socket.gaierror, TimeoutError, ConnectionError):
            result = ""


if __name__ == "__main__":
    quria_logout()
EOF

  chmod 700 "$LOGOUT_SCRIPT"

# This service ensures that the citizen is logged out
# even if they shut down or reboot the machine
cat << EOF > $LOGOUT_SERVICE
[Unit]
Description=Citizen logout service
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=simple
ExecStart=$LOGOUT_SCRIPT

[Install]
WantedBy=halt.target reboot.target shutdown.target
EOF

systemctl enable "$(basename $LOGOUT_SERVICE)"

cat << EOF > $PAM_PYTHON_MODULE
#! /usr/bin/env python3
# -*- coding: utf-8 -*-

from subprocess import check_output
import json
from os.path import exists
import random
import string

CONF_TIME_VALUE = "timeMinutes"

book_specific_pc = $BOOK_SPECIFIC_PC
require_booking = $REQUIRE_BOOKING
allow_idle_login = $ALLOW_IDLE_LOGIN


def pam_sm_authenticate(pamh, flags, argv):
    # print(pamh.fail_delay)
    # http://pam-python.sourceforge.net/doc/html/
    loaner_number_msg = pamh.Message(pamh.PAM_PROMPT_ECHO_ON, "Person- eller låntkortsnummer")
    loaner_number_response = pamh.conversation(loaner_number_msg)
    loaner_number = loaner_number_response.resp

    if len(loaner_number) < $LOANER_NUMBER_MIN_LENGTH:
        result_msg = pamh.Message(
            pamh.PAM_ERROR_MSG, "Ogiltigt värde."
        )
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

    pincode_msg = pamh.Message(pamh.PAM_PROMPT_ECHO_OFF, "Pinkod")
    pincode_response = pamh.conversation(pincode_msg)
    pincode = pincode_response.resp

    if len(pincode) != $LOANER_PIN_LENGTH:
        result_msg = pamh.Message(
            pamh.PAM_ERROR_MSG, "Ogiltig pinkod."
        )
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

    quria_booking_response = check_output(
        ["$QURIA_LOGIN_INTERFACE_PYTHON3", loaner_number, pincode]
    ).strip()

    if not quria_booking_response:
        result_msg = pamh.Message(
            pamh.PAM_ERROR_MSG, "Anslutningen misslyckades. Försök senare."
        )
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

    # quria_booking_response is a binary string containing (time, 'citizen_hash_note', log_id)
    # This format determines the necessary commands to extract time, citizen_hash_note and log_id
    time, citizen_hash_note, log_id = quria_booking_response.split(b", ")
    time = int(time[1:])
    citizen_hash_note = str(citizen_hash_note)[1:-1]
    log_id = str(log_id[:-1])

    if citizen_hash_note == "invalid_pin":
        result_msg = pamh.Message(
            pamh.PAM_ERROR_MSG, "Felaktig pinkod. Ange endast siffror."
        )
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

    if citizen_hash_note == "no_booking":
        if book_specific_pc:
            result_msg = pamh.Message(
                pamh.PAM_ERROR_MSG,
                "Ingen matchande bokning för den här datorn."
            )
        else:
            result_msg = pamh.Message(
                pamh.PAM_ERROR_MSG,
                "Du har inte bokat en dator under den här tiden."
            )
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

    if citizen_hash_note == "logged_in":
        result_msg = pamh.Message(
            pamh.PAM_ERROR_MSG,
            "Du är redan inloggad på en annan dator."
        )
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

    if citizen_hash_note == "booked":
        result_msg = pamh.Message(
            pamh.PAM_ERROR_MSG,
            "Den här datorn är bokad av någon annan."
        )
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

    if citizen_hash_note == "blocked":
        result_msg = pamh.Message(
            pamh.PAM_ERROR_MSG,
            "Ditt bibliotekskonto är blockerat."
        )
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

    if time > 0:

        # If a log should be saved
        # Due to a quirk related to receiving multiple values
        # from a single check_output, log_id will be the string "''"
        # rather than an empty string when no log should be saved
        if log_id != "''":
            with open("$LOG_ID_FILE", "w") as f:
                f.write(log_id)

        # Only remember the logged in citizen if login succeeds, i.e. time > 0
        # No need to remember the citizen if booking is required and idle login
        # is not allowed, as the quarantine system is not used in that case
        if not require_booking or allow_idle_login:
            with open("$CITIZEN_HASH_FILE", "w") as f:
                f.write(citizen_hash_note)

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
        result_msg = pamh.Message(pamh.PAM_ERROR_MSG, "Inloggningen misslyckades.")
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

    elif time < 0:
        time_pos = abs(time)
        hours = str(time_pos // 60)
        minutes = str(time_pos % 60)
        if citizen_hash_note == "later_booking":  # The next matching booking is in the future
            result_msg = pamh.Message(
                pamh.PAM_ERROR_MSG,
                "Din bokning börjar först om " + hours + "t " + minutes + "m.",
            )
        elif citizen_hash_note == "quarantine":  # Idle login is allowed, but the user is quarantined
            result_msg = pamh.Message(
                pamh.PAM_ERROR_MSG,
                "Din karantän upphör om " + hours + "t " + minutes + "m.",
            )
        elif citizen_hash_note == "booking_soon":  # Another person's booking starts soon
            result_msg = pamh.Message(
                pamh.PAM_ERROR_MSG,
                "En bokning börjar om " + hours + "t " + minutes + "m.",
            )
        else:
            result_msg = pamh.Message(
                pamh.PAM_ERROR_MSG,
                "Du kan bara logga in igen efter " + hours + "t " + minutes + "m.",
            )
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

# This function needs to be here for the module to work
def pam_sm_setcred(pamh, flags, argv):
    return pamh.PAM_SUCCESS
EOF

# Make sure they have a sufficiently updated version of the client
pip install --upgrade os2borgerpc-client

else # Cleanup and remove the Quria/booking integration
  # Remove Quria/booking integration from /etc/pam.d/ files
  sed -i '/pam_succeed_if.so user = user/d' $LIGHTDM_PAM
  sed -i '/# OS2borgerPC custom login/d' $LIGHTDM_PAM
  sed -i '/pam_succeed_if.so user != user/d' $LIGHTDM_PAM
  sed -i "\@auth required pam_python.so@d" $LIGHTDM_PAM

  systemctl disable "$(basename $LOGOUT_SERVICE)"

  # Allow login without password
  adduser user nopasswdlogin

  rm --force $QURIA_LOGIN_INTERFACE_PYTHON3 $PAM_PYTHON_MODULE \
  $LOGOUT_SCRIPT $CITIZEN_HASH_FILE $LOGOUT_SERVICE \
  $LOG_ID_FILE
fi
