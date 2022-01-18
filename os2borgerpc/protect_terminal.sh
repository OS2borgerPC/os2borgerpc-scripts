#!/usr/bin/env bash

set -ex

if [ !  -f "/usr/bin/gnome-terminal.real" ]
then
    dpkg-divert --rename --divert  /usr/bin/gnome-terminal.real --add /usr/bin/gnome-terminal
    dpkg-statoverride --update --add superuser root 770 /usr/bin/gnome-terminal.real
fi


cat << EOF > /usr/bin/gnome-terminal
#!/bin/bash

USER=\$(id -un)

if [ \$USER == "user" ]; then
  zenity --info --text="Terminalen er ikke tilgængelig for publikum."
else
  /usr/bin/gnome-terminal.real
fi

EOF

chmod +x /usr/bin/gnome-terminal

apt-get remove --assume-yes nautilus-extension-gnome-terminal
