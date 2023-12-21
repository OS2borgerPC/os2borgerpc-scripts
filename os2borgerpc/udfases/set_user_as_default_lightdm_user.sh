#! /usr/bin/env sh

# Inspiration: https://askubuntu.com/questions/59199/can-i-set-a-default-user-in-lightdm

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

ACTIVATE=$1
USER=user
FILE=/var/lib/lightdm/.cache/unity-greeter/state

mkdir --parents "$(dirname "$FILE")"

if [ "$ACTIVATE" = 'True' ]; then
  cat <<- EOF > "$FILE"
[greeter]
last-user=$USER
EOF
  chown --recursive lightdm:lightdm /var/lib/lightdm/
  chattr +i $FILE
else
  chattr -i $FILE
fi