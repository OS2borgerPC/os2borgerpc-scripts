#! /usr/bin/env bash

set -x

REBOOT_SCRIPT="/usr/share/os2borgerpc/bin/chromium_error_reboot.sh"
RESET_COUNTER_SCRIPT="/usr/share/os2borgerpc/bin/chromium_reboot_counter_reset.sh"
RESET_COUNTER_SERVICE="/etc/systemd/system/chromium_reboot_counter_reset.service"
PROFILE="/home/chrome/.profile"
COUNTER_FILE="/home/chrome/reboot_counter.txt"
MAXIMUM_CONSECUTIVE_REBOOTS=5

ACTIVATE=$1

if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en regulær OS2borgerPC-maskine."
  exit 1
fi

mkdir --parents "$(dirname $REBOOT_SCRIPT)"

# Ensure idempotency
sed --in-place --expression "/startx/d" --expression "/for i in/d" --expression "/sleep/d" \
    --expression "/done/d" --expression "/$(basename $REBOOT_SCRIPT)/d" $PROFILE

if [ "$ACTIVATE" = "False" ]; then
  systemctl disable "$(basename $RESET_COUNTER_SERVICE)"
  rm --force $REBOOT_SCRIPT $RESET_COUNTER_SCRIPT $RESET_COUNTER_SERVICE $COUNTER_FILE
  echo "startx" >> $PROFILE
  exit 0
fi

echo "0" > $COUNTER_FILE
chmod 666 $COUNTER_FILE

cat <<EOF >> $PROFILE
for i in 1 2 3; do
  startx
  sleep 10
done
$REBOOT_SCRIPT
EOF

cat <<EOF > $REBOOT_SCRIPT
#! /usr/bin/env bash

COUNTER=\$(cat $COUNTER_FILE)
COUNTER=\$((COUNTER+1))
echo \$COUNTER > $COUNTER_FILE
if [ \$COUNTER -le $MAXIMUM_CONSECUTIVE_REBOOTS ]; then
  reboot
fi
EOF

chmod 755 $REBOOT_SCRIPT

cat <<EOF > $RESET_COUNTER_SCRIPT
#! /usr/bin/env bash

sleep 120

if [ -n "\$(pgrep --list-full chrome)" ]; then
  echo "0" > $COUNTER_FILE
fi
EOF

chmod 700 $RESET_COUNTER_SCRIPT

cat <<EOF > $RESET_COUNTER_SERVICE
[Unit]
Description=OS2borgerPC chromium error reboot service

[Service]
Type=simple
ExecStart=$RESET_COUNTER_SCRIPT

[Install]
WantedBy=multi-user.target
EOF

systemctl enable "$(basename $RESET_COUNTER_SERVICE)"
