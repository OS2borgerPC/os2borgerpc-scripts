#! /usr/bin/env sh

# Arguments:
#   1: Whether to enable or disable Cicero login. 'yes' enables, 'no' disables.

# Prerequisites:
# 1. Run the script: user_automatic_login.sh --disable

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"

export DEBIAN_FRONTEND=noninteractive
LIGHTDM_PAM=/etc/pam.d/lightdm
# Put our module where PAM modules normally are
PAM_PYTHON_MODULE=/usr/lib/x_-linux-gnu/security/os2borgerpc-cicero-pam-module.py

if [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] && \
   [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then
  apt-get update --assume-yes
  if ! apt-get install --assume-yes libpam-python; then
    echo "Error installing dependencies."
    exit 1
  fi

  # Idempotency: Don't add it multiple times if run multiple times
  if ! grep -q "pam_python" "$LIGHTDM_PAM"; then
    sed -i '/common-auth/i# OS2borgerPC Cicero\nauth [success=4 default=ignore] pam_succeed_if.so user = user' $LIGHTDM_PAM

		cat <<- EOF >> $LIGHTDM_PAM
			# OS2borgerPC Cicero
			auth sufficient pam_succeed_if.so user != user
			auth required pam_python.so $PAM_PYTHON_MODULE
		EOF
  fi

	cat <<- EOF > $PAM_PYTHON_MODULE
    import os2borgerpc.client.admin_client as admin_client
    #host_address="https://os2borgerpc-admin.magenta.dk"
    host_address="http://172.16.120.66:9999/admin-xml/"
    admin = admin_client.OS2borgerPCAdmin(host_address)
    admin.citizen_login('1111111111', '1234', 'magenta')
    from subprocess import check_output

		# From pam_permit python-pam example. Do we need it?:

		def pam_sm_authenticate(pamh, flags, argv):

		  #print(pamh.fail_delay)
		  # http://pam-python.sourceforge.net/doc/html/
		  msg1 = pamh.Message(pamh.PAM_PROMPT_ECHO_ON, "Laanernummer eller CPR")
		  msg2 = pamh.Message(pamh.PAM_PROMPT_ECHO_OFF, "Kodeord")
		  resp1 = pamh.conversation(msg1) # Reponse object also contains a ret_code
		  resp2 = pamh.conversation(msg2)
		  #print(resps)
		  cicero_user = resp1.resp
		  cicero_pass = resp2.resp

      site = check_output(['get_os2borgerpc_config','site'])

      # time = cicero_login(cicero_user, cicero_pass, site)

		  if cicero_user == "allan" or cicero_user == "123456781234":
		    return pamh.PAM_SUCCESS
		  else:
		    msg3 = pamh.Message(pamh.PAM_ERROR_MSG, "Du har karantaene.")
		    pamh.conversation(msg3)
		    return pamh.PAM_AUTH_ERR

		  # From pam_permit python-pam example. Do we need it?:
		  try:
		    user = pamh.get_user(None)
		  except pamh.exception as e:
		    return e.pam_result
		  if user == None:
		    pam.user = DEFAULT_USER


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
  sed -i '/[success=4 default=ignore] pam_succeed_if.so user = user/d' $LIGHTDM_PAM
  sed -i '/# OS2borgerPC Cicero/d' $LIGHTDM_PAM
  sed -i '/auth sufficient pam_succeed_if.so user != user/d' $LIGHTDM_PAM
  sed -i "\@auth required pam_python.so $PAM_PYTHON_MODULE@d" $LIGHTDM_PAM

  # Possibly remove libpam-python as we don't need it anymore
  # - at least this functionality no longer does
  # apt-get remove --assume-yes libpam-python
fi
