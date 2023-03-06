#! /usr/bin/env sh

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

USER=user
SHADOW=.skjult
GIO_LAUNCHER=/usr/share/os2borgerpc/bin/gio-fix-desktop-file-permissions.sh
GIO_SCRIPT=/usr/share/os2borgerpc/bin/gio-dbus.sh
USER_CLEANUP=/usr/share/os2borgerpc/bin/user-cleanup.bash

# Cleanup if they've run previous versions of this script. Suppress deletion errors.
rm --force /home/$SHADOW/.config/autostart/gio-fix-desktop-file-permissions.desktop

# Script that actually runs gio as the user and kills the dbus session it creates to do so
# afterwards
cat << EOF > "$GIO_SCRIPT"
#! /usr/bin/env sh

# gio needs to run as the user + dbus-launch, we have this script to create it and kill it afterwards
export \$(dbus-launch)
DBUS_PROCESS=\$\$

for FILE in /home/$USER/Skrivebord/*.desktop; do
  gio set "\$FILE" metadata::trusted true
done

kill \$DBUS_PROCESS
EOF

# Script to activate programs on the desktop
# (equivalent to right-click -> Allow Launching)
cat << EOF > "$GIO_LAUNCHER"
#! /usr/bin/env sh

# Gio expects the user to own the file so temporarily change that
for FILE in /home/$USER/Skrivebord/*.desktop; do
  chown $USER:$USER \$FILE
done

su --login user --command $GIO_SCRIPT

# Now set the permissions back to their restricted form
for FILE in /home/$USER/Skrivebord/*.desktop; do
  chown root:$USER "\$FILE"
  # In order for gio changes to take effect, it is necessary to update the file time stamp
  # This can be done with many commands such as chmod or simply touch
  # However, in some cases the files might not have execute permission so we add it with chmod
  chmod ug+x "\$FILE"
done
EOF

chmod u+x "$GIO_LAUNCHER"
chmod +x "$GIO_SCRIPT"

# Cleanup if there are previous entries of the gio fix script in the file
sed --in-place "\@$GIO_LAUNCHER@d" $USER_CLEANUP

printf "%s\n" "$GIO_LAUNCHER" >> $USER_CLEANUP
