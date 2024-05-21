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
USERCRON="/etc/os2borgerpc/usercron"
USER_CLEANUP="/usr/share/os2borgerpc/bin/user-cleanup.bash"

mkdir -p /usr/local/lib/os2borgerpc

# Ensure that the usercron-file exists and has the correct permissions
touch $USERCRON
chmod 700 $USERCRON

# Ensure that user-cleanup resets the user crontab
if [ -f "$USER_CLEANUP" ] && ! grep --quiet "crontab" $USER_CLEANUP; then
  echo "crontab -u user $USERCRON" >> $USER_CLEANUP
fi

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
LOCALE_FILE = "/etc/default/locale"

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
    # Get shutdown date and time
    shutdown_date = current_datetime
    shutdown_settings = check_if_date_is_custom_or_regular(plan, shutdown_date)
    shutdown_time = shutdown_settings['stop']
    # Get startup date and time
    startup_date = shutdown_date + datetime.timedelta(days=1)
    startup_settings = check_if_date_is_custom_or_regular(plan, startup_date)
    while startup_settings['start'] == "None":
        startup_date = startup_date + datetime.timedelta(days=1)
        startup_settings = check_if_date_is_custom_or_regular(plan, startup_date)
        if startup_date > shutdown_date + datetime.timedelta(days=31):
            raise Exception("Ingen gyldig start-dato fundet")
    startup_time = startup_settings['start']
    # Get the first-coming planned startup
    # This value is only different from startup when a machine is manually turned on
    # after its shutdown time
    planned_startup = convert_to_datetime_helper(startup_date, startup_time)
    # Get next shutdown date and time
    next_shutdown_date = shutdown_date + datetime.timedelta(days=1)
    next_shutdown_settings = check_if_date_is_custom_or_regular(plan, next_shutdown_date)
    next_shutdown_time = next_shutdown_settings['stop']
    # Get next startup date and time
    next_startup_date = next_shutdown_date + datetime.timedelta(days=1)
    next_startup_settings = check_if_date_is_custom_or_regular(plan, next_startup_date)
    while next_startup_settings['start'] == "None":
        next_startup_date = next_startup_date + datetime.timedelta(days=1)
        next_startup_settings = check_if_date_is_custom_or_regular(plan, next_startup_date)
    next_startup_time = next_startup_settings['start']
    startup_time_today = shutdown_settings['start']
    # Handle None values
    if shutdown_time == "None" and next_shutdown_time == "None":
        shutdown_time = f"{current_datetime.hour}:{current_datetime.minute}"
        shutdown_date = next_shutdown_date
        startup_time_today = "0:1"
    elif shutdown_time == "None" and next_shutdown_time != "None":
        shutdown_date, shutdown_time = next_shutdown_date, next_shutdown_time
        startup_date, startup_time = next_startup_date, next_startup_time
        startup_time_today = "0:1"
    elif shutdown_time != "None" and next_shutdown_time == "None":
        next_shutdown_time = shutdown_time
    # Check whether the machine has been turned on manually,
    # i.e. if start is before stop, but current time is after stop
    shutdown, startup = convert_to_datetime(shutdown_date, shutdown_time, shutdown_date, startup_time_today)
    if startup < shutdown and shutdown < current_datetime:
        startup_date, startup_time = next_startup_date, next_startup_time
        shutdown_date, shutdown_time = next_shutdown_date, next_shutdown_time

    # Convert to datetime.datetime object
    shutdown, startup = convert_to_datetime(shutdown_date, shutdown_time, startup_date, startup_time)
    # Handle shutdown times after 24:00
    shutdown, startup = handle_late_stop(shutdown, startup, current_datetime)
    return shutdown, startup, planned_startup

def convert_to_datetime(shutdown_date, shutdown_time, startup_date, startup_time):
    """Helper method that converts the shutdown/startup date and time
    to datetime.datetime objects and returns those"""
    if shutdown_time == "None":
        shutdown = datetime.datetime.now() + datetime.timedelta(minutes=20)
    else:
        shutdown = convert_to_datetime_helper(shutdown_date, shutdown_time)
    startup = convert_to_datetime_helper(startup_date, startup_time)
    return shutdown, startup

def convert_to_datetime_helper(date, time):
    """Subfunction for the convert_to_datetime helper method"""
    value = datetime.datetime(date.year, date.month, date.day,
                                int(time[: time.index(":")]),
                                int(time[time.index(":") + 1 :]))
    return value

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
    shutdown, startup, planned_startup = get_shutdown_and_startup_datetimes(plan, current_datetime)

    # Refresh the crontab 5 minutes after startup
    # That way, even if a mode such as "mem,"
    # which does not cause the service to be run again, is used,
    # the crontab will still be updated with the next shutdown.
    # To that end, determine the datetime that is 5 minutes after startup
    refresh = startup + datetime.timedelta(minutes=5)

    # Refresh the crontab 5 minutes before planned_startup
    # This ensures that if a machine is manually turned on
    # after its shutdown time and then left on, it will not
    # end in a state where no startup is planned
    refresh2 = planned_startup - datetime.timedelta(minutes=5)

    # Determine off time
    off_time = int((startup - shutdown).total_seconds())

    # Make sure the machine will wake up as planned even if it is not shut down by the schedule
    startup_string = f"{planned_startup.year}-{planned_startup.month}-{planned_startup.day} "\
                     f"{planned_startup.hour}:{planned_startup.minute}"
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
    # Add entry for next shutdown and refreshes
    with open(TCRON, 'a') as cronfile:
        cronfile.write(f"{shutdown.minute} {shutdown.hour} {shutdown.day} {shutdown.month} *"
                       f" $SCHEDULED_OFF_SCRIPT {MODE} {off_time}\n")
        cronfile.write(f"{refresh.minute} {refresh.hour} {refresh.day} {refresh.month} *"
                       f" $ON_OFF_SCHEDULE_SCRIPT\n")
        cronfile.write(f"{refresh2.minute} {refresh2.hour} {refresh2.day} {refresh2.month} *"
                       f" $ON_OFF_SCHEDULE_SCRIPT\n")
    subprocess.run(["crontab", TCRON])
    if os.path.exists(TCRON):
        os.remove(TCRON)

    # Check the product type and add a notification 5 minutes before shutdown on OS2BorgerPC machines
    if plan['product'] == 'os2borgerpc':
        # Set the notification text based on the chosen language
        locale = "None"
        if os.path.exists(LOCALE_FILE):
            with open(LOCALE_FILE, "r") as file:
                locale = file.read()
        if 'LANG=sv' in locale or 'LANG="sv' in locale:
            MESSAGE = 'VARNING: Den här datorn stängs av om fem minuter'
        elif 'LANG=en' in locale or 'LANG="en' in locale:
            MESSAGE = 'WARNING: This computer will shut down in five minutes'
        else:
            MESSAGE = 'ADVARSEL: Denne computer lukker ned om fem minutter'
        # Find the time 5 minutes before shutdown
        notify_time = shutdown - datetime.timedelta(minutes=5)
        # Get current entries
        USERCRON = "/etc/os2borgerpc/usercron"
        # Remove old entries
        with open(USERCRON, 'r') as cronfile:
            cronentries = cronfile.readlines()
        with open(USERCRON, 'w') as cronfile:
            for entry in cronentries:
                if "zenity" not in entry and "notify-send" not in entry:
                    cronfile.write(entry)
        # Add notification for next shutdown
        with open(USERCRON, 'a') as cronfile:
            cronfile.write(f"{notify_time.minute} {notify_time.hour} {notify_time.day} {notify_time.month} *"
                           f" export DISPLAY=:0 && /usr/bin/zenity --warning --text '<big>{MESSAGE}</big>'\n")
        subprocess.run(["crontab", "-u", "user", USERCRON])

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
