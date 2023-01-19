#! /usr/bin/env sh

# Inspiration: https://askubuntu.com/questions/59199/can-i-set-a-default-user-in-lightdm

ACTIVATE=$1
USER=user
FILE=/var/lib/lightdm/.cache/unity-greeter/state

if [ "$ACTIVATE" = 'True' ]; then
  cat <<- EOF > "$FILE"
    [greeter]
    last-user=$USER
EOF
  chattr +i $FILE
else
  chattr -i $FILE
fi