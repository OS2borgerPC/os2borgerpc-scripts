#! /usr/bin/env python2
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

    time = int(cicero_response)

    if time > 0:
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
