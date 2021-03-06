#!/usr/bin/env bash

#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    polkit_policy_shutdown.sh [ENFORCE]
#%
#% DESCRIPTION
#%    This script installs a mandatory PolicyKit policy that prevents the
#%    "user" or "lightdm" users from sleeping, hibernating, restarting or
#%    shutting down the system.
#%
#%    It takes one optional parameter: whether or not to enforce this policy.
#%    Use a boolean to decide whether to enforce the policy or not. A checked box
#%    enforces the policy and an unchecked removes it
#%
#================================================================
#- IMPLEMENTATION
#-    version         polkit_policy_shutdown.sh (magenta.dk) 1.0.0
#-    author          Alexander Faithfull
#-    copyright       Copyright 2019, 2020 Magenta ApS
#-    license         GNU General Public License
#-    email           af@magenta.dk
#-
#================================================================
#  HISTORY
#     2019/09/25 : af : dconf_policy_shutdown.sh created
#     2020/01/27 : af : This script created based on dconf_policy_shutdown.sh
#
#================================================================
# END_OF_HEADER
#================================================================

set -x

POLICY="/etc/polkit-1/localauthority/90-mandatory.d/10-os2borgerpc-no-user-shutdown.pkla"

if [ "$1" = "False" ]; then
    rm -f "$POLICY"
else
    if [ ! -d "$(dirname "$POLICY")" ]; then
        mkdir "$(dirname "$POLICY")"
    fi

    cat > "$POLICY" <<END
[Restrict system shutdown]
Identity=unix-user:user;unix-user:lightdm
Action=org.freedesktop.login1.hibernate*;org.freedesktop.login1.power-off*;org.freedesktop.login1.reboot*;org.freedesktop.login1.suspend*;org.freedesktop.login1.lock-sessions;org.freedesktop.login1.set-reboot*
ResultAny=no
ResultActive=no
ResultInactive=no
END
fi

# PolicyKit is supposed to monitor the /etc/polkit-1/localauthority folder, but
# err on the side of caution and restart the service
systemctl restart polkitd.service || systemctl restart polkit.service
