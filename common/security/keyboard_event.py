#!/usr/bin/env python3

"""
Security Script for finding USB keyboard attachment events
which happened within the last 300 seconds.
"""

import sys
from datetime import datetime, timedelta
import re

__copyright__ = "Copyright 2017-2022 Magenta ApS"
__license__ = "GPL"


def log_read(sec, log_name):
    """Search a (system) log from within the last "sec" seconds to now."""
    log_event_tuples = []
    now = datetime.now()

    with open(log_name) as f:
        for line in f.readlines():
            line = str(line.replace("\0", ""))
            log_event_timestamp = line[:15]
            log_event = line.strip("\n")
            # convert from log event timestamp to security event log timestamp.
            log_event_datetime = datetime.strptime(
                str(now.year) + " " + log_event_timestamp, "%Y %b  %d %H:%M:%S"
            )
            security_event_log_timestamp = datetime.strftime(
                log_event_datetime, "%Y%m%d%H%M"
            )
            # Detect lines from within the last x seconds to now.
            if (datetime.now() - timedelta(seconds=sec)) <= log_event_datetime <= now:
                log_event_tuples.append((security_event_log_timestamp, log_event))

    return log_event_tuples


def csv_writer(security_events):
    """Write security events to security events file."""
    with open("/etc/os2borgerpc/security/securityevent.csv", "at") as csvfile:
        for timestamp, security_problem_uid, log_event, complete_log in security_events:
            event_line = log_event.replace("\n", " ").replace("\r", "").replace(",", "")
            csvfile.write(
                f"{timestamp},{security_problem_uid},{event_line},{complete_log}\n"
            )


def filter_security_events(security_events):
    """Temporary function that filters security events older than 8 hours.

    TODO: remove this in the future.
    """
    now = datetime.now()
    filtered_events = [
        security_event
        for security_event in security_events
        if datetime.strptime(security_event[0], "%Y%m%d%H%M") > now - timedelta(hours=8)
    ]
    return filtered_events


# The file to inspect for events
log_name = "/var/log/syslog"

now = datetime.now()
# The default value in case lastcheck.txt is nonexisting or empty:
last_security_check = now - timedelta(hours=24)
try:
    with open("/etc/os2borgerpc/security/lastcheck.txt", "r") as fp:
        timestamp = fp.read()
        if timestamp:
            last_security_check = datetime.strptime(timestamp, "%Y%m%d%H%M")
except IOError:
    pass

delta_sec = (now - last_security_check).total_seconds()
log_event_tuples = log_read(delta_sec, log_name)

security_problem_uid_template_var = "%SECURITY_PROBLEM_UID%"

# Match keyboard events that are after 9.9999 seconds of boot up (so we don't match upstart keyboard events).
# Example:
# May 20 11:29:33 kbh-nuc-hoejre kernel: [ 10.122061] input: Dell Dell USB Keyboard as /devices/pci0000:00/0000:00:14.0/usb1/1-3/1-3:1.0/0003:413C:2003.0003/input/input8
regexes = [r".*\[[ ]{0,3}[0-9]{2,}\..*\] input: .*Keyboard.*"]

# Filter log_event_tuples based on regex matches and put them
# on the form the admin site expects:
# (timestamp, security_problem_uid, summary, complete_log) (which we don't use.)
log_event_tuples = [
    (log_timestamp, security_problem_uid_template_var, log_event, " ")
    for (log_timestamp, log_event) in log_event_tuples
    if any([re.search(regex, log_event, flags=re.IGNORECASE) for regex in regexes])
]

log_event_tuples = filter_security_events(log_event_tuples)

if not log_event_tuples:
    sys.exit()

csv_writer(log_event_tuples)
