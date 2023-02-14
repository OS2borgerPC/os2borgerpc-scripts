#!/usr/bin/env bash

# SYNOPSIS
#    shutdown_and_wakeup.sh --args <hours> <minutes> <hours>
#
# DESCRIPTION
#    This is a script to make a OS2BorgerPC machine shutdown at a certain time.
#    Synopsis:
#
#      shutdown_and_wakeup.sh <hours> <minutes> <hours>
#
#    to enable shutdown mechanism.
#
#      shutdown_and_wakeup.sh --off
#
#    to disable.
#
#    We'll suppose the user only wants to have regular shutdown once a day
#    as specified by the <hours> and <minutes> parameters. Thus, any line in
#    crontab already specifying a shutdown will be deleted before a new one is
#    inserted.
#    We'll also suppose the user wants the machine to wakeup after X numbers
#     of hours after shutdown everyday.
#
# IMPLEMENTATION
#    author          Danni Als
#    copyright       Copyright 2018, Magenta Aps"
#    license         GNU General Public License

set -x

WAKE_PLAN_FILE=/etc/os2borgerpc/plan.json
SCHEDULED_OFF_SCRIPT="/usr/local/lib/os2borgerpc/scheduled_off.sh"

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

# Delete current crontab entries related to this script AND shutdown_at_time
sed --in-place --expression "/rtcwake/d" --expression "/scheduled_off/d" --expression "/shutdown/d" $ROOTCRON_TMP
sed --in-place "/lukker/d" $USERCRON_TMP

if [ "$1" == "--off" ]; then
    rm --force $SCHEDULED_OFF_SCRIPT
else

    # If not called with --off: Determine the new crontab contents
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

        # Assume the parameters are already validated as integers.
        echo "$MINUTES $HOURS * * * $SCHEDULED_OFF_SCRIPT $MODE $SECONDS_TO_WAKEUP" >> $ROOTCRON_TMP

        MINM5P60=$(( $(( MINUTES - 5)) + 60))
        # Rounding minutes
        MINS=$(( MINM5P60 % 60))
        HRCORR=$(( 1 - $(( MINM5P60 / 60))))
        HRS=$(( HOURS - HRCORR))
        HRS=$(( $(( HRS + 24)) % 24))
        # Now output to user's crontab as well
        echo "$MINS $HRS * * * XDG_RUNTIME_DIR=/run/user/\$(id -u) /usr/bin/notify-send \"$MESSAGE\"" >> $USERCRON_TMP
    else
        echo "Usage: shutdown_and_wakeup.sh [--off] [hours minutes] [hours]"
    fi
fi

# Update crontabs accordingly - either with an empty crontab or updated ones
crontab $ROOTCRON_TMP
crontab -u user $USERCRON_TMP

rm --force $ROOTCRON_TMP $USERCRON_TMP
