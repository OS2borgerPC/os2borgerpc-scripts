#!/bin/sh

#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    hard_shutdown_lockdown.sh [ENFORCE]
#%
#% DESCRIPTION
#%    This script installs two system services:
#&
#%    shutdown_monitor.service & shutdown_monitor.timer - checks
#%    for a shutdown_lockfile at boot, and if it does not exist,
#%    locks the user account
#%
#%    create_shutdown_lockfile.service - creates a 
#%    shutdown_lockfile during a normal reboot/poweroff    
#%
#%    Logins are disabled with the user account expiry mechanism.
#%
#%    It takes one optional parameter: whether or not to enforce this policy.
#%    Use a boolean to decide whether or not to enforce the policy. A checked
#%    box will enable the script, an unchecked box will remove the policy
#%
#%    For use with the "unexpire_user.sh" and
#%    "detect_user_expired_event.py" script
#%
#%
#================================================================
#- IMPLEMENTATION
#-    version         hard_shutdown_lockdown.sh (magenta.dk) 1.0.0
#-    author          Søren Howe Gersager
#-    copyright       Copyright 2021 Magenta ApS
#-    license         GNU General Public License
#-    email           shg@magenta.dk
#-
#================================================================
#  HISTORY
#     2021/10/18 : shg : Script created
#
#================================================================
# END_OF_HEADER
#================================================================

set -x

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

    cat <<"END" > /usr/local/lib/os2borgerpc/check_shutdown_lockfile.py
#!/usr/bin/env python3

from os import remove
from os.path import exists
from subprocess import run

SHUTDOWN_FILE = "/etc/os2borgerpc/shutdown_lockfile"

def main():
    """Check if shutdown_lockfile exists, if not, expire the user account."""
    if exists(SHUTDOWN_FILE):
        remove(SHUTDOWN_FILE)
    else:
        run(["usermod", "-e", "1", "user"])


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
