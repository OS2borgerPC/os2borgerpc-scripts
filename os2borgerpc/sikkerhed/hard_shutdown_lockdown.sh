#!/bin/sh

# SYNOPSIS
#    hard_shutdown_lockdown.sh [ENFORCE]
#
# DESCRIPTION
#    This script installs two system services:
#
#    shutdown_monitor.service & shutdown_monitor.timer - checks
#    for a shutdown_lockfile at boot, and if it does not exist,
#    locks the user account
#
#    create_shutdown_lockfile.service - creates a
#    shutdown_lockfile during a normal reboot/poweroff
#
#    Logins are disabled with the user account expiry mechanism.
#
#    It takes one optional parameter: whether or not to enforce this policy.
#    Use a boolean to decide whether or not to enforce the policy. A checked
#    box will enable the script, an unchecked box will remove the policy
#
#    For use with the "unexpire_user.sh" and
#    "detect_user_expired_event.py" script
#
# IMPLEMENTATION
#    copyright       Copyright 2021 Magenta ApS
#    license         GNU General Public License

# TECHNICAL NOTES
#    You can check whether a user has been expired by checking the last column for the user in /etc/shadow

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

ACTIVATE=$1


if [ "$ACTIVATE" = "True" ]; then
    mkdir -p /usr/local/lib/os2borgerpc

    cat <<"END" > /usr/local/lib/os2borgerpc/create_shutdown_lockfile.sh
#!/bin/sh

touch /etc/os2borgerpc/shutdown_lockfile
END
    chmod 700 /usr/local/lib/os2borgerpc/create_shutdown_lockfile.sh

    cat <<"END" > /etc/systemd/system/create_shutdown_lockfile.service
[Unit]
Description=Run create_shutdown_lockfile.sh when service stops

[Service]
Type=oneshot
RemainAfterExit=true
ExecStop=/usr/local/lib/os2borgerpc/create_shutdown_lockfile.sh

[Install]
WantedBy=multi-user.target
END
    systemctl enable --now create_shutdown_lockfile.service
    # Initially run create_shutdown_lockfile as the "OnBootSec" of check_shutdown_lockfile.py will fire immediately if the event was in the past:
    # "If a timer configured with OnBootSec= or OnStartupSec= is already in the past when the timer unit is activated, it will immediately elapse and the configured unit is started."
    /usr/local/lib/os2borgerpc/create_shutdown_lockfile.sh

    cat <<"END" > /usr/local/lib/os2borgerpc/check_shutdown_lockfile.py
#!/usr/bin/env python3

from os import remove
from os.path import exists
from subprocess import run

SHUTDOWN_FILE = "/etc/os2borgerpc/shutdown_lockfile"

# Old versions of this script expired to 1970-01-02 like lockdown_usb.sh
# They were changed to use different dates so we can distinguish which
# script locked the account from the security event directly
def main():
    """Check if shutdown_lockfile exists, if not, expire the user account."""
    if exists(SHUTDOWN_FILE):
        remove(SHUTDOWN_FILE)
    else:
        run(["usermod", "-e", "1970-01-04", "user"])


if __name__ == "__main__":
    main()
END
    chmod 700 /usr/local/lib/os2borgerpc/check_shutdown_lockfile.py

    cat <<"END" > /etc/systemd/system/shutdown_monitor.timer
[Unit]
Description=Run shutdown_monitor.service once at system boot

[Timer]
OnBootSec=0min

[Install]
WantedBy=timers.target
END

    cat <<"END" > /etc/systemd/system/shutdown_monitor.service
[Unit]
Description=OS2BorgerPC Shutdown monitoring service

[Service]
Type=oneshot
ExecStart=/usr/local/lib/os2borgerpc/check_shutdown_lockfile.py
END
    systemctl enable --now shutdown_monitor.timer

else
    systemctl disable --now shutdown_monitor.timer
    systemctl disable --now create_shutdown_lockfile.service
    rm -f /usr/local/lib/os2borgerpc/check_shutdown_lockfile.py \
            /etc/systemd/system/shutdown_monitor.service \
            /etc/systemd/system/shutdown_monitor.timer \
            /usr/local/lib/os2borgerpc/create_shutdown_lockfile.sh \
            /etc/systemd/system/create_shutdown_lockfile.service
fi
