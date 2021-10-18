#!/bin/sh

#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    lockdown_usb.sh [ENFORCE]
#%
#% DESCRIPTION
#%    This script installs a system service that shuts down and disables the
#%    user session whenever an action is detected on a USB port, and configures
#%    udev to forward all USB events to this service.
#%
#%    Logins are disabled with the user account expiry mechanism.
#%
#%    It takes one optional parameter: whether or not to enforce this policy.
#%    If this parameter is missing, empty, "false", "falsk", "no" or "nej"
#%    (not case-sensitive), the policy will be removed; otherwise, it will be
#%    enforced.
#%
#%    For use with the "unexpire_user.sh" and
#%    "detect_user_expired_event.py" script
#%
#%
#================================================================
#- IMPLEMENTATION
#-    version         lockdown_usb.sh (magenta.dk) 1.0.0
#-    author          Alexander Faithfull, Søren Howe Gersager
#-    copyright       Copyright 2021 Magenta ApS
#-    license         GNU General Public License
#-    email           af@magenta.dk, shg@magenta.dk
#-
#================================================================
#  HISTORY
#     2021/08/30 : shg: Modified to user account expiration
#     2021/04/12 : af : Script created
#
#================================================================
# END_OF_HEADER
#================================================================

set -x

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

activate="`lower "$1"`"

if [ "$activate" != "" \
        -a "$activate" != "false" -a "$activate" != "falsk" \
        -a "$activate" != "no" -a "$activate" != "nej" ]; then
    mkdir -p /usr/local/lib/os2borgerpc

    cat <<"END" > /usr/local/lib/os2borgerpc/usb-monitor
#!/usr/bin/env python3

from os import mkfifo, unlink
from os.path import exists
import subprocess

PIPE = "/var/lib/os2borgerpc/usb-event"


def lockdown():
    """Disable the user account."""
    subprocess.run(["usermod", "-e", "1", "user"])
    subprocess.run(["loginctl", "terminate-user", "user"])


def main():
    # Make sure we always start with a fresh FIFO
    try:
        unlink(PIPE)
    except FileNotFoundError:
        pass

    mkfifo(PIPE)
    try:
        while True:
            with open(PIPE, "rt") as fp:
                # Reading from a FIFO should block until the udev helper script
                # gives us a signal. Lock the system immediately when that
                # happens
                content = fp.read()
                lockdown()
    finally:
        unlink(PIPE)


if __name__ == "__main__":
    main()
END
    chmod 700 /usr/local/lib/os2borgerpc/usb-monitor

    cat <<"END" > /etc/systemd/system/os2borgerpc-usb-monitor.service
[Unit]
Description=OS2borgerPC USB monitoring service

[Service]
Type=simple
ExecStart=/usr/local/lib/os2borgerpc/usb-monitor
# It's important that we stop the Python process, stuck in a blocking read,
# with SIGINT rather than SIGTERM so that its finaliser has a chance to run
KillSignal=SIGINT

[Install]
WantedBy=display-manager.service
END
    systemctl enable --now os2borgerpc-usb-monitor.service

    cat <<"END" > /usr/local/lib/os2borgerpc/on-usb-event
#!/bin/sh

if [ -p "/var/lib/os2borgerpc/usb-event" ]; then
    # Use dd with oflag=nonblock to make sure that we don't append to the pipe
    # if the reader isn't yet running
    echo "$@" | dd oflag=nonblock \
            of=/var/lib/os2borgerpc/usb-event status=none
fi
END
    chmod 700 /usr/local/lib/os2borgerpc/on-usb-event

    cat <<"END" > /etc/udev/rules.d/99-os2borgerpc-usb-event.rules
SUBSYSTEM=="usb", TEST=="/var/lib/os2borgerpc/usb-event", RUN{program}="/usr/local/lib/os2borgerpc/on-usb-event '%E{ACTION}' '$sys$devpath'"
END
else
    systemctl disable --now os2borgerpc-usb-monitor.service
    rm -f /usr/local/lib/os2borgerpc/on-usb-event \
            /etc/udev/rules.d/99-os2borgerpc-usb-event.rules \
            /usr/local/lib/os2borgerpc/usb-monitor \
            /etc/systemd/system/os2borgerpc-usb-monitor.service
fi

udevadm control -R