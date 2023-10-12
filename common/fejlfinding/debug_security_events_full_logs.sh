#!/usr/bin/env sh

# Consider merging this with "debug_security_events". The advantage of this script is that it can handle larger logs,
# and logs that may contain special characters.
# It could potentially be adjusted slightly to also allow it to optionally send .1 files, and the already gzipped .n files

# The admin site currently only accepts up to 2 MiB per request,
# and these logs are often larger than that, hence the compression.
# Base64 encoding is used as xmlrpc might not handle all the special characters correctly, or the adminsite may not
# display them correctly

AUTHLOG=/var/log/auth.log
SYSLOG=/var/log/syslog
KERNLOG=/var/log/kern.log

print_log() {
  LOG=$1
  echo "Size of the log file:"
  du -h "$LOG"
  echo "Log itself, base64 encoded to reduce the transfer size and remove special characters:"
  echo "" && gzip -c "$LOG" | base64 && echo ""
}

CHOSEN_LOG="$1"

if [ "$CHOSEN_LOG" = "auth" ]; then
  LOG=$AUTHLOG
elif [ "$CHOSEN_LOG" = "sys" ]; then
  LOG=$SYSLOG
else
  LOG=$KERNLOG
fi

if [ "$CHOSEN_LOG" = "all" ]; then
  print_log $AUTHLOG
  print_log $SYSLOG
  print_log $KERNLOG
else
  print_log $LOG
fi
