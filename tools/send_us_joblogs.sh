#! /usr/bin/env sh

# TODO: This script is unfinished but is meant for debugging

cd /home/superuser || exit 1

cp -r /var/lib/os2borgerpc/jobs .

# Delete all other files
find ./jobs -not -iname output.log --delete

# Remove the arguments from the log as it may contain sensitive data
for file in jobs/*/*; do sed -i '/Starting process/d' "$file"; done

# Create a zip file of the output-logs
zip -r output-logs.zip jobs

# TODO: Send the file somehow. Maybe base64 encode it and print it to screen so it's in the job log. Is it long enough?

#find /var/lib/os2borgerpc/jobs -name output.log | xargs -I {} zip /home/superuser/logs.zip {}
