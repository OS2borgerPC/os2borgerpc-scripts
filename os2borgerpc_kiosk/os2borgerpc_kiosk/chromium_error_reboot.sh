#! /usr/bin/env bash

set -x

REBOOT_SCRIPT="/usr/share/os2borgerpc/bin/chromium_error_reboot.sh"
REBOOT_SERVICE="/etc/systemd/system/chromium_error_reboot.service"
COUNTER_FILE="/etc/os2borgerpc/reboot_counter.txt"
MAXIMUM_CONSECUTIVE_REBOOTS=5

ACTIVATE=$1

if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en regulær OS2borgerPC-maskine."
  exit 1
fi

mkdir --parents "$(dirname $REBOOT_SCRIPT)"
mkdir --parents "$(dirname $COUNTER_FILE)"

if [ "$ACTIVATE" = "False" ]; then
  systemctl disable "$(basename $REBOOT_SERVICE)"
  rm --force $REBOOT_SCRIPT $REBOOT_SERVICE $COUNTER_FILE
  exit 0
fi

echo "0" > $COUNTER_FILE

cat <<EOF > $REBOOT_SCRIPT
#! /usr/bin/env bash

sleep 120

if [ -z "\$(pgrep --list-full chrome)" ]; then
  COUNTER=\$(cat $COUNTER_FILE)
  COUNTER=\$((COUNTER+1))
  echo \$COUNTER > $COUNTER_FILE
  if [ \$COUNTER -le $MAXIMUM_CONSECUTIVE_REBOOTS ]; then
    reboot
  fi
else
  echo "0" > $COUNTER_FILE
fi
EOF

chmod 700 $REBOOT_SCRIPT

cat <<EOF > $REBOOT_SERVICE
[Unit]
Description=Chromium error reboot service

[Service]
Type=simple
ExecStart=$REBOOT_SCRIPT

[Install]
WantedBy=multi-user.target
EOF

systemctl enable "$(basename $REBOOT_SERVICE)"