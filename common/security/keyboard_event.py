#!/usr/bin/env python3

"""
Security Script for finding USB keyboard attachment events
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


def filter_duplicate_events(security_events):
    """This function filters duplicate events related to
    the same keyboard"""

    unique_tuples = []
    unique_keyboards = []

    for security_event in security_events:
        # This identifier is based on the ID of the USB device.
        # The ID is identical for identical USB devices so
        # if two identical keyboards are inserted simultaneously,
        # only one event will be generated.
        regex = (
            r"[0-9a-z]{4}:[0-9a-z]{4}:[0-9a-z]{4}"
            r"(?!.*/[0-9a-z]{4}:[0-9a-z]{4}:[0-9a-z]{4})"
        )
        match = re.search(regex, security_event[2], flags=re.IGNORECASE)
        # Keyboard event lines should always contain a match, but in order
        # to prevent possibly overlooking a relevant event, we always include
        # events with no match
        if match:
            keyboard_identifier = match.group(0)
            if keyboard_identifier not in unique_keyboards:
                unique_tuples.append(security_event)
                unique_keyboards.append(keyboard_identifier)
        else:  # This part should never be relevant, but it is here just in case
            unique_tuples.append(security_event)

    return unique_tuples


# The file to inspect for events
log_name = "/var/log/syslog"

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

# Match keyboard events that are after 9.9999 seconds of boot up
# (so we don't match upstart keyboard events),
# Also remove system control and consumer control entries:
# The reason is that some keyboards add three keyboard entries when connected.
# Example from inserting a keyboard once:
# Jun 28 14:24:43 kbh-nuc-venstre kernel: [ 1948.130701] input: Logitech HID compliant keyboard as /devices/pci0000:00/0000:00:14.0/usb1/1-3/1-3:1.0/0003:046D:C30E.000A/input/input25
# Jun 28 14:24:43 kbh-nuc-venstre kernel: [ 1948.264053] input: Logitech HID compliant keyboard System Control as /devices/pci0000:00/0000:00:14.0/usb1/1-3/1-3:1.1/0003:046D:C30E.000B/input/input27
# Jun 28 14:24:43 kbh-nuc-venstre kernel: [ 1948.204460] input: Logitech HID compliant keyboard Consumer Control as /devices/pci0000:00/0000:00:14.0/usb1/1-3/1-3:1.1/0003:046D:C30E.000B/input/input26
# Fortunately it seems Consumer Control and System Control aren't Logitech specific, as we've seen the exact same with Lenovo keyboards.
# The second regex matches certain keyboards that do not generate a log line with "input:" and "Keyboard"
# Most regular keyboards also generate a log line that matches the second regex, but
# the duplicate events are removed by the filtering
regexes = [
    r".*\[[ ]{0,3}[0-9]{2,}\..*\] input: .*Keyboard "
    r"(?!((mouse )?system control))(?!((mouse )?consumer control)).*",
    r".*\[[ ]{0,3}[0-9]{2,}\..*\].*input,hidraw.*keyboard (?!mouse)",
]

# Filter log_event_tuples based on regex matches and put them
# on the form the admin site expects:
# (timestamp, security_problem_uid, summary)
log_event_tuples = [
    (log_timestamp, security_problem_uid_template_var, log_event)
    for (log_timestamp, log_event) in log_event_tuples
    if any([re.search(regex, log_event, flags=re.IGNORECASE) for regex in regexes])
]

log_event_tuples = filter_duplicate_events(log_event_tuples)

if not log_event_tuples:
    sys.exit()

csv_writer(log_event_tuples)
