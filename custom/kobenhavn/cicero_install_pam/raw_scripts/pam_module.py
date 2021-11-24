from subprocess import check_output


def pam_sm_authenticate(pamh, flags, argv):

    # print(pamh.fail_delay)
    # http://pam-python.sourceforge.net/doc/html/
    msg1 = pamh.Message(pamh.PAM_PROMPT_ECHO_OFF, "Laanernummer eller CPR")
    msg2 = pamh.Message(pamh.PAM_PROMPT_ECHO_OFF, "Kodeord")
    resp1 = pamh.conversation(msg1)  # Reponse object also contains a ret_code
    resp2 = pamh.conversation(msg2)
    cicero_user = resp1.resp
    cicero_pass = resp2.resp

    time = int(check_output(["$CICERO_INTERFACE_PYTHON3", cicero_user, cicero_pass]))

    if time > 0:
        with open('$LOGOUT_TIMER_CONF', 'w') as f:
            # Convert minutes to seconds, which the timer expects.
            f.write("TIME_SECONDS=" + str(time * 60))
        return pamh.PAM_SUCCESS
    elif time == 0:
        msg3 = pamh.Message(pamh.PAM_ERROR_MSG, "Login mislykkedes.")
        pamh.conversation(msg3)
        return pamh.PAM_AUTH_ERR
    elif time < 0:
        msg3 = pamh.Message(
            pamh.PAM_ERROR_MSG,
            "Du kan logge ind igen om " + str(abs(time)) + " minutter."
        )
        pamh.conversation(msg3)
        return pamh.PAM_AUTH_ERR
    else:
        msg3 = pamh.Message(
            pamh.PAM_ERROR_MSG, "Forbindelse kunne ikke oprettes. Proev igen senere."
        )
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
