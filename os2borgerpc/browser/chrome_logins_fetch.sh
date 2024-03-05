#! /usr/bin/env sh

# Fetches the logins file from a logged in user and sends them to the adminsite

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "This script has not been designed to be run on a Kiosk-machine. Exiting."
  exit 1
fi

OUR_USER="user"
LOGINS="/home/$OUR_USER/.config/google-chrome/Default/Login Data"

if [ -f "$LOGINS" ]; then
  echo "This is the file, base64 encoded to prevent issues with special characters (empty lines not included):"
  printf "\n\n"
  base64 "$LOGINS"
  printf "\n\n"
else
  echo "Failed fetching login data! Maybe the profile has a different name than Default?"
  echo "Listing files in the root of the google-chrome dir:"
  ls -l /home/$OUR_USER/.config/google-chrome/
  exit 1
fi
