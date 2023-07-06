#! /usr/bin/env sh

SUPERUSER="superuser"
CITIZEN="user"
DESKTOP=$(basename "$(runuser -u $SUPERUSER xdg-user-dir DESKTOP)")
SHORTCUT_PATH="/home/$SUPERUSER/$DESKTOP/os2borgerpc-reenable-user-login.desktop"

cat << EOF > "$SHORTCUT_PATH"
  [Desktop Entry]
  Name=Unlock logins to the Citizen account
  Name[da]=Lås op for login til Borger-konto
  Name[sv]=Låsa upp inloggning till medborgarkonto
  Type=Application
  Exec=gnome-terminal -- sudo usermod -e '' $CITIZEN
  Icon=system-lock-screen
EOF

# Adjust the shortcut's permissions and activate it

chown $SUPERUSER:$SUPERUSER "$SHORTCUT_PATH"

runuser -u $SUPERUSER dbus-launch gio set "$SHORTCUT_PATH" metadata::trusted true
# Updating the timestamp of the file so gio realizes its changed. We've tried touch for this, but sometimes, strangely,
# that hasn't been enough
chmod u+x,go-rwx "$SHORTCUT_PATH"
