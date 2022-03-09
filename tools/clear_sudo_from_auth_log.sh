#! /usr/bin/env sh

# Related to recurring security event issues in at least in OS2borgerPC image 3.1.0
# Clears all sudo entries from auth.log, which stops the recurring sudo security events

sed -i '/sudo/d' /var/log/auth.log
