#! /usr/bin/env sh

SMB_LOG_1="/var/log/samba/log.smbd"
SMB_LOG_2="/var/log/samba/log.nmbd" # For samba over netbios?

echo "Check samba status + version info:"
smbstatus

echo "Test configuration file correctness:"
testparm --suppress-prompt

echo "Listing processes listening on TCP, which should include smbd:"
lsof -nP -iTCP -sTCP:LISTEN

echo "Listing processes using UDP ports, which should include nmbd (netbios)"
lsof -nP -iUDP

echo "What's in the Samba log dir?:"
ls -l "$(dirname $SMB_LOG_1)"

echo "Anything in the main log file?:"
[ -f $SMB_LOG_1 ] && tail --lines 200 $SMB_LOG_1

echo "Anything in the samba netbios log file?:"
[ -f $SMB_LOG_2 ] && tail --lines 200 $SMB_LOG_2
