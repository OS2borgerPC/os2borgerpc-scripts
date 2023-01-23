#!/bin/sh

# SYNOPSIS
#    on_off_schedule_set.sh PLAN MODE
#
# DESCRIPTION
#    This script installs a system service that manages the planned on/off schedule
#    by updating the crontab with the next planned shutdown and startup process
#    whenever the computer starts.
#
#    The shutdown and startup processes are handled by rtcwake.
#
#    It takes two mandatory parameters: the planned on/off schedule and the desired rtcwake mode.
#    The planned on/off schedule should be represented by a json-file.
#    The desired rtcwake mode should be represented by a string.
#
#    For use with the "on_off_schedule_remove.sh" script
#
# IMPLEMENTATION
#    version         on_off_schedule_set.sh (magenta.dk) 1.0.0
#    copyright       Copyright 2022 Magenta ApS
#    license         GNU General Public License
#
# TECHNICAL DESCRIPTION
#    This script creates and starts "os2borgerpc-set_on-off_schedule.service"
#    which runs the script "set_on-off_schedule.py" as a daemon.
#
#    "set_on-off_schedule.py" is a python-script that runs on startup and updates the crontab
#    with an entry for the next planned shutdown and startup process.
#
#    The shutdown and startup process is handled by rtcwake, which shuts the computer down
#    in the specified mode and starts it again after a specified number of seconds.

set -x

MONDAY_START=$1
MONDAY_STOP=$2
TUESDAY_START=$3
TUESDAY_STOP=$4
WEDNESDAY_START=$5
WEDNESDAY_STOP=$6
THURSDAY_START=$7
THURSDAY_STOP=$8
FRIDAY_START=$9
FRIDAY_STOP=${10}
SATURDAY_START=${11}
SATURDAY_STOP=${12}
SUNDAY_START=${13}
SUNDAY_STOP=${14}
CUSTOM_DATES=${15}
MODE=${16}

WAKE_PLAN_FILE=/etc/os2borgerpc/plan.json
SCHEDULE_CREATION_SCRIPT="/usr/local/lib/os2borgerpc/make_schedule_plan.py"
ON_OFF_SCHEDULE_SERVICE="/etc/systemd/system/os2borgerpc-set_on-off_schedule.service"
ON_OFF_SCHEDULE_SCRIPT="/usr/local/lib/os2borgerpc/set_on-off_schedule.py"
SCHEDULED_OFF_SCRIPT="/usr/local/lib/os2borgerpc/scheduled_off.sh"

mkdir -p /usr/local/lib/os2borgerpc

# Make the schedule plan.json
cat <<EOF > $SCHEDULE_CREATION_SCRIPT
#!/usr/bin/env python3

import json
import datetime
from os2borgerpc.client.config import get_config

FILE = "/etc/os2borgerpc/plan.json"

MONDAY_START = "$MONDAY_START"
MONDAY_STOP = "$MONDAY_STOP"
TUESDAY_START = "$TUESDAY_START"
TUESDAY_STOP = "$TUESDAY_STOP"
WEDNESDAY_START = "$WEDNESDAY_START"
WEDNESDAY_STOP = "$WEDNESDAY_STOP"
THURSDAY_START = "$THURSDAY_START"
THURSDAY_STOP = "$THURSDAY_STOP"
FRIDAY_START = "$FRIDAY_START"
FRIDAY_STOP = "$FRIDAY_STOP"
SATURDAY_START = "$SATURDAY_START"
SATURDAY_STOP = "$SATURDAY_STOP"
SUNDAY_START = "$SUNDAY_START"
SUNDAY_STOP = "$SUNDAY_STOP"
CUSTOM_DATES = "$CUSTOM_DATES"

def make_schedule():
    """Make the schedule plan.json"""

    # Make the schedule plan dictionary
    plan = {'week_plan': {'monday': {'start': MONDAY_START, 'stop': MONDAY_STOP}}}
    plan['week_plan']['tuesday'] = {'start': TUESDAY_START, 'stop': TUESDAY_STOP}
    plan['week_plan']['wednesday'] = {'start': WEDNESDAY_START, 'stop': WEDNESDAY_STOP}
    plan['week_plan']['thursday'] = {'start': THURSDAY_START, 'stop': THURSDAY_STOP}
    plan['week_plan']['friday'] = {'start': FRIDAY_START, 'stop': FRIDAY_STOP}
    plan['week_plan']['saturday'] = {'start': SATURDAY_START, 'stop': SATURDAY_STOP}
    plan['week_plan']['sunday'] = {'start': SUNDAY_START, 'stop': SUNDAY_STOP}

    custom_dict = {}
    if CUSTOM_DATES:
        wake_change_events = CUSTOM_DATES.split('|')
        for event in wake_change_events:
            settings = event.split(';')
            start_date = datetime.datetime.strptime(settings[0], '%d-%m-%Y')
            end_date = datetime.datetime.strptime(settings[1], '%d-%m-%Y')
            date = start_date
            while date <= end_date:
                custom_dict[date.strftime('%d-%m-%Y')] = {'start': settings[2], 'stop': settings[3]}
                date = date + datetime.timedelta(days=1)
    plan['custom_dates'] = custom_dict

    # Check the product type and include it in the plan
    product = get_config("os2_product")
    plan['product'] = product

    # Save the plan
    with open(FILE, 'w') as file:
        json.dump(plan, file, indent=4)

if __name__ == "__main__":
    make_schedule()
EOF

python3 $SCHEDULE_CREATION_SCRIPT
rm -f $SCHEDULE_CREATION_SCRIPT

cat <<EOF > $SCHEDULED_OFF_SCRIPT
#!/usr/bin/env bash

MODE=\$1
DURATION=\$2

pkill -KILL -u user
pkill -KILL -u superuser
/usr/sbin/rtcwake --mode \$MODE --seconds \$DURATION
EOF

chmod 700 $SCHEDULED_OFF_SCRIPT

cat <<EOF > $ON_OFF_SCHEDULE_SCRIPT
#!/usr/bin/env python3

import json
import datetime
import subprocess
import os

FILE = "$WAKE_PLAN_FILE" # "/etc/os2borgerpc/" + "$PLAN_NAME"
MODE = "$MODE".lower()

def check_weekday(plan, date):
    """Helper method that returns the week plan settings for the week day
    corresponding to a given date represented by a datetime.date object"""
    week_days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
    week_day = week_days[date.weekday()]
    return plan['week_plan'][week_day]

def check_custom_date(plan, date):
    """Helper method that returns either the custom settings for
    a given date represented by a datetime.date object or
    None if no custom settings exist"""
    date = date.strftime('%d-%m-%Y')
    try:
        return plan["custom_dates"][date]
    except KeyError:
        return None

def check_if_date_is_custom_or_regular(plan, date):
    """Helper method that returns either the custom settings for
    a given date represented by a datetime.date object or
    the week plan settings for the corresponding week day
    if no custom settings exist"""
    date_settings = check_custom_date(plan, date)
    if date_settings is None:
        date_settings = check_weekday(plan, date)
    return date_settings

def get_shutdown_and_startup_datetimes(plan, current_datetime):
    """Get the next shutdown/startup date and time
    and return them as datetime.datetime objects"""
    # Get next shutdown date and time
    shutdown_date = current_datetime
    shutdown_settings = check_if_date_is_custom_or_regular(plan, shutdown_date)
    shutdown_time = shutdown_settings['stop']
    # Check whether the machine should already be off today,
    # i.e. if start is before stop, but current time is after stop
    startup_time_today = shutdown_settings['start']
    if shutdown_time != "None":
        shutdown, startup = convert_to_datetime(shutdown_date, shutdown_time, shutdown_date, startup_time_today)
        if startup < shutdown and shutdown < current_datetime:
            shutdown_time = "None"
    # Get next startup date and time
    startup_date = shutdown_date + datetime.timedelta(days=1)
    startup_settings = check_if_date_is_custom_or_regular(plan, startup_date)
    while startup_settings['start'] == "None":
        startup_date = startup_date + datetime.timedelta(days=1)
        startup_settings = check_if_date_is_custom_or_regular(plan, startup_date)
        if startup_date > shutdown_date + datetime.timedelta(days=31):
            raise Exception("Ingen gyldig start-dato fundet")
    startup_time = startup_settings['start']
    # Convert to datetime.datetime object
    shutdown, startup = convert_to_datetime(shutdown_date, shutdown_time, startup_date, startup_time)
    # Handle shutdown times after 24:00
    shutdown, startup = handle_late_stop(shutdown, startup, current_datetime)
    return shutdown, startup

def convert_to_datetime(shutdown_date, shutdown_time, startup_date, startup_time):
    """Helper method that converts the shutdown/startup date and time
    to datetime.datetime objects and returns those"""
    if shutdown_time == "None":
        shutdown = datetime.datetime.now() + datetime.timedelta(minutes=20)
    else:
        shutdown = datetime.datetime(shutdown_date.year, shutdown_date.month, shutdown_date.day,
                                     int(shutdown_time[: shutdown_time.index(":")]),
                                     int(shutdown_time[shutdown_time.index(":") + 1 :]))
    startup = datetime.datetime(startup_date.year, startup_date.month, startup_date.day,
                                int(startup_time[: startup_time.index(":")]),
                                int(startup_time[startup_time.index(":") + 1 :]))
    return shutdown, startup

def handle_late_stop(shutdown, startup, current_datetime):
    """Helper method to handle late stops"""
    if shutdown < current_datetime:
        shutdown = shutdown + datetime.timedelta(days=1)
        if startup < shutdown:
            startup = shutdown + datetime.timedelta(minutes=5)
    return shutdown, startup


def main():
    # Add some functionality to ensure that the time settings are correct?

    # Load the plan
    with open(FILE) as file:
        plan = json.load(file)

    # Get the current datetime
    current_datetime = datetime.datetime.today()

    # Get shutdown and startup datetimes
    shutdown, startup = get_shutdown_and_startup_datetimes(plan, current_datetime)

    # Refresh the crontab 5 minutes after startup
    # That way, even if a mode such as "mem,"
    # which does not cause the service to be run again, is used,
    # the crontab will still be updated with the next shutdown.
    # To that end, determine the datetime that is 5 minutes after startup
    refresh = startup + datetime.timedelta(minutes=5)

    # Determine off time
    off_time = int((startup - shutdown).total_seconds())

    # Make sure the machine will wake up as planned even if it is not shut down by the schedule
    startup_string = f"{startup.year}-{startup.month}-{startup.day} {startup.hour}:{startup.minute}"
    subprocess.run(["rtcwake", "-m", "no", "--date", startup_string])

    # Update crontab
    # Get current entries
    TCRON = "/tmp/oldcron"
    with open(TCRON, 'w') as cronfile:
        subprocess.run(["crontab", "-l"], stdout=cronfile)
    # Remove old entries
    with open(TCRON, 'r') as cronfile:
        cronentries = cronfile.readlines()
    with open(TCRON, 'w') as cronfile:
        for entry in cronentries:
            if "scheduled_off" not in entry and "set_on-off_schedule" not in entry and \
                    "shutdown" not in entry and "rtcwake" not in entry:
                cronfile.write(entry)
    # Add entry for next shutdown and refresh
    with open(TCRON, 'a') as cronfile:
        cronfile.write(f"{shutdown.minute} {shutdown.hour} {shutdown.day} {shutdown.month} *"
                       f" $SCHEDULED_OFF_SCRIPT {MODE} {off_time}\n")
        cronfile.write(f"{refresh.minute} {refresh.hour} {refresh.day} {refresh.month} *"
                       f" $ON_OFF_SCHEDULE_SCRIPT\n")
    subprocess.run(["crontab", TCRON])
    if os.path.exists(TCRON):
        os.remove(TCRON)

    # Check the product type and add a notification 5 minutes before shutdown on OS2BorgerPC machines
    if plan['product'] == 'os2borgerpc':
        Message = 'Denne computer lukker ned om fem minutter'
        # Find the time 5 minutes before shutdown
        notify_time = shutdown - datetime.timedelta(minutes=5)
        # Get current entries
        USERCRON = "/tmp/usercron"
        with open(USERCRON, 'w') as cronfile:
            subprocess.run(["crontab", "-u", "user", "-l"], stdout=cronfile)
        # Remove old entries
        with open(USERCRON, 'r') as cronfile:
            cronentries = cronfile.readlines()
        with open(USERCRON, 'w') as cronfile:
            for entry in cronentries:
                if "lukker" not in entry:
                    cronfile.write(entry)
        # Add notification for next shutdown
        with open(USERCRON, 'a') as cronfile:
            cronfile.write(f"{notify_time.minute} {notify_time.hour} {notify_time.day} {notify_time.month} *"
                           f" XDG_RUNTIME_DIR=/run/user/\$(id -u) /usr/bin/notify-send \"{Message}\"\n")
        subprocess.run(["crontab", "-u", "user", USERCRON])
        if os.path.exists(USERCRON):
            os.remove(USERCRON)

if __name__ == "__main__":
    main()
EOF

chmod 700 $ON_OFF_SCHEDULE_SCRIPT

cat <<EOF > $ON_OFF_SCHEDULE_SERVICE
[Unit]
Description=OS2borgerPC on/off schedule service

[Service]
Type=simple
ExecStart=$ON_OFF_SCHEDULE_SCRIPT

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now "$(basename $ON_OFF_SCHEDULE_SERVICE)"
