#! /usr/bin/env sh

# Minimal install of X and Chromium and connectivity.

# Not set -x because otherwise it prints out the contents of LOG_OUT as well, and so the output XML is invalid again...
set -e

if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en regulær OS2borgerPC-maskine."
  exit 1
fi

# Log output in English, please. More useable as search terms when debugging.
export LANG=en_US.UTF-8
export DEBIAN_FRONTEND=noninteractive

apt-get update --assume-yes

apt-get install --assume-yes xinit xserver-xorg-core x11-xserver-utils --no-install-recommends --no-install-suggests
apt-get install --assume-yes xdg-utils xserver-xorg-video-qxl xserver-xorg-video-intel xserver-xorg-video-all xserver-xorg-input-all libleveldb-dev
printf '%s\n' "The following output from chromium install is base64 encoded. Why?:" \
              "Chromium-install writes 'scroll'-comments to keep progress to a single line instead of taking up the entire screen," \
              "and this currently results in invalid XML, when the answer is sent back to the server"
printf '\n'

# This section is a workaround to handle an error in Ubuntu server 22.04
# that causes certain snap installs to trigger DNS problems on wifi.
# Chromium is only available as a snap and is one of the affected snaps.
# The workaround installs a service that periodically restarts
# systemd-resolved if it fails to ping google.com.
# If "snap install chromium" can run via wifi without causing DNS problems
# then the workaround is no longer necessary
if lsb_release -d | grep --quiet 22; then
  DNS_FIX_SCRIPT="/usr/local/lib/os2borgerpc/DNS_fix.py"
  DNS_FIX_SERVICE="/etc/systemd/system/os2borgerpc-DNS_fix.service"
  mkdir --parents "$(dirname $DNS_FIX_SCRIPT)"
  cat << EOF > $DNS_FIX_SCRIPT
#! /usr/bin/env python3

import os
import subprocess
import time

def main():
  while True:
    time.sleep(30)
    wifi_check = os.system("ping -c 1 google.com")
    # If ping fails, restart systemd-resolved
    if wifi_check != 0:
      subprocess.run(["systemctl", "restart", "systemd-resolved"])

if __name__ == '__main__':
  main()
EOF

  chmod 700 $DNS_FIX_SCRIPT

  cat <<EOF > $DNS_FIX_SERVICE
[Unit]
Description=OS2borgerPC Kiosk restart systemd-resolved service

[Service]
Type=simple
ExecStart=$DNS_FIX_SCRIPT

[Install]
WantedBy=multi-user.target
EOF

  systemctl enable --now "$(basename $DNS_FIX_SERVICE)"
fi

# Chromium is only available as a snap and will also be installed as
# a snap when using apt-get install
LOG_OUT=$(apt-get install --assume-yes chromium-browser)
# Save exit status so we get the exit status of apt rather than from base64
EXIT_STATUS=$?
echo "$LOG_OUT" | base64

exit $EXIT_STATUS
