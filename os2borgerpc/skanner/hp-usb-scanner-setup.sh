#! /usr/bin/env sh

export DEBIAN_FRONTEND=noninteractive

# Install the dependencies to run the interactive script noninteractively
apt-get update --assume-yes
apt-get install --assume-yes --fix-broken expect

SCRIPT_PATH=/tmp/hp-plugin-setup.sh

cat << EOF > $SCRIPT_PATH
#!/usr/bin/expect -f

set timeout -1

spawn hp-plugin -i

expect "Enter option (d=download*, p=specify path, q=quit) ? "

send -- "\r"

expect "Do you accept the license terms for the plug-in (y=yes*, n=no, q=quit) ? "

send -- "\r"

expect eof
EOF

# Fix permissions
chmod +x $SCRIPT_PATH

# Run it
$SCRIPT_PATH
