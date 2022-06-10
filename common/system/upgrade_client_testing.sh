#!/usr/bin/env sh

set -ex

# Updates the OSborgerPC client to a test version stored on the test server

FILE=os2borgerpc_client.tar.gz

# IMPORTANT!: Remove old events identified, as this file may contain the same event duplicated many times in older clients.
rm --force /etc/os2borgerpc/security/securityevent.csv

# Remove old parameters.json for all previous jobs as they may contain e.g. passwords
rm /var/lib/os2borgerpc/jobs/*/parameters.json

# Set the correct, more restrictive permissions on all previous jobs
chmod --recursive 700 /var/lib/os2borgerpc

# Fix permissions on /home/superuser
chmod -R 700 /home/superuser

cd /tmp/ || exit 1
curl https://os2borgerpc-media-test.magenta.dk/div/os2borgerpc_client-1.3.0.tar.gz --output $FILE
pip install $FILE

# Cleanup afterwards
rm --force $FILE
