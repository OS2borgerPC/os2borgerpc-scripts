#! /usr/bin/env sh

# Minimal install of X and Chromium and connectivity.

# Not set -x because otherwise it prints out the contents of LOG_OUT as well, and so the output XML is invalid again...
set -e

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
LOG_OUT=$(apt-get install --assume-yes chromium-browser)
# Save exit status so we get the exit status of apt rather than from base64
EXIT_STATUS=$?
echo "$LOG_OUT" | base64

exit $EXIT_STATUS
