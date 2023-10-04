#!/bin/sh

set -x

LOGIN_COUNT_SCRIPT="/usr/local/lib/os2borgerpc/count_daily_logins.sh"
LOGIN_COUNT_SERVICE="/etc/systemd/system/os2borgerpc-count_daily_logins.service"
DATE_FILE="/etc/os2borgerpc/last_on_date.txt"
CONFIG_NAME="login_counts"
DATA_LIMIT=89 # This is one less than the number of days that are stored
ROOTCRON_TMP="/etc/rootcron"

mkdir --parents "$(dirname $LOGIN_COUNT_SCRIPT)"
mkdir --aprents "$(dirname $DATE_FILE)"

crontab -l > $ROOTCRON_TMP

sed -i "/count_daily_logins/d" $ROOTCRON_TMP

echo "* 4 * * * $LOGIN_COUNT_SCRIPT" >> $ROOTCRON_TMP

crontab $ROOTCRON_TMP

rm --force $ROOTCRON_TMP

date -d "yesterday" +%F > $DATE_FILE

cat <<EOF > $LOGIN_COUNT_SCRIPT
#!/usr/bin/env bash

LAST_ON_DATE_FULL=\$(cat $DATE_FILE)
LAST_ON_DATE=\$(LANG=en_US.UTF-8 date -d "\$LAST_ON_DATE_FULL" "+%b %_d")
TODAY_DATE_FULL=\$(date -d "today" +%F)
echo \$TODAY_DATE_FULL > $DATE_FILE

YESTERDAY_DATE=\$(LANG=en_US.UTF-8 date -d "yesterday" "+%b %_d")
YESTERDAY_FULL_DATE=\$(date -d "yesterday" +%F)
LOG_FILE="/var/log/auth.log"

OLD_LOGIN_COUNTS=\$(get_os2borgerpc_config "$CONFIG_NAME")

if ! grep --quiet "\$LAST_ON_DATE" \$LOG_FILE; then
  LOG_FILE="var/log/auth.log.1"
fi

LOGIN_COUNT=\$(grep --text "\$LAST_ON_DATE" "\$LOG_FILE" | grep -c "New session c[^ ]* of user user")

if [ -z "\$OLD_LOGIN_COUNTS" ]; then
  CONFIG_VALUE=\$(echo "\$LAST_ON_DATE_FULL: \$LOGIN_COUNT")
else
  IFS="," read -ra OLD_COUNTS_ARRAY <<< "\$(echo "\$OLD_LOGIN_COUNTS" | sed "s/, /,/g")"
  IFS=":" read -ra NEWEST_OLD_COUNT <<< \${OLD_COUNTS_ARRAY[-1]}
  if [ \${NEWEST_OLD_COUNT[0]} = \$LAST_ON_DATE_FULL ] && [ \${NEWEST_OLD_COUNT[1]} -lt \$LOGIN_COUNT ]; then
    TEMP=\$(IFS="," ; echo "\${OLD_COUNTS_ARRAY[*]::\${#OLD_COUNTS_ARRAY[@]}-1}")
    IFS="," read -ra OLD_COUNTS_ARRAY <<< \$TEMP
  fi
  if [ \${#OLD_COUNTS_ARRAY[@]} -gt $DATA_LIMIT ]; then
    TEMP=\$(IFS="," ; echo "\${OLD_COUNTS_ARRAY[*]: -$DATA_LIMIT}")
    IFS="," read -ra OLD_COUNTS_ARRAY <<< \$TEMP
  fi
  OLD_LOGIN_COUNTS=\$(IFS="," ; echo "\${OLD_COUNTS_ARRAY[*]}" | sed "s/,/, /g")
  CONFIG_VALUE=\$(echo "\$OLD_LOGIN_COUNTS, \$LAST_ON_DATE_FULL: \$LOGIN_COUNT")
fi

if ! grep --quiet "\$LAST_ON_DATE_FULL" <<< "\$OLD_LOGIN_COUNTS"; then
  set_os2borgerpc_config "$CONFIG_NAME" "\$CONFIG_VALUE"
  os2borgerpc_push_config_keys "$CONFIG_NAME"
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