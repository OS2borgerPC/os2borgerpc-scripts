#!/bin/bash
# Make Chromium autostart, fx. in preparation for OS2Display.

set -ex

# Initialize parameters

TIME=$1
URL=$2
WIDTH=$3
HEIGHT=$4
ORIENTATION=$5

# Setup Chromium user.
# useradd will fail on multiple runs, so prevent that
if ! id chrome &>/dev/null; then
  useradd chrome -m -p 12345 -s /bin/bash -U
fi
chfn -f Chrome chrome

# Autologin default user

mkdir -p /etc/systemd/system/getty@tty1.service.d

cat << EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin chrome %I $TERM
Type=idle
EOF

# Create script to rotate screen

cat << EOF > /usr/local/bin/rotate_screen.sh
#!/usr/bin/env bash
set -x

sleep $TIME

export XAUTHORITY=/home/chrome/.Xauthority
# Rotate screen
active_monitors=(\$(xrandr --listactivemonitors -display :0 | grep -v Monitors | awk '{ print \$4; }'))
# If more than one monitor, rotate them all.

for m in "\${active_monitors[@]}"
do
    xrandr --output \$m --rotate $ORIENTATION -display :0
done

EOF

chmod +x /usr/local/bin/rotate_screen.sh &


# Create a script dedicated to launch chromium, which both xinit or any wm
# launches, to avoid logic duplication, fx. having to update chromium settings
# in multiple files
# If this script's path/name is changed, remember to change it in
# install_wm_keyboard.sh as well
CHROMIUM_SCRIPT='/usr/share/os2borgerpc/bin/start_chromium.sh'
mkdir -p "$(dirname "$CHROMIUM_SCRIPT")"

cat << EOF > "$CHROMIUM_SCRIPT"
#!/bin/sh

WM=\$1
IURL="$URL"
IWIDTH="$WIDTH"
IHEIGHT="$HEIGHT"
COMMON_SETTINGS="--password-store=basic --autoplay-policy=no-user-gesture-required --disable-translate --enable-offline-auto-reload"
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

# Launch chrome upon startup
XINITRC="/home/chrome/.xinitrc"
cat << EOF > $XINITRC
#!/bin/sh

xset s off
xset s noblank
xset -dpms

sleep 20

/usr/local/bin/rotate_screen.sh

# Launch chromium with its non-WM settings
exec $CHROMIUM_SCRIPT nowm
EOF

# Start X upon login
if ! grep -q -- 'startx' "$XINITRC"; then # Ensure idempotency
  echo "startx" >> /home/chrome/.profile
fi
