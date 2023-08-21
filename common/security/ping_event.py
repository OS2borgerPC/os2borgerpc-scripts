#!/usr/bin/env python3

# This is basically just a simple example for how to write a security script,
# and also a way to test that the security system is working.

from datetime import datetime


def csv_writer(security_events):
    """Write security events to security events file."""
    with open("/etc/os2borgerpc/security/securityevent.csv", "at") as csvfile:
        for timestamp, security_problem_uid, log_event, complete_log in security_events:
            event_line = log_event.replace("\n", " ").replace("\r", "").replace(",", "")
            csvfile.write(
                f"{timestamp},{security_problem_uid},{event_line},{complete_log}\n"
            )


now = datetime.now()
timestamp = datetime.strftime(now, "%Y%m%d%H%M%S")
security_problem_uid_template_var = "%SECURITY_PROBLEM_UID%"
log_event = "Ping warning."
complete_log = "Nothing to worry about. Just a ping warning."


csv_writer([(timestamp, security_problem_uid_template_var, log_event, complete_log)])
