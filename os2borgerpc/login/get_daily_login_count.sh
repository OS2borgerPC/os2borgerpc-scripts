#!/bin/sh

set -x

LOGIN_COUNT_SCRIPT="/usr/local/lib/os2borgerpc/count_daily_logins.sh"
LOGIN_COUNT_SERVICE="/etc/systemd/system/os2borgerpc-count_daily_logins.service"
DATE_FILE="/etc/os2borgerpc/last_on_date.txt"
CONFIG_NAME="login_counts"
DATA_LIMIT=89 # This is one less than the number of days that are stored
ROOTCRON_TMP="/tmp/rootcron"

ACTIVATE=$1

mkdir --parents "$(dirname $LOGIN_COUNT_SCRIPT)" "$(dirname $DATE_FILE)"

crontab -l > $ROOTCRON_TMP

sed -i "/count_daily_logins/d" $ROOTCRON_TMP

if [ "$ACTIVATE" = "False" ]; then
  systemctl disable "$(basename $LOGIN_COUNT_SERVICE)"
  crontab $ROOTCRON_TMP
  rm --force $LOGIN_COUNT_SCRIPT $LOGIN_COUNT_SERVICE \
              $DATE_FILE $ROOTCRON_TMP
  exit 0
fi

echo "0 * * * * $LOGIN_COUNT_SCRIPT" >> $ROOTCRON_TMP

crontab $ROOTCRON_TMP

rm --force $ROOTCRON_TMP

# When the script is run, get value for the day before
# This might not be necessary, but it's convenient for testing
date -d "yesterday" +%F > $DATE_FILE

cat <<EOF > $LOGIN_COUNT_SCRIPT
#!/usr/bin/env bash

LAST_ON_DATE_FULL=\$(cat $DATE_FILE)
# Convert to the date format used in auth.log
LAST_ON_DATE=\$(LANG=en_US.UTF-8 date -d "\$LAST_ON_DATE_FULL" "+%b %_d")
TODAY_DATE_FULL=\$(date -d "today" +%F)

# Stop if the date to be checked is today
if [ "\$LAST_ON_DATE_FULL" = "\$TODAY_DATE_FULL" ]; then
  exit 0
fi

LOG_FILE="/var/log/auth.log"

OLD_LOGIN_COUNTS=\$(/usr/local/bin/get_os2borgerpc_config "$CONFIG_NAME")

if ! grep --quiet "\$LAST_ON_DATE" \$LOG_FILE; then
  LOG_FILE="/var/log/auth.log.1"
fi

LOGIN_COUNT=\$(grep --text "\$LAST_ON_DATE" "\$LOG_FILE" | grep -c "New session c[^ ]* of user user")

if [ -z "\$OLD_LOGIN_COUNTS" ]; then
  CONFIG_VALUE=\$(echo "\$LAST_ON_DATE_FULL: \$LOGIN_COUNT")
else
  # Remove old values to ensure that we never save more than DATA_LIMIT+1 days
  IFS="," read -ra OLD_COUNTS_ARRAY <<< "\$(echo "\$OLD_LOGIN_COUNTS" | sed "s/, /,/g")"
  if [ \${#OLD_COUNTS_ARRAY[@]} -gt $DATA_LIMIT ]; then
    OLD_LOGIN_COUNTS=\$(IFS="," ; echo "\${OLD_COUNTS_ARRAY[*]: -$DATA_LIMIT}" | sed "s/,/, /g")
  fi
  CONFIG_VALUE=\$(echo "\$OLD_LOGIN_COUNTS, \$LAST_ON_DATE_FULL: \$LOGIN_COUNT")
fi

if grep --quiet "\$LAST_ON_DATE_FULL" <<< "\$OLD_LOGIN_COUNTS"; then
  echo \$TODAY_DATE_FULL > $DATE_FILE
  exit 0
fi

OLD_CONFIG_VALUE=\$(/usr/local/bin/get_os2borgerpc_config "$CONFIG_NAME")
/usr/local/bin/set_os2borgerpc_config "$CONFIG_NAME" "\$CONFIG_VALUE"
PUSH_OUTPUT=\$(/usr/local/bin/os2borgerpc_push_config_keys "$CONFIG_NAME")
if grep --quiet "The following keys were pushed to the admin system:" <<< "\$PUSH_OUTPUT"; then
  echo \$TODAY_DATE_FULL > $DATE_FILE
else
  /usr/local/bin/set_os2borgerpc_config "$CONFIG_NAME" "\$OLD_CONFIG_VALUE"
fi
EOF

chmod 700 $LOGIN_COUNT_SCRIPT

cat <<EOF > $LOGIN_COUNT_SERVICE
[Unit]
Description=OS2borgerPC count daily logins service

[Service]
Type=simple
ExecStart=$LOGIN_COUNT_SCRIPT

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now "$(basename $LOGIN_COUNT_SERVICE)"