#! /usr/bin/env sh

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

USERNAME=user
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

# Determine the name of the user desktop directory. This can be done simply
# because this file is run as user during the execution of GIO_LAUNCHER
# which already makes sure that /home/user/.config/user-dirs.dirs exists
DESKTOP=\$(xdg-user-dir DESKTOP)

for FILE in \$DESKTOP/*.desktop; do
  gio set "\$FILE" metadata::trusted true
done

kill \$DBUS_PROCESS
EOF

# Script to activate programs on the desktop
# (equivalent to right-click -> Allow Launching)
cat << EOF > "$GIO_LAUNCHER"
#! /usr/bin/env sh

# Determine the name of the user desktop directory. This is done via xdg-user-dir,
# which checks the /home/user/.config/user-dirs.dirs file. To ensure this file exists,
# we run xdg-user-dirs-update, which generates it based on the environment variable
# LANG. This variable is empty in lightdm so we first export it
# based on the value stored in /etc/default/locale
export \$(grep LANG= /etc/default/locale | tr -d '"')
runuser -u user xdg-user-dirs-update
DESKTOP=\$(runuser -u $USERNAME xdg-user-dir DESKTOP)

# Gio expects the user to own the file so temporarily change that
for FILE in \$DESKTOP/*.desktop; do
  chown $USERNAME:$USERNAME \$FILE
done

su --login user --command $GIO_SCRIPT

# Now set the permissions back to their restricted form
for FILE in \$DESKTOP/*.desktop; do
  chown root:$USERNAME "\$FILE"
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

# Make sure to insert this line before the desktop is made immutable
# in case desktop_toggle_writable has already been run
# Also make sure to only insert the line once
sed -i "0,\@chown -R \$USERNAME:\$USERNAME /home/\$USERNAME@ s@@&\n$GIO_LAUNCHER@" $USER_CLEANUP
