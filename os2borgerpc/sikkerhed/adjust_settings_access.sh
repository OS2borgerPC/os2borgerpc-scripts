#!/usr/bin/env bash

set -ex

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

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
    dpkg-divert --remove --no-rename /usr/bin/gnome-control-center
    # dpkg-divert can --rename it itself, but the problem with doing that is that in some images
    # dpkg-divert is not used, it was simply moved/copied, so that won't restore it, leaving you
    # with no gnome-control-center
    mv /usr/bin/gnome-control-center.real /usr/bin/gnome-control-center
  fi
else # Remove access to settings

  if [ ! -f "/usr/bin/gnome-control-center.real" ]; then
    dpkg-divert --rename --divert  /usr/bin/gnome-control-center.real --add /usr/bin/gnome-control-center
    dpkg-statoverride --update --add superuser root 770 /usr/bin/gnome-control-center.real
  fi

  cat << EOF > /usr/bin/gnome-control-center
#!/bin/bash

USER=\$(id -un)

# Set the info text based on the chosen language
if echo \$LANG | grep sv; then
  INFO="Systeminställningarna är inte tillgängliga för allmänheten.\n\nKontakta personalen om det uppstår problem."
elif echo \$LANG | grep en; then
  INFO="The settings are not accessible to the public.\n\nContact the staff if there are issues."
else
  INFO="Systemindstillingerne er ikke tilgængelige for publikum.\n\nKontakt personalet, hvis der er problemer."
fi

if [ \$USER == "user" ]; then
  zenity --info --text="\$INFO"
else
  /usr/bin/gnome-control-center.real "\$@"
fi
EOF

  chmod +x /usr/bin/gnome-control-center

fi
