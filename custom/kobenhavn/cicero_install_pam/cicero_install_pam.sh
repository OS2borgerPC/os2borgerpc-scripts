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
  # 1. User skips regular login and only uses Cicero.
  # 2. All other users use regular login and conversely skip Cicero
  # Idempotency: Don't add it multiple times if run multiple times
  if ! grep -q "pam_python" "$LIGHTDM_PAM"; then
    sed -i '/common-auth/i# OS2borgerPC Cicero\nauth [success=4 default=ignore] pam_succeed_if.so user = user' $LIGHTDM_PAM

    # The one immediately below resulted in lightdm ubuntu errors
	  #sed -i '/include common-account/i# OS2borgerPC Cicero\nauth sufficient pam_succeed_if.so user != user\nauth required pam_python.so' $LIGHTDM_PAM
	  sed -i "/include common-account/i# OS2borgerPC Cicero\nauth [success=1 default=ignore] pam_succeed_if.so user != user\nauth required pam_python.so $PAM_PYTHON_MODULE" $LIGHTDM_PAM
  fi

  # Separated out because pam_python is python2 while our client is python3
cat << EOF > $CICERO_INTERFACE_PYTHON3
#! /usr/bin/env python3

import sys
from subprocess import check_output
import os2borgerpc.client.admin_client as admin_client


def cicero_validate(cicero_user, cicero_pass):

    # host_address="https://os2borgerpc-admin.magenta.dk"
    # host_address="http://172.16.120.66:9999/admin-xml/"
    host_address = "http://10.0.2.2:9999/admin-xml/"

    # Obtain the site and convert from bytes to regular string
    # and remove the trailing newline
    site = check_output(['get_os2borgerpc_config', 'site']).decode().replace('\n', '')

    # Values it can return - see cicero_login here:
    # https://github.com/OS2borgerPC/admin-site/blob/master/admin_site/system/rpc.py
    # For reference:
    #   r < 0: User is quarantined and may login in -r minutes
    #   r = 0: Unable to authenticate.
    #   r > 0: The user is allowed r minutes of login time.
    admin = admin_client.OS2borgerPCAdmin(host_address)
    time = admin.citizen_login(cicero_user, cicero_pass, site)
    # DEBUG:
    # with open('/home/superuser/log.txt', 'w') as f:
    #  f.write(f"User: {cicero_user}, Password: {cicero_pass}, Site: {site}, Time: {time}")

    # Time is received in minutes
    return time


if __name__ == "__main__":
    print(cicero_validate(sys.argv[1], sys.argv[2]))
EOF

  chmod u+x $CICERO_INTERFACE_PYTHON3

  # Note: pam_python currently runs on python 2.7.18, not python3!
cat << EOF > $PAM_PYTHON_MODULE
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
        msg3 = pamh.Message(pamh.PAM_ERROR_MSG, "Forbindelse kunne ikke oprettes. Proev igen senere.")
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
