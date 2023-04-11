#!/usr/bin/env bash

set -ex

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

ACTIVATE=$1
PROGRAM_OLD_PATH="/usr/bin/gnome-terminal"
PROGRAM_NEW_PATH="$PROGRAM_OLD_PATH.real"

# Restore access
if [ "$ACTIVATE" = 'True' ]; then
  # Making sure we're not removing the actual
  # gnome-terminal if run with the wrong argument or multiple times
  if grep --quiet 'zenity' "$PROGRAM_OLD_PATH"; then
    # Remove the permissions override and manually reset permissions to defaults
     # Suppress error to prevent set -e exiting in case the override no longer exists
    dpkg-statoverride --remove "$PROGRAM_NEW_PATH" || true
    chown root:root "$PROGRAM_OLD_PATH"
    chmod 755 "$PROGRAM_NEW_PATH"
    # Remove the shell script that prints the error message
    rm "$PROGRAM_OLD_PATH"
    # Remove location override and restore gnome-terminal.real back to gnome-terminal
    dpkg-divert --remove "$PROGRAM_OLD_PATH"
    # dpkg-divert can --rename it itself, but the problem with doing that is that in some images
    # dpkg-divert is not used, it was simply moved/copied, so that won't restore it, leaving you
    # with no gnome-control-center
    mv "$PROGRAM_NEW_PATH" "$PROGRAM_OLD_PATH"
  fi
else # Deny access

  if [ !  -f "$PROGRAM_NEW_PATH" ] # Don't divert and statoverride if they've already been done (idempotency)
  then
      dpkg-divert --rename --divert  "$PROGRAM_NEW_PATH" --add "$PROGRAM_OLD_PATH"
      dpkg-statoverride --update --add superuser root 770 "$PROGRAM_OLD_PATH"
  fi

	cat <<- EOF > "$PROGRAM_OLD_PATH"
		#!/bin/bash

		USER=\$(id -un)

		if [ \$USER == "user" ]; then
		  zenity --info --text="Terminalen er ikke tilgængelig for publikum."
		else
		  "$PROGRAM_NEW_PATH"
		fi
	EOF

  chmod +x "$PROGRAM_OLD_PATH"

  # Also remove the gnome extension that can start gnome terminal
  apt-get remove --assume-yes nautilus-extension-gnome-terminal
fi
