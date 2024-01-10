#!/usr/bin/env bash

#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    polkit_policy_shutdown.sh [ENFORCE]
#%
#% DESCRIPTION
#%    This script installs a mandatory PolicyKit policy that either prevents
#%    the "user" or "lightdm" users from suspending the system or
#%    prevents the "user" or "lightdm" users from suspending, restarting or shutting down
#%    the system.
#%
#%    It takes two optional parameters: whether to prevent suspending the system
#%    and whether to also prevent restart/shutdown.
#%    1. Use a boolean to decide whether or not to prevent the "user" from
#%       suspending the system. A checked box prevents suspend and an
#%       unchecked box allows it
#%    2. Use a boolean to decide whether or not to also prevent the "user" from
#%       restarting/shutting down the system. A checked box prevents
#%       restart/shutdown and an unchecked box allows it.
#%       Has no effect if input 1 is unchecked
#%
#================================================================
#- IMPLEMENTATION
#-    version         polkit_policy_shutdown.sh (magenta.dk) 1.0.0
#-    author          Alexander Faithfull
#-    modified by     Andreas Poulsen
#-    copyright       Copyright 2019, 2020 Magenta ApS
#-    license         GNU General Public License
#-    email           af@magenta.dk
#-
#================================================================
#  HISTORY
#     2019/09/25 : af : dconf_policy_shutdown.sh created
#     2020/01/27 : af : This script created based on dconf_policy_shutdown.sh
#     2022/11/01 : ap : This script modified to always disable hibernating/sleeping
#     2022/12/12 : ap : This script modified to allow separately
#                       disabling restart/shutdown or hibernating/sleeping
#
#================================================================
# END_OF_HEADER
#================================================================

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

POLICY="/etc/polkit-1/localauthority/90-mandatory.d/10-os2borgerpc-no-user-shutdown.pkla"

if [ ! -d "$(dirname "$POLICY")" ]; then
    mkdir -p "$(dirname "$POLICY")"
fi

if [ "$1" = "False" ]; then
  rm -f "$POLICY"
elif [ "$1" = "True" ] && [ "$2" = "False" ]; then
  cat > "$POLICY" <<END
[Restrict system shutdown]
Identity=unix-user:user;unix-user:lightdm
Action=org.freedesktop.login1.hibernate*;org.freedesktop.login1.suspend*;org.freedesktop.login1.lock-sessions
ResultAny=no
ResultActive=no
ResultInactive=no
END
else
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
