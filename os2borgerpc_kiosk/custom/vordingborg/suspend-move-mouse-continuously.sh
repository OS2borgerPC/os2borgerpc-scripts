#! /usr/bin/env sh

# ...As a workaround to prevent suspend.
# Restart not necessary, crontab should detect that its config was updated.
#
# Arguments:
# 1: Enable/Disable the program?
# 2: Interval to run at.
#
# Author: mfm@magenta.dk

set -ex

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"
INTERVAL=$2 # Example: 10 for every 10 minutes

SCRIPT_PATH="/usr/share/os2borgerpc/bin/move-mouse-continuously.sh"
mkdir -p "$(dirname "$SCRIPT_PATH")"
USER=chrome

delete_entry_crontab() {
  (crontab -u $USER -l || true ) | sed "\,$SCRIPT_PATH,d" | crontab -u $USER -
}


if [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] && \
   [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then

  export DEBIAN_FRONTEND=noninteractive
  apt-get install -y xdotool

cat << EOF > $SCRIPT_PATH
  #! /usr/bin/env sh

  DISPLAY=:0 xdotool mousemove_relative 1 1
  sleep 2
  DISPLAY=:0 xdotool mousemove_relative -- -1 -1
EOF

  chmod +x $SCRIPT_PATH
  chown $USER:$USER $SCRIPT_PATH

  delete_entry_crontab # In case it's already there, for idempotency

  # Append to crontab: Take the current crontab, add the new line, make that
  # the new crontab
  # "|| true" is there if crontab is empty 
  # as otherwise set -e, if enabled, will stop execution there
  (crontab -u $USER -l || true; echo "*/$INTERVAL * * * * $SCRIPT_PATH") | crontab -u $USER -

else
  # Take the current crontab, remove the line matching SCRIPT_PATH, 
  # make the result the new crontab
  # When using a nonstandard character as delimiter (,) it must be escaped the
  # first time:
  # https://stackoverflow.com/a/25173311/1172409
  delete_entry_crontab
fi
