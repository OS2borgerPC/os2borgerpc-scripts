#! /usr/bin/env sh

header() {
  MSG=$1
  printf "\n\n\n%s\n\n\n" "### $MSG: ###"
}

NUM_LINES="50"
SERVICE="heimdal-clienthost"

HEIMDAL_LOG_TODAY="/sbin/heimdal/HeimdalLogs/Heimdal.ClientHost/$(date -u +%d.%m.%Y).log"

header "Checking if the Heimdal service is running:"
# The service status could potentially change between the two commands, but writing it to a variable and echoing it did not
# produce very readable results, soooo
if systemctl status $SERVICE | grep --quiet "active (running)"; then
  echo "The heimdal service is running."
else
  echo "The heimdal service is NOT running."
fi
header "Echoing the full status of the service:"
systemctl status $SERVICE

header "Echoing the heimdal log file from today, only showing the lines containing the word \"license\":"
grep "license" "$HEIMDAL_LOG_TODAY"

header "Echoing the last $NUM_LINES lines of the Heimdal log from today:"
tail --lines $NUM_LINES "$HEIMDAL_LOG_TODAY"
