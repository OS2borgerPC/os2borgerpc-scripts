#!/usr/bin/env sh

# Updates the OSborgerPC client and settings
# Not relevant for new machines as they have saner defaults, but it's a good idea when upgrading older machines (machines instaled from images 3.1.0 (maybe even 3.1.1) or older)

set -ex

# IMPORTANT!: Remove old events identified, as this file may contain the same event duplicated many times in older clients.
rm --force /etc/os2borgerpc/security/securityevent.csv

# Remove old parameters.json for all previous jobs (status is DONE or FAILED) as they may contain sensitive information
for j in /var/lib/os2borgerpc/jobs/*; do
  if [ "$(cat "$j"/status)" = "DONE" ] || [ "$(cat "$j"/status)" = "FAILED" ]; then
      rm --force "$j/parameters.json"
  fi
done

# Set the correct, more restrictive permissions on all previous jobs
chmod --recursive 700 /var/lib/os2borgerpc

# Determine the name of the superuser desktop directory.
DESKTOP=$(runuser -u superuser xdg-user-dir DESKTOP)

# More restrictive permissions on /home/superuser
chmod -R 700 /home/superuser
chown -R superuser:superuser "$DESKTOP"

pip3 install --upgrade os2borgerpc-client
