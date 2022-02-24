#!/usr/bin/env sh

# Takes effect after logout

OUR_USER=.skjult
DIR=/home/$OUR_USER/.local/share/applications

mkdir --parents $DIR
cp /usr/share/applications/apport-gtk.desktop $DIR/
sed -i 's@Exec.*@Exec=/bin/false@' $DIR/apport-gtk.desktop
