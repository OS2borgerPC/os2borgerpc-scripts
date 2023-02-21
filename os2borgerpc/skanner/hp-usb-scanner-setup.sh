#! /usr/bin/env sh

export DEBIAN_FRONTEND=noninteractive

# Install the dependencies to run the interactive script noninteractively
apt-get update -y
apt-get install -yf expect

SCRIPT_PATH=/tmp/hp-plugin-setup.sh

cat << EOF > $SCRIPT_PATH
#!/usr/bin/expect -f
 
set timeout -1
 
spawn hp-plugin -i
 
expect "Do you wish to download and install the plug-in? (y=yes*, no=no, q=quit) ? \r"
 
send -- "\r"
 
expect "Enter option (d=download*, p=specify path, q=quit) ? \r"
 
send -- "\r"
 
expect "Do you accept the license terms for the plug-in (y=yes*, n=no, q=quit) ? \r"
 
send -- ""
 
expect eof
EOF

# Fix permissions
chmod +x $SCRIPT_PATH

# Run it
/tmp/hp-plugin-setup.sh
