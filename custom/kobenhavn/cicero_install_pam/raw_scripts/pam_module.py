#! /usr/bin/env python2

from subprocess import check_output


def pam_sm_authenticate(pamh, flags, argv):

    # print(pamh.fail_delay)
    # http://pam-python.sourceforge.net/doc/html/
    username_msg = pamh.Message(pamh.PAM_PROMPT_ECHO_OFF, "Laanernummer eller CPR")
    password_msg = pamh.Message(pamh.PAM_PROMPT_ECHO_OFF, "Kodeord")
    # Note: Response object also contains a ret_code
    username_response = pamh.conversation(username_msg)
    password_response = pamh.conversation(password_msg)
    cicero_user = username_response.resp
    cicero_pass = password_response.resp

    cicero_response = check_output(
        ["$CICERO_INTERFACE_PYTHON3", cicero_user, cicero_pass]
    )

    if not cicero_response:
        result_msg = pamh.Message(
            pamh.PAM_ERROR_MSG, "Forbindelse kunne ikke oprettes. Proev igen senere."
        )
        pamh.conversation(result_msg)
        return pamh.PAM_AUTH_ERR

    time = int(cicero_response)

    if time > 0:
        with open('$LOGOUT_TIMER_CONF', 'w') as f:
            # Convert minutes to seconds, which the timer expects.
            f.write("TIME_SECONDS=" + str(time * 60))
        return pamh.PAM_SUCCESS
    elif time == 0:
        result_msg = pamh.Message(pamh.PAM_ERROR_MSG, "Login mislykkedes.")
        pamh.conversation(result_msg)
        return pamh.PAM_AUTH_ERR
    elif time < 0:
        result_msg = pamh.Message(
            pamh.PAM_ERROR_MSG,
            "Du kan logge ind igen om " + str(abs(time)) + " minutter."
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
