#! /usr/bin/env sh

# Create a persistent directory in the user's home directory
# Logout or restart to take effect
#
# Arguments
#   1: Whether to add or remove the shared dir
#      'yes' adds, 'no' removes
#   2: The name of the shared dir to add or remove
#
# Author: mfm@magenta.dk
# Credits: carstena@magenta.dk

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"
NAME="$2"

DIR=/var/local/$NAME
USERNAME=user
SHADOW=.skjult

# Determine the name of the user desktop directory. This is done via xdg-user-dir,
# which checks the /home/user/.config/user-dirs.dirs file. To ensure this file exists,
# we run xdg-user-dirs-update, which generates it based on the environment variable
# LANG. This variable is empty in lightdm so we first export it
# based on the value stored in /etc/default/locale
export "$(grep LANG= /etc/default/locale)"
runuser -u user xdg-user-dirs-update
DESKTOP=$(basename "$(runuser -u $USERNAME xdg-user-dir DESKTOP)")

if [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] && \
   [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then

  mkdir --parents "$DIR"
  mkdir --parents "/home/$SHADOW/$DESKTOP"
  chown $USERNAME:$USERNAME "$DIR"
  ln --symbolic "$DIR" "/home/$SHADOW/$DESKTOP/$NAME"

else # Delete the persistent dir with the specified NAME

  rm --force --recursive "$DIR"
  rm --force "/home/$SHADOW/$DESKTOP/$NAME"
fi
