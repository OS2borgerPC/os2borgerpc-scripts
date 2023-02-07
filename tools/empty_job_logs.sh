#! /usr/bin/env sh

# This is useful if a given job has a job log with invalid contents, which it repeatedly tries to send to the server,
# and thus all jobs end up in an "Afsendt" state.
# Fx. you get errors like:
# xmlrpc.client.Fault: <Fault 1: "<class 'xml.parsers.expat.ExpatError'>:not well-formed (invalid token): line 538, column 0">

# Replaces all job logs contents with the text "Emptied log"
# shellcheck disable=SC2156
find /var/lib/os2borgerpc/jobs -name output.log -exec sh -c 'echo "Emptied log" > {}' \;
# Alternate approach that would empty the file
# find /var/lib/os2borgerpc/jobs -name output.log -exec truncate -s 0 {} \;
