#!/bin/bash

#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    unexpire_user.sh
#%
#% DESCRIPTION
#%    This script unexpires the "user" account after it has been
#%    set expired.
#%
#%    For use with the "lockdown_usb.sh" and
#%    "detect_user_expired_event.py" script.
#%
#================================================================
#- IMPLEMENTATION
#-    version         unexpire_user.sh (magenta.dk) 1.0.0
#-    author          Søren Howe Gersager
#-    copyright       Copyright 2021 Magenta ApS
#-    license         GNU General Public License
#-    email           shg@magenta.dk
#-
#================================================================
#  HISTORY
#     2021/08/30 : shg: Creation
#================================================================
# END_OF_HEADER
#================================================================

usermod -e '' user