#!/usr/bin/env bash

set_job_status() {
  STATUS=$1

  JOB_STATUS_PATH="$(dirname "$0")/status"

  echo -n "$STATUS" > "$JOB_STATUS_PATH"
}

# Set successful exit status for the job as otherwise it ends in PENDING and
# ultimately FAILED because it shuts down before it gets to the point
# where it reports back
set_job_status "DONE"

reboot

# If the script reaches this point the command failed, and so we re-set the status accordingly
set_job_status "FAILED"
