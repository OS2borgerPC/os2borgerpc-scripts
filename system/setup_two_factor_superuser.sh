#! /usr/bin/env sh

# Sets up two-factor authentication for Ubuntu using the open standard used by
# google-authenticator, which many apps support, such as:
# Duo Mobile, Authy, Microsoft Authenticator
# and of course Google Authenticator itself.

# Arguments
# 1: Whether to enable or disable two factor authentication for the user
#    Alternately "kode" generates a secret for you and prints it to screen
# 2: The secret to use, as we need the same secret across multiple machines.
#    A valid value is 26 characters consisting of A-Z 0-9
#   (at least that's the format /usr/bin/google-authenticator generates)

set -x

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"
SECRET="$2"

[ "$#" -lt 1 ] && printf "The script needs at least one argument" && exit 1

USER=superuser
AUTHENTICATOR_CONFIG=/home/superuser/.google_authenticator
PAM_CONFIG=/etc/pam.d/common-auth
PAM_TEXT1="auth [default=1 success=ignore] pam_succeed_if.so quiet user ingroup superuser"
PAM_TEXT2="auth required pam_google_authenticator.so"
export DEBIAN_FRONTEND=noninteractive

install_ga() {
  apt-get update --assume-yes "$1"
  apt-get install --assume-yes libpam-google-authenticator "$1"
}

if [ "$ACTIVATE" = 'kode' ]; then
  install_ga --quiet
  printf "Sikkerhedsnøgle"
  # All these parameters are basically random, they're just to ensure that it's
  # noninteractive so we immediately get a secret key and don't have to use
  # e.g. expect.
  google-authenticator --time-based --window-size 5 --force --disallow-reuse --rate-limit 3 \
  --rate-time 30 --emergency-codes 1 2>/dev/null \
  | grep "secret key" | awk 'NF{ print $NF }'
  # Somehow saving this file to /dev/null (--secret /dev/null) means google-authenticator
  # starks looking for the key there?! So instead we create it at the normal location
  # and then delete it afterwards. It must have another config file then? Maybe the pam module is
  # updated with the non-standard config location?
  rm /root/.google_authenticator
  # Another possible way we could generate this
  #printf '%s\n' "$(openssl rand -hex 26 | tr "[:lower:]" "[:upper:]")"
elif [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] && \
   [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then

  install_ga

  # Make PAM require two factor for the superuser, both for direct login and su
  if ! grep -q "pam_google_authenticator" $PAM_CONFIG; then

		printf '%s\n' "$PAM_TEXT1" "$PAM_TEXT2" >> $PAM_CONFIG
  fi

  # Create the config file for the superuser
  # TOTP_AUTH         | Time based authentication
  # DISALLOW_REUSE    | An authentication token can only be used in one attempt
  # RATE_LIMIT        | Limit to 3 login attempts every 30 seconds (default)
  # WINDOW_SIZE       | Allow using the two previous, current and two next
  #                     codes in case of time synchronisation issues
  # The following lines are emergency codes. The interactive mode defaults to
  # 5, and 1-10 are valid values it claims
  # Most values here are simply the defaults from its interactive mode
  # Confusingly lines prefixed with " are NOT comments?!
	cat <<- EOF > $AUTHENTICATOR_CONFIG
		$SECRET
		" RATE_LIMIT 3 30
		" WINDOW_SIZE 5
		" DISALLOW_REUSE
		" TOTP_AUTH
		51460423
	EOF
  # TODO!: ^ Generate this recovery code!!

  # Fixing the permissions to what the google-authenticator command generates,
  # as it appears to be particular about this
  chown $USER:$USER $AUTHENTICATOR_CONFIG
  chmod 400 $AUTHENTICATOR_CONFIG

  #CODE="otpauth://totp/$USER@$(hostname)?secret=$SECRET&issuer=$(hostname)"
  CODE="otpauth://totp/$USER@$(hostname)%3Fsecret%3D$SECRET%26issuer%3D$(hostname)"

  printf "%s\n" "QR-koden er:" "$CODE"

  # For debugging uncomment this to get a link to a QR with it:
  printf "%s\n" "https://www.google.com/chart?chs=200x200&chld=M|0&cht=qr&chl=$CODE"
else

  # Remove the two factor authenticator's config
  rm $AUTHENTICATOR_CONFIG

  # Wish there was a builtin way to pass in a literal string so escaping
  # wouldn't be necessary
  # https://stackoverflow.com/a/29613573/1172409
  PAM_TEXT1_ESCAPED=$(echo "$PAM_TEXT1" | sed 's/[^^]/[&]/g; s/\^/\\^/g') # escape it.
  sed --in-place "/$PAM_TEXT1_ESCAPED/d" $PAM_CONFIG
  sed --regexp-extended --in-place "/$PAM_TEXT2/d" $PAM_CONFIG

  # Uninstall the two factor authenticator
  apt-get remove --assume-yes libpam-google-authenticator
fi
