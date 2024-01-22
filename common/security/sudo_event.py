#!/usr/bin/env python3

"""
Security Script for finding sudo events
"""

import sys
from datetime import datetime, timedelta
import re

__copyright__ = "Copyright 2017-2024 Magenta ApS"
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
                log_event_datetime, "%Y%m%d%H%M%S"
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
    """Temporary function that filters security events older than <HOURS> hours.

    Consider adjusting or removing this in the future.
    If wanting to make this permanent remove this function and take the most
    recent timestamp of last_security_check OR cut_off_for_oldest_event
    when calculating delta_sec
    """
    HOURS = 48
    now = datetime.now()
    filtered_events = [
        security_event
        for security_event in security_events
        if datetime.strptime(security_event[0], "%Y%m%d%H%M%S")
        > now - timedelta(hours=HOURS)
    ]
    return filtered_events


# The file to inspect for events
log_name = "/var/log/auth.log"

now = datetime.now()
# The default value in case lastcheck.txt is nonexisting or empty:
last_security_check = now - timedelta(hours=24)
try:
    with open("/etc/os2borgerpc/security/lastcheck.txt", "r") as fp:
        timestamp = fp.read()
        if timestamp:
            last_security_check = datetime.strptime(timestamp, "%Y%m%d%H%M%S")
except IOError:
    pass

delta_sec = (now - last_security_check).total_seconds()
log_event_tuples = log_read(delta_sec, log_name)

security_problem_uid_template_var = "%SECURITY_PROBLEM_UID%"
# Ignore if not a sudo event or if a sudo event from root
regexes = [r"sudo:(?!\s*root).*COMMAND"]

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
