#!/usr/bin/env python3

# HEADER
#================================================================
#% SYNOPSIS
#+    detect_user_expired_event.py
#%
#% DESCRIPTION
#%    Security Script for finding user expired events that happened
#%    within the last 300 seconds.
#%
#%
#%    For use with the "lockdown_usb.sh" and "unexpire_user.sh"
#%    script.
#%
#================================================================
#- IMPLEMENTATION
#-    version         unexpire_user.sh (magenta.dk) 1.0.0
#-    author          Søren Howe Gersager
#-    copyright       Copyright 2021 Magenta ApS
#-    license         GNU General Public License
#-    email           shg@magenta.dk
#-
#================================================================
#  HISTORY
#     2021/08/30 : shg: Creation
#================================================================
# END_OF_HEADER
#================================================================

import sys
from datetime import datetime, timedelta
import re

import csv_writer
import log_read

__author__ = "Søren Howe Gersager"
__copyright__ = "Copyright 2017-2020 Magenta ApS"
__credits__ = [
    "Carsten Agger",
    "Dennis Borup Jakobsens",
    "Alexander Faithfull",
    "Søren Howe Gersager",
]
__license__ = "GPL"
__version__ = "0.0.6"
__maintainer__ = "Søren Howe Gersager"
__email__ = "shg@magenta.dk"
__status__ = "Production"


# Get lines from syslog
fname = "/var/log/auth.log"

now = datetime.now()
last_security_check = now - timedelta(seconds=86400)
try:
    with open("/etc/os2borgerpc/security/lastcheck.txt", "r") as fp:
        timestamp = fp.read()
        if timestamp:
            last_security_check = datetime.strptime(timestamp, "%Y%m%d%H%M")
except IOError:
    pass

delta_sec = int((now - last_security_check).total_seconds())

lines = ""
if delta_sec <= 86400:
    lines = log_read.read(delta_sec, fname)
else:
    raise ValueError("No security check in the last 24 hours.")

usermod_regex = r"(usermod\[[0-9]+\]: change user 'user' expiration from 'never' to '1970-01-02')"
splitted = re.split(usermod_regex, lines, maxsplit=1)

# Ignore if not a usermod event
if len(splitted) <= 1:
    sys.exit()

# securityEventCode, Tec sum, Raw data
csv_data = []
# securityEventCode (security problem id)
csv_data.append("%SECURITY_PROBLEM_UID%")

# find keyword
# select text from auth.log until end of line
before_keyword, keyword, after_keyword = splitted

# Tec sum
csv_data.append(keyword)

log_data = before_keyword[-1000:] + keyword + after_keyword[:1000]

log_data = log_data.replace("\n", " ").replace("\r", "").replace(",", "")

# Raw data
csv_data.append("'" + log_data + "'")

csv_writer.write_data(csv_data)