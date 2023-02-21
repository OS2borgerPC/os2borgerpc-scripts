#!/bin/bash

# Make Chromium autostart, fx. in preparation for OS2Display.

set -ex

TIME=$1
URL=$2
WIDTH=$3
HEIGHT=$4
ORIENTATION=$5

USER="chrome"

# Setup Chromium user.
# useradd will fail on multiple runs, so prevent that
if ! id $USER &>/dev/null; then
  useradd $USER -m -p 12345 -s /bin/bash -U
fi

# Autologin default user
mkdir --parents /etc/systemd/system/getty@tty1.service.d

# Note: The empty ExecStart is not insignificant!
# By default the value is appended, so the empty line changes it to an override
cat << EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin $USER %I $TERM
Type=idle
EOF

# Create script to rotate screen

ROTATE_SCREEN_SCRIPT_PATH="/usr/share/os2borgerpc/bin/rotate_screen.sh"
OLD_ROTATE_SCREEN_SCRIPT_PATH="/usr/local/bin/rotate_screen.sh"

# ...remove the rotate script from its previous location
rm --force $OLD_ROTATE_SCREEN_SCRIPT_PATH

cat << EOF > $ROTATE_SCREEN_SCRIPT_PATH
#!/usr/bin/env sh

set -x

TIME=\$1
ORIENTATION=\$2

sleep \$TIME

export XAUTHORITY=/home/$USER/.Xauthority

# --listactivemonitors lists the primary monitor first
ALL_MONITORS=\$(xrandr --listactivemonitors | tail -n +2 | cut --delimiter ' ' --fields 6)

# Make all connected monitors display what the first monitor displays, rather than them extending the desktop
PRIMARY_MONITOR=\$(echo "\$ALL_MONITORS" | head -n 1)
OTHER_MONITORS=\$(echo "\$ALL_MONITORS" | tail -n +2)
echo "\$OTHER_MONITORS" | xargs -I {} xrandr --output {} --same-as "\$PRIMARY_MONITOR"

# Rotate screen - and if more than one monitor, rotate them all.
echo "\$ALL_MONITORS" | xargs -I {} xrandr --output {} --rotate \$ORIENTATION
EOF

chmod +x $ROTATE_SCREEN_SCRIPT_PATH


# Create a script dedicated to launch chromium, which both xinit or any wm
# launches, to avoid logic duplication, fx. having to update chromium settings
# in multiple files
# If this script's path/name is changed, remember to change it in
# wm_keyboard_install.sh as well
CHROMIUM_SCRIPT='/usr/share/os2borgerpc/bin/start_chromium.sh'
mkdir --parents "$(dirname "$CHROMIUM_SCRIPT")"

# TODO: Make URL a policy instead ("RestoreOnStarupURLs", see chrome_install.sh)
# password-store=basic and enable-offline-auto-reload do not exist as policies so we add them as flags.
cat << EOF > "$CHROMIUM_SCRIPT"
#!/bin/sh

WM=\$1
IURL="$URL"
IWIDTH="$WIDTH"
IHEIGHT="$HEIGHT"
COMMON_SETTINGS="--password-store=basic --enable-offline-auto-reload"
KIOSK="--kiosk"
INCOGNITO=""

if [ "\$WM" == "wm" ]
then
  chromium-browser "\$KIOSK" "\$IURL" "\$COMMON_SETTINGS"
else
  exec chromium-browser "\$KIOSK" "\$IURL" --window-size="\$IWIDTH","\$IHEIGHT" --window-position=0,0 "\$COMMON_SETTINGS"
fi
EOF
chmod +x "$CHROMIUM_SCRIPT"

# Launch chromium upon starting up X
cat << EOF > /home/$USER/.xinitrc
#!/bin/sh

xset s off
xset s noblank
xset -dpms

# Dev note: We used to have "sleep 20" hardcoded here but we removed it.
# Re-add if it causes timing issues. That said such potential issues should be
# solveable simple by raising the sleep parameter to rotate_screen.sh

$ROTATE_SCREEN_SCRIPT_PATH $TIME $ORIENTATION

# Launch chromium with its non-WM settings
exec $CHROMIUM_SCRIPT nowm
EOF

CHROMIUM_POLICY_FILE="/var/snap/chromium/current/policies/managed/os2borgerpc-defaults.json"
mkdir --parents "$(dirname "$CHROMIUM_POLICY_FILE")"
cat << EOF > $CHROMIUM_POLICY_FILE
{
  "AutoplayAllowed":true,
  "TranslateEnabled":false
}
EOF

# Start X upon login
if ! grep -q -- 'startx' /home/$USER/.xinitrc; then # Ensure idempotency
  echo "startx" >> /home/$USER/.profile
fi
