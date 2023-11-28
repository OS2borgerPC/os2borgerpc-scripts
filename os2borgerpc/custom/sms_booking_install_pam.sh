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
REQUIRE_BOOKING=$2
BOOK_SPECIFIC_PC=$3
SAVE_LOG=$4

export DEBIAN_FRONTEND=noninteractive
LIGHTDM_PAM=/etc/pam.d/lightdm
# Put our module where PAM modules normally are
PAM_PYTHON_MODULE=/usr/lib/x86_64-linux-gnu/security/os2borgerpc-sms-booking-pam-module.py
# Keep this in sync with the extensions name as given in the os2borgerpc-gnome-extensions repo!
# shellcheck disable=SC2034   # It exists in an included file
EXTENSION_NAME='logout-timer@os2borgerpc.magenta.dk'
# shellcheck disable=SC2034   # It exists in an included file
LOGOUT_TIMER_CONF="/usr/share/gnome-shell/extensions/$EXTENSION_NAME/config.json"
SMS_LOGIN_INTERFACE_PYTHON3=/usr/share/os2borgerpc/bin/sms_login_interface_python3.py
LOGIN_FINALIZE_INTERFACE_PYTHON3=/usr/share/os2borgerpc/bin/sms_login_finalize_python3.py
CITIZEN_HASH_FILE="/etc/os2borgerpc/citizen_hash.txt"
LOG_ID_FILE="/etc/os2borgerpc/login_log_id.txt"
SMS_LOGOUT_SCRIPT="/etc/lightdm/greeter-setup-scripts/sms_logout.py"
SMS_LOGOUT_SERVICE="/etc/systemd/system/sms_logout.service"
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
    sed -i '/common-auth/i# OS2borgerPC SMS login\nauth [success=4 default=ignore] pam_succeed_if.so user = user' $LIGHTDM_PAM

    # 2. All other users use regular login and conversely skip Cicero
    sed -i "/include common-account/i# OS2borgerPC SMS login\nauth [success=1 default=ignore] pam_succeed_if.so user != user\nauth required pam_python.so $PAM_PYTHON_MODULE" $LIGHTDM_PAM
  fi

# Separated out because the pam module cannot run if you import the admin_client or re
cat << EOF > $SMS_LOGIN_INTERFACE_PYTHON3
#! /usr/bin/env python3

import sys
from subprocess import check_output
import os2borgerpc.client.admin_client as admin_client
import socket
import re

book_specific_pc = $BOOK_SPECIFIC_PC
require_booking = $REQUIRE_BOOKING

def sms_validate(phone_number, password):
    # The phone number should only contain digits
    if not re.fullmatch(f"^\d+$", phone_number):
        return 0, "invalid_number"

    # Add the country code to the phone number
    country_code = "+467" # +467 is for Swedish numbers, Danish numbers should start with +45
    phone_number = country_code + phone_number

    host_address = (
        check_output(["get_os2borgerpc_config", "admin_url"]).decode().strip()
    )
    # Example URL:
    # host_address = "https://os2borgerpc-admin.magenta.dk"

    # For local testing with VirtualBox
    # host_address = "http://10.0.2.2:9999"

    # Obtain the site and convert from bytes to regular string
    # and remove the trailing newline
    site = check_output(["get_os2borgerpc_config", "site"]).decode().strip()

    # If booking a specific PC is required, obtain the name of this PC,
    # convert from bytes to regular string and remove the trailing newline
    if book_specific_pc:
        pc_name = check_output(["get_os2borgerpc_config", "hostname"]).decode().strip()
    else:
        pc_name = None

    # Values it can return - see sms_login here:
    # https://github.com/OS2borgerPC/admin-site/blob/master/admin_site/system/rpc.py
    # For reference:
    #   time < 0: User is quarantined and may login in -time minutes. Alternatively,
    #             the next matching booking starts in -time minutes
    #   time = 0: Unable to authenticate.
    #   time > 0: The user is allowed r minutes of login time.
    admin = admin_client.OS2borgerPCAdmin(host_address + "/admin-xml/")
    try:
        time, citizen_hash = admin.sms_login(phone_number, password, site, require_booking, pc_name)
    except (socket.gaierror, TimeoutError, ConnectionError):
        time = ""
        citizen_hash = ""

    # Time is received in minutes
    return time, citizen_hash


if __name__ == "__main__":
    print(sms_validate(sys.argv[1], sys.argv[2]))
EOF

  chmod u+x $SMS_LOGIN_INTERFACE_PYTHON3

# Separated out because the pam module cannot run if you import the admin_client
cat << EOF > $LOGIN_FINALIZE_INTERFACE_PYTHON3
#! /usr/bin/env python3

import sys
from subprocess import check_output
import os2borgerpc.client.admin_client as admin_client
import socket

require_booking = $REQUIRE_BOOKING
save_log = $SAVE_LOG

def sms_login_finalize(phone_number):

    host_address = (
        check_output(["get_os2borgerpc_config", "admin_url"]).decode().strip()
    )
    # Example URL:
    # host_address = "https://os2borgerpc-admin.magenta.dk"

    # For local testing with VirtualBox
    # host_address = "http://10.0.2.2:9999"

    # Obtain the site and convert from bytes to regular string
    # and remove the trailing newline
    site = check_output(["get_os2borgerpc_config", "site"]).decode().strip()

    admin = admin_client.OS2borgerPCAdmin(host_address + "/admin-xml/")
    try:
        log_id = admin.sms_login_finalize(phone_number, site, require_booking, save_log)
    except (socket.gaierror, TimeoutError, ConnectionError):
        log_id = ""

    return log_id


if __name__ == "__main__":
    print(sms_login_finalize(sys.argv[1]))
EOF

  chmod u+x $LOGIN_FINALIZE_INTERFACE_PYTHON3

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

cat << EOF > $SMS_LOGOUT_SCRIPT
#! /usr/bin/env python3

from subprocess import check_output
import os2borgerpc.client.admin_client as admin_client
from os.path import exists
from os import remove
import socket

def sms_logout():
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
            result = admin.sms_logout(citizen_hash, log_id)
        except (socket.gaierror, TimeoutError, ConnectionError):
            result = ""


if __name__ == "__main__":
    sms_logout()
EOF

  chmod 700 "$SMS_LOGOUT_SCRIPT"

# This service ensures that the citizen is logged out
# even if they shut down or reboot the machine
cat << EOF > $SMS_LOGOUT_SERVICE
[Unit]
Description=SMS logout service
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=simple
ExecStart=$SMS_LOGOUT_SCRIPT

[Install]
WantedBy=halt.target reboot.target shutdown.target
EOF

systemctl enable "$(basename $SMS_LOGOUT_SERVICE)"

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
save_log = $SAVE_LOG

def generate_password(length):
    # Generate a pseudo-random password with a desired length
    numbers = string.digits
    password = "".join(random.choice(numbers) for n in range(length))
    return password


def pam_sm_authenticate(pamh, flags, argv):
    # print(pamh.fail_delay)
    # http://pam-python.sourceforge.net/doc/html/
    phone_number_msg = pamh.Message(pamh.PAM_PROMPT_ECHO_OFF, "Skriv in telefonnummer")
    phone_number_response = pamh.conversation(phone_number_msg)
    phone_number = phone_number_response.resp

    if not len(phone_number) == 8:
        result_msg = pamh.Message(
            pamh.PAM_ERROR_MSG, "Ogiltigt nummer. Ange 8 siffror."
        )
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

    # Generate a six-digit password
    current_password = generate_password(6)

    sms_booking_response = check_output(
        ["$SMS_LOGIN_INTERFACE_PYTHON3", phone_number, current_password]
    ).strip()

    if not sms_booking_response:
        result_msg = pamh.Message(
            pamh.PAM_ERROR_MSG, "Anslutningen misslyckades. Försök senare."
        )
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

    # sms_booking_response is a binary string containing (time, 'citizen_hash')
    # This format determines the necessary commands to extract time and citizen_hash
    time = int(sms_booking_response.split(b", ")[0][1:])
    citizen_hash = str(sms_booking_response.split(b", ")[1][:-1])[1:-1]

    if citizen_hash == "sms_failed":
        result_msg = pamh.Message(
            pamh.PAM_ERROR_MSG, "SMS kunde inte skickas. Försök senare."
        )
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

    if citizen_hash == "invalid_number":
        result_msg = pamh.Message(
            pamh.PAM_ERROR_MSG, "Felaktig input. Ange endast siffror."
        )
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

    if citizen_hash == "no_booking" and book_specific_pc:
        result_msg = pamh.Message(
            pamh.PAM_ERROR_MSG,
            "Ingen matchande bokning för den här datorn."
        )
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR
    elif citizen_hash == "no_booking" and not book_specific_pc:
        result_msg = pamh.Message(
            pamh.PAM_ERROR_MSG,
            "Du har inte bokat en dator under den här tiden."
        )
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

    if citizen_hash == "logged_in":
        result_msg = pamh.Message(
            pamh.PAM_ERROR_MSG,
            "Du är redan inloggad på en annan dator."
        )
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

    if time > 0:

        password_msg = pamh.Message(pamh.PAM_PROMPT_ECHO_OFF, "Engångslösenord")
        # Note: Response object also contains a ret_code
        password_response = pamh.conversation(password_msg)
        password = password_response.resp

        # Three attempts to enter the correct password
        if password != current_password:
            result_msg = pamh.Message(pamh.PAM_ERROR_MSG, "Fel lösenord. Två försök kvar.")
            pamh.conversation(result_msg)
            password_msg = pamh.Message(pamh.PAM_PROMPT_ECHO_OFF, "Engångslösenord")
            # Note: Response object also contains a ret_code
            password_response = pamh.conversation(password_msg)
            password = password_response.resp
            if password != current_password:
                result_msg = pamh.Message(pamh.PAM_ERROR_MSG, "Fel lösenord. Ett försök kvar.")
                pamh.conversation(result_msg)
                password_msg = pamh.Message(pamh.PAM_PROMPT_ECHO_OFF, "Engångslösenord")
                # Note: Response object also contains a ret_code
                password_response = pamh.conversation(password_msg)
                password = password_response.resp
                if password != current_password:
                    result_msg = pamh.Message(pamh.PAM_ERROR_MSG, "Fel lösenord. Inga försök kvar.")
                    pamh.conversation(result_msg)

                    return pamh.PAM_AUTH_ERR

        # We only need the finalize function if we are not using booking
        # or if a log should be saved
        if not require_booking or save_log:
            log_id = check_output(
                ["$LOGIN_FINALIZE_INTERFACE_PYTHON3", phone_number]
            ).strip()
            if log_id:
                with open("$LOG_ID_FILE", "w") as f:
                    f.write(log_id)

        # Only remember the logged in citizen if login succeeds, i.e. time > 0
        # No need to remember the citizen if booking is required, as the
        # quarantine system is not used in that case
        if not require_booking:
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
        result_msg = pamh.Message(pamh.PAM_ERROR_MSG, "Inloggningen misslyckades.")
        pamh.conversation(result_msg)

        return pamh.PAM_AUTH_ERR

    elif time < 0:
        time_pos = abs(time)
        hours = str(time_pos // 60)
        minutes = str(time_pos % 60)
        if require_booking:  # The next matching booking is in the future
            result_msg = pamh.Message(
                pamh.PAM_ERROR_MSG,
                "Din bokning börjar om " + hours + "t " + minutes + "m.",
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

else # Cleanup and remove the SMS/booking integration
  # Remove SMS/booking integration from /etc/pam.d/ files
  sed -i '/pam_succeed_if.so user = user/d' $LIGHTDM_PAM
  sed -i '/# OS2borgerPC SMS login/d' $LIGHTDM_PAM
  sed -i '/pam_succeed_if.so user != user/d' $LIGHTDM_PAM
  sed -i "\@auth required pam_python.so@d" $LIGHTDM_PAM

  systemctl disable "$(basename $SMS_LOGOUT_SERVICE)"

  rm --force $SMS_LOGIN_INTERFACE_PYTHON3 $PAM_PYTHON_MODULE \
  $SMS_LOGOUT_SCRIPT $CITIZEN_HASH_FILE $SMS_LOGOUT_SERVICE \
  $LOG_ID_FILE
fi
