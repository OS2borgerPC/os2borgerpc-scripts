#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    shutdown_and_wakeup.sh --args <hours> <minutes> <hours>
#%
#% DESCRIPTION
#%    This is a script to make a OS2BorgerPC machine shutdown at a certain time.
#%    Synopsis:
#%
#%      shutdown_and_wakeup.sh <hours> <minutes> <hours>
#%
#%    to enable shutdown mechanism.
#%
#%      shutdown_and_wakeup.sh --off
#%
#%    to disable.
#%
#%    We'll suppose the user only wants to have regular shutdown once a day
#%    as specified by the <hours> and <minutes> parameters. Thus, any line in
#%    crontab already specifying a shutdown will be deleted before a new one is
#%    inserted.
#%    We'll also suppose the user wants the machine to wakeup after X numbers
#%     of hours after shutdown everyday.
#%
#================================================================
#- IMPLEMENTATION
#-    version         shutdown_and_wakeup.sh (magenta.dk) 0.0.1
#-    author          Danni Als
#-    copyright       Copyright 2018, Magenta Aps"
#-    license         GNU General Public License
#-    email           danni@magenta.dk
#-
#================================================================
#  HISTORY
#     2018/12/12 : danni : Script creation - based on shutdown_at_time.sh
#     2018/12/12 : danni : Changed paramter count from 2 to 3.
#     Corrected sed delete regex.
#     2021/05/06 : mfm : Switch from sudo -u user crontab to crontab -u
#                        user to not trigger our sudo warnings
#
#================================================================
# END_OF_HEADER
#================================================================

set -x

WAKE_PLAN_FILE=/etc/os2borgerpc/plan.json
SCHEDULED_OFF_SCRIPT="/usr/local/lib/os2borgerpc/scheduled_off.sh"

if [ -f $WAKE_PLAN_FILE ]; then
  echo "Dette script kan ikke anvendes på en PC, der er tilknyttet en tænd/sluk tidsplan."
  exit 1
fi

TCRON=/tmp/oldcron
USERCRON=/tmp/usercron
MESSAGE="Denne computer lukker ned om fem minutter"

crontab -l > $TCRON
crontab -u user -l > $USERCRON


if [ "$1" == "--off" ]; then

    if [ -f $TCRON ]; then
        sed -i -e "/\/rtcwake/d" $TCRON
        sed -i "/scheduled_off/d" $TCRON
        crontab $TCRON
    fi

    if [ -f $USERCRON ]; then
        sed -i -e "/lukker/d" $USERCRON
        crontab -u user $USERCRON
    fi

    rm --force $SCHEDULED_OFF_SCRIPT

else

    if [ $# -gt 2 ]; then
        cat <<EOF > $SCHEDULED_OFF_SCRIPT
#!/usr/bin/env bash

MODE=\$1
DURATION=\$2

pkill -KILL -u user
pkill -KILL -u superuser
/usr/sbin/rtcwake --mode \$MODE --seconds \$DURATION
EOF

        chmod 700 $SCHEDULED_OFF_SCRIPT
        HOURS=$1
        MINUTES=$2
        SECONDS_TO_WAKEUP=$(( 3600 * $3))

        # If not set set it to the previous script default: off
        [ -z "$4" ] && MODE="off" || MODE=$4

        # We still remove shutdown lines, if any
        if [ -f $TCRON ]; then
            sed -i -e "/\/rtcwake/d" $TCRON
            sed -i "/scheduled_off/d" $TCRON
        fi
        if [ -f $USERCRON ]; then
            sed -i -e "/lukker/d" $USERCRON
        fi
        # Assume the parameters are already validated as integers.
        echo "$MINUTES $HOURS * * * $SCHEDULED_OFF_SCRIPT $MODE $SECONDS_TO_WAKEUP" >> $TCRON
        crontab $TCRON

        MINM5P60=$(( $(( MINUTES - 5)) + 60))
        # Rounding minutes
        MINS=$(( MINM5P60 % 60))
        HRCORR=$(( 1 - $(( MINM5P60 / 60))))
        HRS=$(( HOURS - HRCORR))
        HRS=$(( $(( HRS + 24)) % 24))
        # Now output to user's crontab as well
        echo "$MINS $HRS * * * XDG_RUNTIME_DIR=/run/user/\$(id -u) /usr/bin/notify-send \"$MESSAGE\"" >> $USERCRON
        crontab -u user $USERCRON
    else
        echo "Usage: shutdown_and_wakeup.sh [--off] [hours minutes] [hours]"
    fi

fi

rm --force $TCRON
