#!/usr/bin/env bash
# This script will set up a VNC server to listen on display :0 and will
# set a password given in the first parameter.

VNC_PASSWORD=$1

XINETD_FILE=/etc/xinetd.d/x11vnc

if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en regulær OS2borgerPC-maskine."
  exit 1
fi

apt install -y ssh x11vnc xinetd

cat << EOF > $XINETD_FILE
service x11vncservice
{
       port            = 5900
       type            = UNLISTED
       socket_type     = stream
       protocol        = tcp
       wait            = no
       user            = chrome
       server          = /usr/bin/x11vnc
       server_args     = -inetd -o /home/chrome/x11vnc.log -noxdamage -display :0 -auth /home/chrome/.Xauthority -passwd $VNC_PASSWORD
       disable         = no
}
EOF

chmod 640 $XINETD_FILE

rm --force /etc/os2borgerpc/vncpasswd /var/log/x11vnc.log

service xinetd restart
