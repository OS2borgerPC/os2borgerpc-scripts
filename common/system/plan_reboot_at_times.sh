#! /usr/bin/env bash

set -x

ACTIVATE=$1
TIMES=$2
ROOTCRON_TMP="/tmp/oldcron"
USERCRON_TMP="/tmp/usercron"

if grep "LANG=" /etc/default/locale | grep "sv"; then
  MESSAGE="Den här datorn kommer att starta om efter fem minuter"
elif grep "LANG=" /etc/default/locale | grep "da"; then
  MESSAGE="Denne computer genstarter om fem minutter"
else
  MESSAGE="This computer will reboot in five minutes"
fi

crontab -l > $ROOTCRON_TMP

sed --in-place "/reboot/d" $ROOTCRON_TMP

if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  crontab -u user -l > $USERCRON_TMP
  sed --in-place "/starta om/d ; /genstarter/d ; /reboot/d" $USERCRON_TMP
fi

if [ "$ACTIVATE" = "True" ]; then

  IFS=", " read -ra TIMES_ARRAY <<< "$TIMES"
  for TIME in "${TIMES_ARRAY[@]}"; do
    IFS=":" read -ra HOUR_MIN <<< "$TIME"
    HOURS=${HOUR_MIN[0]}
    MINUTES=${HOUR_MIN[1]}
    echo "$MINUTES $HOURS * * * /usr/sbin/reboot" >> $ROOTCRON_TMP
    if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
      MINM5P60=$(( $(( MINUTES - 5)) + 60))
      # Rounding minutes
      MINS=$(( MINM5P60 % 60))
      HRCORR=$(( 1 - $(( MINM5P60 / 60))))
      HRS=$(( HOURS - HRCORR))
      HRS=$(( $(( HRS + 24)) % 24))
      echo "$MINS $HRS * * * XDG_RUNTIME_DIR=/run/user/\$(id -u) /usr/bin/notify-send \"$MESSAGE\"" >> $USERCRON_TMP
    fi
  done
fi

crontab $ROOTCRON_TMP
rm --force $ROOTCRON_TMP

if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  crontab -u user $USERCRON_TMP
  rm --force $USERCRON_TMP
fi
