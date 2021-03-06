#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    shutdown_at_time.sh
#%
#% DESCRIPTION
#%    This is a script to make a OS2BorgerPC machine shutdown at a certain time.
#%    Synopsis:
#%
#%      shutdown_at_time.sh <hours> <minutes>
#%
#%    to enable shutdown mechanism.
#%
#%      shutdown_at_time.sh --off
#%
#%    to disable.
#%
#%    We'll suppose the user only wants to have regular shutdown once a day
#%    as specified by the <hours> and <minutes> parameters. Thus, any line in
#%    crontab already specifying a shutdown will be deleted before a new one is
#%    inserted.
#%
#================================================================
#- IMPLEMENTATION
#-    version         shutdown_at_time.sh (magenta.dk) 0.0.1
#-    author          Danni Als
#-    copyright       Copyright 2018, Magenta Aps"
#-    license         GNU General Public License
#-    email           danni@magenta.dk
#-
#================================================================
#  HISTORY
#     2018/12/12 : danni : Script creation - based on an already existing script.
#
#================================================================
# END_OF_HEADER
#================================================================



TCRON=/tmp/oldcron
USERCRON=/tmp/usercron
MESSAGE="Denne computer lukker ned om fem minutter"

crontab -l > $TCRON
crontab -u user -l > $USERCRON


if [ "$1" == "--off" ]
then

    if [ -f $TCRON ]
    then
        sed -i -e "/\/sbin\/shutdown/d" $TCRON
        crontab $TCRON
    fi

    if [ -f $USERCRON ]
    then
        sed -i -e "/lukker/d" $USERCRON
        crontab -u user $USERCRON
    fi

else

    if [ $# == 2 ]
    then
        HOURS=$1
        MINUTES=$2
        # We still remove shutdown lines, if any
        if [ -f $TCRON ]
        then
            sed -i -e "/\/sbin\/shutdown/d" $TCRON
        fi
        if [ -f $USERCRON ]
        then
            sed -i -e "/lukker/d" $USERCRON
        fi
        # Assume the parameters are already validated as integers.
        echo "$MINUTES $HOURS * * * /sbin/shutdown -P now" >> $TCRON
        crontab $TCRON

        MINM5P60=$(( $(( MINUTES - 5)) + 60))
        # Rounding minutes
        MINS=$((MINM5P60 % 60))
        HRCORR=$(( 1 - $(( MINM5P60 / 60))))
        HRS=$(( HOURS - HRCORR))
        HRS=$(( $(( HRS + 24)) % 24))
        # Now output to user's crontab as well
        echo "$MINS $HRS * * * DISPLAY=:0.0 /usr/bin/notify-send \"$MESSAGE\"" >> $USERCRON
        crontab -u user $USERCRON
    else
        echo "Usage: shutdown_at_time.sh [--off] [hours minutes]"
    fi

fi

if [ -f $TCRON ]
then
    rm $TCRON
fi
