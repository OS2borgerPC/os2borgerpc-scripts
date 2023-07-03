#!/bin/sh

set -x

LOGIN_COUNT_SCRIPT="/usr/local/lib/os2borgerpc/count_daily_logins.sh"
LOGIN_COUNT_SERVICE="/etc/systemd/system/os2borgerpc-count_daily_logins.service"
ROOTCRON_TMP="/etc/rootcron"

mkdir --parents "$(dirname $LOGIN_COUNT_SCRIPT)"

crontab -l > $ROOTCRON_TMP

sed -i "/count_daily_logins/d" $ROOTCRON_TMP

echo "* 4 * * * $LOGIN_COUNT_SCRIPT" >> $ROOTCRON_TMP

crontab $ROOTCRON_TMP

rm --force $ROOTCRON_TMP

cat <<EOF > $LOGIN_COUNT_SCRIPT
#!/usr/bin/env bash

YESTERDAY_DATE=\$(LANG=en_US.UTF-8 date -d "yesterday" "+%b %_d")
LOG_FILE="/var/log/auth.log"

if ! grep --quiet "$YESTERDAY_DATE" \$LOG_FILE; then
  LOG_FILE="var/log/auth.log.1"
fi

LOGIN_COUNT=\$(grep --text "\$YESTERDAY_DATE" "\$LOG_FILE" | grep -c "New session c[^ ]* of user user")

set_os2borgerpc_config logins_yesterday \$LOGIN_COUNT

os2borgerpc_push_config_keys logins_yesterday
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

systemctl enable "$(basename $LOGIN_COUNT_SERVICE)"