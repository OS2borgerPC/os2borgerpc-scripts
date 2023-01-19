#!/usr/bin/env bash
# This script will set up a VNC server to listen on display :0 and will
# set a password given in the first parameter.

VNC_PASSWORD=$1

apt install -y ssh x11vnc xinetd

cat << EOF > /etc/xinetd.d/x11vnc
service x11vncservice
{
       port            = 5900
       type            = UNLISTED
       socket_type     = stream
       protocol        = tcp
       wait            = no
       user            = root
       server          = /usr/bin/x11vnc
       server_args     = -inetd -o /var/log/x11vnc.log -noxdamage -display :0 -auth /home/chrome/.Xauthority -passwdfile /etc/os2borgerpc/vncpasswd
       disable         = no
}
EOF

cat << EOF > /etc/os2borgerpc/vncpasswd
$VNC_PASSWORD
EOF

service xinetd restart
