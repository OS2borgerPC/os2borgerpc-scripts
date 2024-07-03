#!/bin/bash

# Make Chromium autostart, fx. in preparation for OS2Display.

# Policies:
# AutofillAddressEnabled: Disable Autofill of addresses
# AutofillCreditCardEnabled: Disable Autofill of payment methods
# AutoplayAllowed: Allow auto-playing content. Relevant for displaying videos without user input?
# PasswordManagerEnabled: Disables the password manager, which should also prevent autofilling passwords
# TranslateEnabled: Don't translate or prompt for translation of content that isn't in the current locale on a computer that's often userless
#
# Launch args:
# Note: Convert these to policies if it is or becomes possible!
# --enable-offline-auto-reload: This should reload all pages if the browser lost internet access and regained it
# --password-store=basic: Don't prompt user to unlock GNOME keyring on a computer that's often userless

set -ex

TIME=$1
URL=$2
WIDTH=$3
HEIGHT=$4
ORIENTATION=$5

CUSER="chrome"
XINITRC="/home/$CUSER/.xinitrc"
BSPWM_CONFIG="/home/$CUSER/.config/bspwm/bspwmrc"
CHROMIUM_SCRIPT='/usr/share/os2borgerpc/bin/start_chromium.sh'
ROTATE_SCREEN_SCRIPT_PATH="/usr/share/os2borgerpc/bin/rotate_screen.sh"
OLD_ROTATE_SCREEN_SCRIPT_PATH="/usr/local/bin/rotate_screen.sh"
ENVIRONMENT_FILE="/etc/environment"
AUTOLOGIN_SCRIPT="/usr/share/os2borgerpc/bin/autologin.sh"
AUTOLOGIN_COUNTER="/etc/os2borgerpc/login_counter.txt"
COUNTER_RESET_SERVICE="/etc/systemd/system/reset_login_counter.service"
REBOOT_SCRIPT="/usr/share/os2borgerpc/bin/chromium_error_reboot.sh"
MAXIMUM_CONSECUTIVE_AUTOLOGINS=3

if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en regulær OS2borgerPC-maskine."
  exit 1
fi

# Create user.
# TODO: This is now built into the image instead, but for now it's kept here for backwards compatibility with old images
# useradd will fail on multiple runs, so prevent that
if ! id $CUSER &>/dev/null; then
  useradd $CUSER --create-home --password 12345 --shell /bin/bash --user-group --comment "Chrome"
fi

# Autologin default user
mkdir --parents /etc/systemd/system/getty@tty1.service.d

# Note: The empty ExecStart is not insignificant!
# By default the value is appended, so the empty line changes it to an override
# We make agetty use our own login-program instead of /bin/login
# so we can customize the behavior
cat << EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --login-program $AUTOLOGIN_SCRIPT --autologin $CUSER %I $TERM
Type=idle
EOF

# Create the autologin script

# Ensure that the folder exists
mkdir --parents "$(dirname $AUTOLOGIN_SCRIPT)"

cat << EOF > $AUTOLOGIN_SCRIPT
#! /usr/bin/env bash
COUNTER=\$(cat $AUTOLOGIN_COUNTER)
COUNTER=\$((COUNTER+1))
echo \$COUNTER > $AUTOLOGIN_COUNTER
if [ \$COUNTER -le $MAXIMUM_CONSECUTIVE_AUTOLOGINS ]; then
  if [ \$COUNTER -gt 1 ]; then
    # Sleep before autologin attempts other than the first
    sleep 10
  fi
  # Autologin as $CUSER
  /bin/login -f $CUSER
else
  # Regular login prompt
  /bin/login
fi
EOF

# To maintain the functionality of the error reboot script
if [ -f "$REBOOT_SCRIPT" ]; then
  sed --in-place --expression "\@else@{ n; n; s@/bin/login@$REBOOT_SCRIPT@ }" \
      --expression "s/Regular login prompt/Reboot the computer/" $AUTOLOGIN_SCRIPT
fi

chmod 700 $AUTOLOGIN_SCRIPT

# Create login counter
echo "0" > $AUTOLOGIN_COUNTER

# Create service to reset counter when
# the computer is booted
cat << EOF > $COUNTER_RESET_SERVICE
[Unit]
Description=Reset the autologin counter when the computer starts

[Service]
Type=oneshot
ExecStart=sh -c 'echo "0" > $AUTOLOGIN_COUNTER'

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now "$(basename $COUNTER_RESET_SERVICE)"

# Create script to rotate screen

# ...remove the rotate script from its previous location
rm --force $OLD_ROTATE_SCREEN_SCRIPT_PATH

cat << EOF > $ROTATE_SCREEN_SCRIPT_PATH
#!/usr/bin/env sh

set -x

TIME=\$1
ORIENTATION=\$2

sleep \$TIME

export XAUTHORITY=/home/$CUSER/.Xauthority

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

# Kiosk mode cannot currently be set via policy
# so we set the value in the environment file
# To prevent overwriting changes made by other scripts
# we only set the value if it does not exist
if ! grep --quiet "BPC_KIOSK" $ENVIRONMENT_FILE; then
  echo 'BPC_KIOSK="--kiosk"' >> $ENVIRONMENT_FILE
fi

# Create a script dedicated to launch chromium, which both xinit or any wm
# launches, to avoid logic duplication, fx. having to update chromium settings
# in multiple files
# If this script's path/name is changed, remember to change it in
# wm_keyboard_install.sh as well
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
if [ "\$WM" == "wm" ]
then
  chromium-browser "\$BPC_KIOSK" "\$IURL" "\$COMMON_SETTINGS"
else
  exec chromium-browser "\$BPC_KIOSK" "\$IURL" --window-size="\$IWIDTH","\$IHEIGHT" --window-position=0,0 "\$COMMON_SETTINGS"
fi
EOF
chmod +x "$CHROMIUM_SCRIPT"

# Launch chromium upon starting up X
cat << EOF > $XINITRC
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

# If bspwm config (for the onscreen keyboard) is found, restore starting it up instead of starting chromium directly
if [ -f $BSPWM_CONFIG ]; then
# Don't auto-start chromium from xinitrc
  sed -i "s,\(.*$CHROMIUM_SCRIPT.*\),#\1," $XINITRC

  # Instead autostart bspwm
	cat <<- EOF >> $XINITRC
		exec bspwm
	EOF
fi

# Start X upon login
PROFILE="/home/$CUSER/.profile"
if ! grep --quiet -- 'exit' $PROFILE; then # Ensure idempotency
  # This first line cleans up after previous versions of the script
  sed --in-place --expression "/startx/d" --expression "/for i in/d" --expression "/sleep/d" \
      --expression "/done/d" --expression "/chromium_error_reboot/d" $PROFILE
  cat << EOF >> $PROFILE
startx
exit
EOF
fi
