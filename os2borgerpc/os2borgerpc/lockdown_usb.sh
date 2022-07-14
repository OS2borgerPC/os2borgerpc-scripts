#!/bin/sh

# SYNOPSIS
#    lockdown_usb.sh [ENFORCE]
#
# DESCRIPTION
#    This script installs a system service that shuts down and disables the
#    user session whenever an action is detected on a USB port, and configures
#    udev to forward all USB events to this service.
#
#    Logins are disabled with the user account expiry mechanism.
#
#    It takes one optional parameter: whether or not to enforce this policy.
#    Use a boolean to decide whether or not to enable this policy, a checked box
#    will enable it and an unchecked box will remove it
#
#    For use with the "unexpire_user.sh" and
#    "detect_user_expired_event.py" script
#
# IMPLEMENTATION
#    version         lockdown_usb.sh (magenta.dk) 1.0.0
#    copyright       Copyright 2022 Magenta ApS
#    license         GNU General Public License
#
# TECHNICAL DESCRIPTION
#    This scripts creates and starts "os2borgerpc-monitor.service" which runs the script "usb-monitor" as a daemon.
#    "usb-monitor" is a python-script which continually reads from a FIFO, we name "usb-event".
#
#    If that FIFO receives any data, "usb-monitor" logs and locks the user named "user" out.
#
#    udev writes to that FIFO, by calling the shell script "on-usb-event", when it detects any USB related events.

set -x

ACTIVATE=$1

if [ "$ACTIVATE" = "True" ]; then
    mkdir -p /usr/local/lib/os2borgerpc

    cat <<"END" > /usr/local/lib/os2borgerpc/usb-monitor
#!/usr/bin/env python3

from os import mkfifo, unlink
from os.path import exists
import subprocess

PIPE = "/var/lib/os2borgerpc/usb-event"


# Old versions of this script expired to 1970-01-02 like hard_shutdown_lockdown.sh
# It was changed to different dates so we can distinguish which
# script locked the account from the security event directly
def lockdown():
    """Disable the user account."""
    subprocess.run(["usermod", "-e", "1970-01-05", "user"])
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
