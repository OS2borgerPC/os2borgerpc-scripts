#!/usr/bin/env bash

set -ex

ACTIVATE=$1

# Restore access to settings
if [ "$ACTIVATE" = 'True' ]; then

  # Making sure we're not removing the actual
  # gnome-control-center if run with the wrong argument or multiple times
  if grep --quiet 'zenity' /usr/bin/gnome-control-center; then
    # Remove the permissions override and manually reset permissions to defaults
     # Suppress error to prevent set -e exiting in case the override no longer exists
    dpkg-statoverride --remove /usr/bin/gnome-control-center.real || true
    chown root:root /usr/bin/gnome-control-center.real
    chmod 755 /usr/bin/gnome-control-center.real
    # Remove the shell script that prints the error message
    rm /usr/bin/gnome-control-center
    # Remove location override and restore gnome-control-center.real back to gnome-control-center
    dpkg-divert --rename --remove /usr/bin/gnome-control-center
  fi
else # Remove access to settings

  if [ ! -f "/usr/bin/gnome-control-center.real" ]; then
    dpkg-divert --rename --divert  /usr/bin/gnome-control-center.real --add /usr/bin/gnome-control-center
    dpkg-statoverride --update --add superuser root 770 /usr/bin/gnome-control-center.real
  fi

  cat << EOF > /usr/bin/gnome-control-center
#!/bin/bash

USER=\$(id -un)

if [ \$USER == "user" ]; then
  zenity --info --text="Systemindstillingerne er ikke tilgængelige for publikum.\n\n Kontakt personalet, hvis der er problemer."
else
  /usr/bin/gnome-control-center.real
fi
EOF

  chmod +x /usr/bin/gnome-control-center

fi
