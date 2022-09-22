#!/bin/sh

# SYNOPSIS
#    lockdown_usb_unless_approved.sh [ENFORCE] [APPEND] [UNLOCK]
#
# DESCRIPTION
#    This script registers all of the currently connected USB devices as
#    pre-approved devices and installs a system service that shuts down
#    and disables the user session whenever an action caused by a
#    non-approved device is detected on a USB port, and configures
#    udev to forward all USB events to this service. When the PC is booted,
#    it will also check whether the currently connected devices are among
#    the pre-approved devices and disable the user session if they are not.
#
#    Logins are disabled with the user account expiry mechanism.
#
#    It takes three optional parameters: whether or not to enforce this policy,
#    whether or not to append the currently connected devices to an existing list
#    of pre-approved devices and whether or not to enable user logins.
#    [ENFORCE]: Use a boolean to decide whether or not to enable this policy, a checked box
#    will enable it and an unchecked box will remove it
#    [APPEND]: Use a boolean to decide whether or not to append the currently
#    connected devices to an existing list of pre-approved devices. A checked box
#    will append the currently connected devices to the list of pre-approved devices
#    and an unchecked box will replace the list of pre-approved devices with the currently
#    connected devices
#    [UNLOCK]: Use a boolean to decide whether or not to enable user logins, a checked box
#    will enable user logins and an unchecked box does nothing
#
#    For use with the "unexpire_user.sh" and
#    "detect_user_expired_event.py" script
#
#    Before running this script for the first time, please run lockdown_usb.sh with the
#    input False, i.e. an unchecked checkbox
#
# IMPLEMENTATION
#    version         lockdown_usb_unless_approved.sh (magenta.dk) 1.0.0
#    copyright       Copyright 2022 Magenta ApS
#    license         GNU General Public License
#
# TECHNICAL DESCRIPTION
#    This script registers the currently connected USB devices as pre-approved devices then
#    creates and starts "os2borgerpc-monitor.service" which runs the script "usb-monitor" as a daemon.
#    "usb-monitor" is a python-script which first checks if the currently connected devices are among
#    the pre-approved devices then continually reads from a FIFO, we name "usb-event".
#
#    If the first check finds any devices that are not among the pre-approved devices or that FIFO
#    receives any data from a non-approved device, "usb-monitor" logs and locks the user named "user" out.
#
#    udev writes to that FIFO, by calling the shell script "on-usb-event", when it detects any USB related events.

set -x

ACTIVATE=$1
APPEND=$2
UNLOCK=$3

if [ "$UNLOCK" = "True" ]; then
    usermod -e '' user
fi

if [ "$ACTIVATE" = "True" ]; then
    FILE=/etc/systemd/system/os2borgerpc-usb-monitor.service
    if [ -f "$FILE" ]; then
        systemctl disable --now os2borgerpc-usb-monitor.service
    fi
    mkdir -p /usr/share/os2borgerpc/lib

    cat << EOF > /usr/share/os2borgerpc/lib/approve-devices.py
#!/usr/bin/env python3

import subprocess
import re
from os.path import exists

APPROVED_LIST = "/etc/os2borgerpc/approved_usb_ids.txt"
APPEND = $APPEND

def get_approved_ids():
    """Load the list of approved device ids. If no list
    has been made, return an empty list."""
    if not exists(APPROVED_LIST):
        return []
    else:
        with open(APPROVED_LIST) as file:
            approved_ids = file.readlines()
        for i in range(len(approved_ids)):
            approved_ids[i] = approved_ids[i][:-1]
        return approved_ids

def approve_devices(append=False):
    """Get the ids of all currently connected usb devices
    and update the list of approved ids. If append is True,
    the current ids are appended to the existing list.
    If append is False, the existing list is replaced
    with a list containing the current ids."""
    encoding = 'utf-8'
    lsusb_output = subprocess.check_output("lsusb")
    device_ids = []
    for info in lsusb_output.split(b'\n'):
        if info:
            id = re.search(b"ID\s(\w+:\w+)", info).group(1)
            if id:
                device_ids.append(id)
    device_ids = list(dict.fromkeys(device_ids))
    device_ids = [str(device_id, encoding) for device_id in device_ids]
    if append:
        current_list = get_approved_ids()
        new_ids = [id for id in device_ids if id not in current_list]
        if new_ids:
            with open(APPROVED_LIST, 'a') as file:
                file.write('\n'.join(new_ids))
                file.write('\n')
    else:
        with open(APPROVED_LIST, 'w') as file:
            file.write('\n'.join(device_ids))
            file.write('\n')

if __name__ == "__main__":
    # Pre-approve currently connected usb devices
    approve_devices(APPEND)
EOF
    chmod 700 /usr/share/os2borgerpc/lib/approve-devices.py
    /usr/share/os2borgerpc/lib/approve-devices.py
    rm -f /usr/share/os2borgerpc/lib/approve-devices.py

    cat << EOF > /usr/share/os2borgerpc/lib/usb-monitor.py
#!/usr/bin/env python3

from os import mkfifo, unlink
from os.path import exists
import subprocess
import re

PIPE = "/var/lib/os2borgerpc/usb-event"
APPROVED_LIST = "/etc/os2borgerpc/approved_usb_ids.txt"

# Old versions of this script expired to 1970-01-02 like hard_shutdown_lockdown.sh
# It was changed to different dates so we can distinguish which
# script locked the account from the security event directly
def lockdown():
    """Disable the user account."""
    subprocess.run(["usermod", "-e", "1970-01-05", "user"])
    subprocess.run(["loginctl", "terminate-user", "user"])

def get_current_ids():
    """Get the ids of the currently connected usb devices."""
    encoding = 'utf-8'
    lsusb_output = subprocess.check_output("lsusb")
    device_ids = []
    for info in lsusb_output.split(b'\n'):
        if info:
            id = re.search(b"ID\s(\w+:\w+)", info).group(1)
            if id:
                device_ids.append(id)
    device_ids = list(dict.fromkeys(device_ids))
    device_ids = [str(device_id, encoding) for device_id in device_ids]
    return device_ids

def get_approved_ids():
    """Load the list of approved device ids."""
    with open(APPROVED_LIST) as file:
        approved_ids = file.readlines()
    for i in range(len(approved_ids)):
        approved_ids[i] = approved_ids[i][:-1]
    return approved_ids

def check_usb_event():
    """Check if a usb event was caused by an approved device
    and return the resulting boolean"""
    current_ids = get_current_ids()
    approved_ids = get_approved_ids()
    return all(id in approved_ids for id in current_ids)

def main():

    # Make sure we always start with a fresh FIFO
    try:
        unlink(PIPE)
    except FileNotFoundError:
        pass

    current_ids = get_current_ids()
    approved_ids = get_approved_ids()
    # Check if the current device ids are among the approved ids.
    # If not, lock the system immediately
    if not all(id in approved_ids for id in current_ids):
        lockdown()

    mkfifo(PIPE)
    try:
        while True:
            with open(PIPE, "rt") as fp:
                # Reading from a FIFO should block until the udev helper script
                # gives us a signal. If the usb device that caused the signal
                # is not among the approved devices, lock the system immediately
                usb_event = fp.read()
                allowed = check_usb_event()
                if not allowed:
                    lockdown()
    finally:
        unlink(PIPE)


if __name__ == "__main__":
    main()
EOF
    chmod 700 /usr/share/os2borgerpc/lib/usb-monitor.py

    cat <<"END" > /etc/systemd/system/os2borgerpc-usb-monitor.service
[Unit]
Description=OS2borgerPC USB monitoring service

[Service]
Type=simple
ExecStart=/usr/share/os2borgerpc/lib/usb-monitor.py
# It's important that we stop the Python process, stuck in a blocking read,
# with SIGINT rather than SIGTERM so that its finaliser has a chance to run
KillSignal=SIGINT

[Install]
WantedBy=display-manager.service
END
    systemctl enable --now os2borgerpc-usb-monitor.service

    cat <<"END" > /usr/share/os2borgerpc/lib/on-usb-event.sh
#!/bin/sh

if [ -p "/var/lib/os2borgerpc/usb-event" ]; then
    # Use dd with oflag=nonblock to make sure that we don't append to the pipe
    # if the reader isn't yet running
    echo "$@" | dd oflag=nonblock \
            of=/var/lib/os2borgerpc/usb-event status=none
fi
END
    chmod 700 /usr/share/os2borgerpc/lib/on-usb-event.sh

    cat <<"END" > /etc/udev/rules.d/99-os2borgerpc-usb-event.rules
SUBSYSTEM=="usb", TEST=="/var/lib/os2borgerpc/usb-event", RUN{program}="/usr/share/os2borgerpc/lib/on-usb-event.sh '%E{ACTION}' '$sys$devpath'"
END
else
    systemctl disable --now os2borgerpc-usb-monitor.service
    rm -f /usr/share/os2borgerpc/lib/on-usb-event.sh \
            /etc/udev/rules.d/99-os2borgerpc-usb-event.rules \
            /usr/share/os2borgerpc/lib/usb-monitor.py \
            /etc/systemd/system/os2borgerpc-usb-monitor.service \
            /etc/os2borgerpc/approved_usb_ids.txt
fi

udevadm control -R
