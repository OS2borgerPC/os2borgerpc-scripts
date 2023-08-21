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
# TECHNICAL NOTES
#    This scripts creates and starts "os2borgerpc-monitor.service" which runs the script "usb-monitor" as a daemon.
#    "usb-monitor" is a python-script which continually reads from a FIFO, we name "usb-event".
#
#    If that FIFO receives any data, "usb-monitor" logs and locks the user named "user" out.
#
#    udev writes to that FIFO, by calling the shell script "on-usb-event", when it detects any USB related events.
#
#    You can check whether a user has been expired by checking the last column for the user in /etc/shadow

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

ACTIVATE=$1

SERVICE_FILE="/etc/systemd/system/os2borgerpc-usb-monitor.service"
USB_MONITOR="/usr/share/os2borgerpc/lib/usb-monitor.py"
ON_USB_EVENT="/usr/share/os2borgerpc/lib/on-usb-event.sh"
USB_RULES="/etc/udev/rules.d/99-os2borgerpc-usb-event.rules"

if [ -f "$SERVICE_FILE" ]; then
  systemctl disable --now os2borgerpc-usb-monitor.service
fi

rm --force /usr/local/lib/os2borgerpc/usb-monitor /usr/local/lib/os2borgerpc/on-usb-event

if [ "$ACTIVATE" = "True" ]; then
    mkdir --parents "$(dirname $USB_MONITOR)"

    cat <<END > $USB_MONITOR
#!/usr/bin/env python3

from os import mkfifo, unlink
from os.path import exists
import subprocess
import datetime

PIPE = "/var/lib/os2borgerpc/usb-event"
USB_EVENT_LOG = "/var/log/usb-events.log"


# Old versions of this script expired to 1970-01-02 like hard_shutdown_lockdown.sh
# It was changed to different dates so we can distinguish which
# script locked the account from the security event directly
def lockdown():
    """Disable the user account."""
    subprocess.run(["usermod", "-e", "1970-01-05", "user"])
    subprocess.run(["loginctl", "terminate-user", "user"])

def get_current_devices():
    """Get the ids of the currently connected usb devices."""
    encoding = 'utf-8'
    lsusb_output = subprocess.check_output("lsusb")
    device_ids = []
    for info in lsusb_output.split(b'\n'):
        if info:
            device_ids.append(str(info, encoding))
    return device_ids

def make_log_entry(device):
    current_datetime = datetime.datetime.now()
    entry = f"{current_datetime.day} {current_datetime.strftime('%B')} {current_datetime.year} " \
            f"{current_datetime.hour}:{current_datetime.minute} - USB-event caused by {device}\n"
    return entry

def main():
    # Make sure we always start with a fresh FIFO
    try:
        unlink(PIPE)
    except FileNotFoundError:
        pass

    mkfifo(PIPE)
    try:
        while True:
            devices_before_event = get_current_devices()
            with open(PIPE, "rt") as fp:
                # Reading from a FIFO should block until the udev helper script
                # gives us a signal. Lock the system immediately when that
                # happens and then write the log
                content = fp.read()
                lockdown()
                devices_after_event = get_current_devices()
                changed_device = list(set(devices_before_event).symmetric_difference(set(devices_after_event)))
                entries = ""
                for device in changed_device:
                    entry = make_log_entry(device)
                    entries += entry
                with open(USB_EVENT_LOG, "a") as log:
                    log.write(entries)
    finally:
        unlink(PIPE)


if __name__ == "__main__":
    main()
END
    chmod 700 $USB_MONITOR

    cat <<END > $SERVICE_FILE
[Unit]
Description=OS2borgerPC USB monitoring service

[Service]
Type=simple
ExecStart=$USB_MONITOR
# It's important that we stop the Python process, stuck in a blocking read,
# with SIGINT rather than SIGTERM so that its finaliser has a chance to run
KillSignal=SIGINT

[Install]
WantedBy=display-manager.service
END
    systemctl enable --now os2borgerpc-usb-monitor.service

    cat <<END > $ON_USB_EVENT
#!/bin/sh

if [ -p "/var/lib/os2borgerpc/usb-event" ]; then
    # Use dd with oflag=nonblock to make sure that we don't append to the pipe
    # if the reader isn't yet running
    echo "\$@" | dd oflag=nonblock \
            of=/var/lib/os2borgerpc/usb-event status=none
fi
END
    chmod 700 $ON_USB_EVENT

    cat <<END > $USB_RULES
SUBSYSTEM=="usb", TEST=="/var/lib/os2borgerpc/usb-event", RUN{program}="$ON_USB_EVENT '%E{ACTION}' '\$sys\$devpath'"
END
else
    rm --force $ON_USB_EVENT $USB_RULES $USB_MONITOR $SERVICE_FILE
fi

udevadm control -R
