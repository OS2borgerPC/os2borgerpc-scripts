#!/usr/bin/env python3

# HEADER
# ================================================================
# SYNOPSIS
#    detect_user_expired_event.py
#
# DESCRIPTION
#    Security Script for finding user expired events that happened
#    within the last 300 seconds.
#
#
#    For use with the "lockdown_usb.sh" and "unexpire_user.sh"
#    script.
#
# ================================================================
# IMPLEMENTATION
#    version         unexpire_user.sh (magenta.dk) 1.0.0
#    author          Søren Howe Gersager
#    copyright       Copyright 2021 Magenta ApS
#    license         GNU General Public License
#    email           shg@magenta.dk
#
# ================================================================
#  HISTORY
#     2021/08/30 : shg: Creation
# ================================================================
# END_OF_HEADER
# ================================================================

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


# The file to inspect for events
log_name = "/var/log/auth.log"

now = datetime.now()
try:
    with open("/etc/os2borgerpc/security/lastcheck.txt", "r") as fp:
        timestamp = fp.read()
        if timestamp:
            last_security_check = datetime.strptime(timestamp, "%Y%m%d%H%M")
except IOError:
    last_security_check = now - timedelta(seconds=86400)

delta_sec = (now - last_security_check).total_seconds()
log_event_tuples = log_read(delta_sec, log_name)

security_problem_uid_template_var = "%SECURITY_PROBLEM_UID%"

regexes = [
    (
        r"(usermod\[[0-9]+\]: change user 'user'"
        " expiration from 'never' to '1970-01-02')"
    )
]

# Filter log_event_tuples based on regex matches and put them
# on the form the admin site expects:
# (timestamp, security_problem_uid, summary, complete_log) (which we don't use.)
log_event_tuples = [
    (log_timestamp, security_problem_uid_template_var, log_event, " ")
    for (log_timestamp, log_event) in log_event_tuples
    if any([re.search(regex, log_event, flags=re.IGNORECASE) for regex in regexes])
]

if not log_event_tuples:
    sys.exit()

csv_writer(log_event_tuples)
