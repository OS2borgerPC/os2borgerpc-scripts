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

TCRON=/tmp/oldcron
USERCRON=/tmp/usercron
MESSAGE="Denne computer lukker ned om fem minutter"

crontab -l > $TCRON
crontab -u user -l > $USERCRON


if [ "$1" == "--off" ]; then

    if [ -f $TCRON ]; then
        sed -i -e "/\/rtcwake/d" $TCRON
        crontab $TCRON
    fi

    if [ -f $USERCRON ]; then
        sed -i -e "/lukker/d" $USERCRON
        crontab -u user $USERCRON
    fi

else

    if [ $# -gt 2 ]; then
        HOURS=$1
        MINUTES=$2
        SECONDS_TO_WAKEUP=$(( 3600 * $3))

        # If not set set it to the previous script default: off
        [ -z "$4" ] && MODE="off" || MODE=$4

        # We still remove shutdown lines, if any
        if [ -f $TCRON ]; then
            sed -i -e "/\/rtcwake/d" $TCRON
        fi
        if [ -f $USERCRON ]; then
            sed -i -e "/lukker/d" $USERCRON
        fi
        # Assume the parameters are already validated as integers.
        echo "$MINUTES $HOURS * * * /usr/sbin/rtcwake --mode $MODE --seconds $SECONDS_TO_WAKEUP" >> $TCRON
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
