#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    logout_user
#%
#% DESCRIPTION
#%    This script will logout the user user immediately
#%
#================================================================
#- IMPLEMENTATION
#-    version         chrome_autostart (magenta.dk) 0.0.1
#-    author          Danni Als
#-    copyright       Copyright 2019, Magenta Aps"
#-    license         GNU General Public License
#-    email           danni@magenta.dk
#-
#================================================================
#  HISTORY
#     2019/13/06 : danni : Script creation
#
#================================================================
# END_OF_HEADER
#================================================================

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

user=$(who | grep -wo 'user')

if [ -z "$user" ]
then
    echo "User is not logged in..."
else
    pkill -KILL -u "$user"
    echo "User $user is now logged out."
fi
