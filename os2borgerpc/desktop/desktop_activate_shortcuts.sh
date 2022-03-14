#! /usr/bin/env sh

set -x

USER=user
AUTOSTART_DESKTOP_SYSTEMD_UNIT=/etc/systemd/system/gio-fix-desktop-file-permissions.service
SCRIPT_PATH=/usr/share/os2borgerpc/bin/gio-fix-desktop-file-permissions.sh

# Autorun file that simply launches the script below it after startup
#TODO: Alternately try: After=os2borgerpc-cleanup.service
cat << EOF > "$AUTOSTART_DESKTOP_SYSTEMD_UNIT"
[Unit]
Description=OS2borgerPC activate desktop shortcuts oneshot
After=os2borgerpc-cleanup.service

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH

[Install]
WantedBy=default.target
EOF

# Script to activate programs on the desktop
# (equivalent to right-click -> Allow Launching)
cat << EOF > "$SCRIPT_PATH"
#! /usr/bin/env sh

for FILE in /home/$USER/Skrivebord/*.desktop; do
  # The for loop runs even if no desktop files are found, and thus the systemd service fails to
  # start. Prevent that.
  if [ -n "\$FILE" ]; then
    # gio seemingly needs user ownership of the file
    chown $USER:$USER "\$FILE"
    su --login $USER --command "dbus-launch gio set \$FILE metadata::trusted true"
    # Can't make sense of this as it already has execute permissions, but it
    # won't work without it
    chmod ug+x "\$FILE"
    # Restoring root ownership of the file afterwards
    chown root:$USER "\$FILE"
  fi
done
EOF

# Proper permissions on this file since it's in the home dir
# chown $USER:$USER "$AUTOSTART_DESKTOP_FILE_PATH"

# The regular user needs to be able to execute the script
chmod o+x "$SCRIPT_PATH"

# Now enable the systemd unit which launches the activate desktop shortcuts script
systemctl enable --now $(basename $AUTOSTART_DESKTOP_SYSTEMD_UNIT)
