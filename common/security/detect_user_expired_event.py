#!/usr/bin/env python3

"""
Security Script for finding user expired events.

For use with the "lockdown_usb.sh" and "unexpire_user.sh"
script.
"""


import sys
from datetime import datetime, timedelta
import re

__copyright__ = "Copyright 2017-2024 Magenta ApS"
__license__ = "GPL"


def log_read(last_security_check, log_name):
    """Search a (system) log for events that occurred
    between "last_security_check" and now."""
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
            if last_security_check <= log_event_datetime <= now:
                log_event_tuples.append((security_event_log_timestamp, log_event))

    return log_event_tuples


def csv_writer(security_events):
    """Write security events to security events file."""
    with open("/etc/os2borgerpc/security/securityevent.csv", "at") as csvfile:
        for timestamp, security_problem_uid, log_event in security_events:
            event_line = log_event.replace("\n", " ").replace("\r", "").replace(",", "")
            csvfile.write(f"{timestamp},{security_problem_uid},{event_line}\n")


# Sync these dates with the dates set in hard_shutdown_lockdown, lockdown_usb or any future script that may use this expiry mechanism
def annotate_event_type(event):
    """Adds the type of the security event (USB/Hard shutdown) to the start of the event, as inferred from the expiry date"""
    if event.endswith("'1970-01-05'"):
        event = f"USB event detected: {event}"
    if event.endswith("'1970-01-04'"):
        event = f"Hard shutdown detected: {event}"
    return event


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

log_event_tuples = log_read(last_security_check, log_name)

security_problem_uid_template_var = "%SECURITY_PROBLEM_UID%"

# Example event:
# Jul 13 11:50:20 bpc usermod[328713]: change user 'user' expiration from 'never' to '1970-01-02'
regexes = [
    (r"(usermod\[[0-9]+\]: change user 'user' expiration from 'never' to '[0-9-]+')")
]

# Filter log_event_tuples based on regex matches and put them
# on the form the admin site expects:
# (timestamp, security_problem_uid, summary)
log_event_tuples = [
    (log_timestamp, security_problem_uid_template_var, annotate_event_type(log_event))
    for (log_timestamp, log_event) in log_event_tuples
    if any([re.search(regex, log_event, flags=re.IGNORECASE) for regex in regexes])
]

if not log_event_tuples:
    sys.exit()

csv_writer(log_event_tuples)
