#!/usr/bin/env bash

# SYNOPSIS
#    shutdown_at_time.sh <hours> <minutes>
#
# DESCRIPTION
#    This is a script to make a OS2BorgerPC machine shutdown at a certain time.
#
#    To disable the scheduled shutdown:
#      shutdown_at_time.sh --off
#
#    We'll suppose the user only wants to have regular shutdown once a day
#    as specified by the <hours> and <minutes> parameters. Thus, any line in
#    crontab already specifying a shutdown will be deleted before a new one is
#    inserted.
#
# IMPLEMENTATION
#    author          Danni Als
#    copyright       Copyright 2018, Magenta Aps"
#    license         GNU General Public License

set -x

WAKE_PLAN_FILE=/etc/os2borgerpc/plan.json

if [ -f $WAKE_PLAN_FILE ]; then
  echo "Dette script kan ikke anvendes på en PC, der er tilknyttet en tænd/sluk tidsplan."
  exit 1
fi

ROOTCRON_TMP=/tmp/oldcron
USERCRON_TMP=/tmp/usercron
MESSAGE="Denne computer lukker ned om fem minutter"

# Read and save current cron settings first
crontab -l > $ROOTCRON_TMP
crontab -u user -l > $USERCRON_TMP

# Delete current crontab entries related to this script AND shutdown_and_wakeup.sh
sed --in-place --expression "/shutdown/d" --expression "/rtcwake/d" --expression "/scheduled_off/d" $ROOTCRON_TMP
sed --in-place "/lukker/d" $USERCRON_TMP

# If not called with --off: Determine the new crontab contents
if [ "$1" != "--off" ]; then

    if [ $# == 2 ]; then
        HOURS=$1
        MINUTES=$2
        # Assume the parameters are already validated as integers.
        echo "$MINUTES $HOURS * * * /sbin/shutdown -P now" >> $ROOTCRON_TMP

        MINM5P60=$(( $(( MINUTES - 5)) + 60))
        # Rounding minutes
        MINS=$(( MINM5P60 % 60))
        HRCORR=$(( 1 - $(( MINM5P60 / 60))))
        HRS=$(( HOURS - HRCORR))
        HRS=$(( $(( HRS + 24)) % 24))
        # Now output to user's crontab as well
        echo "$MINS $HRS * * * XDG_RUNTIME_DIR=/run/user/\$(id -u) /usr/bin/notify-send \"$MESSAGE\"" >> $USERCRON_TMP
    else
        echo "Usage: shutdown_at_time.sh [--off] [hours minutes]"
    fi
fi

# Update crontabs accordingly - either with an empty crontab or updated ones
crontab $ROOTCRON_TMP
crontab -u user $USERCRON_TMP

rm --force $ROOTCRON_TMP $USERCRON_TMP
