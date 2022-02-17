#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    change_admin_site args $(admin site url) $(site UID)
#%
#% DESCRIPTION
#%    This script "migrates" a computer to a new admin site.
#%    
#%    This involves changing the admin site url and site uid in
#%    in the os2borgerpc config file and re-registering. 
#%
#================================================================
#- IMPLEMENTATION
#-    version         change_admin_site (magenta.dk) 0.0.1
#-    author          Søren Howe Gersager
#-    copyright       Copyright 2022, Magenta Aps"
#-    license         GNU General Public License
#-    email           shg@magenta-aps.dk
#-
#================================================================
#  HISTORY
#     2022/02/17 : shg : Script creation
#
#================================================================
# END_OF_HEADER
#================================================================

ADMIN_SITE_URL=$1
SITE_UID=$2

[ "$#" -lt 1 ] && printf "The script needs at least one argument. Exiting." && exit 1

set_os2borgerpc_config admin_url "$ADMIN_SITE_URL"

if [ -n "$SITE_UID" ]; then
    set_os2borgerpc_config site "$SITE_UID"
fi

os2borgerpc_register_in_admin