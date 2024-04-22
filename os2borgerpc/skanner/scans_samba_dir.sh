#! /usr/bin/env sh

# Test it like this, preferably from another machine:
# smbclient '\\<IP_ADDRESS_HERE>\<SHARE_NAME>' -U <USER>
# ...so more specifically:
# smbclient '\\IP_ADDRESS_HERE\scan' -U samba

set -x

ACTIVATE="$1"
DIRECTORY_NAME_ON_DESKTOP="${2-scan}" # Set a default argument so rm --recursive below doesn't attempt to delete the desktop if no argument was passed
SAMBA_USER_PASSWORD="$3"
AUTH_DISALLOW_NTLM_V1="$4"
ALLOW_NETBIOS="$5"

SCAN_DIRECTORY_SOURCE="/home/.skjult/Skrivebord/$DIRECTORY_NAME_ON_DESKTOP"
SCAN_DIRECTORY_DESTINATION=$(echo "$SCAN_DIRECTORY_SOURCE" | sed 's/.skjult/user/')
SAMBA_CONFIG=/etc/samba/smb.conf
# This share name can really be anything
SHARE_NAME="scan"
SAMBA_SERVICE="smbd"
OUR_USER="user"
# This name can be anything
SAMBA_USER="samba"

if [ "$ACTIVATE" != "True" ]; then
	apt-get purge --assume-yes samba samba-common-bin
	rm --recursive "$SCAN_DIRECTORY_SOURCE"
	userdel $SAMBA_USER
	groupdel $SAMBA_USER
	exit 0
fi

# A provided password is required when activating this script
[ -z "$SAMBA_USER_PASSWORD" ] && echo "Error: You need to choose a password for the samba user, which is then used to access the share. Exiting." && exit 1

if [ "$AUTH_DISALLOW_NTLM_V1" = "False" ]; then
  AUTH_NTLM_V1_TEXT="
# Better support for old devices by allowing older auth protocols
# Newer versions default to: ntlm auth = ntlmv2-only
# https://wiki.archlinux.org/title/Samba#Enable_access_for_old_clients/devices
   server min protocol = NT1
   ntlm auth = yes"
fi

# Defaults are:
#   disable netbios = no
#   smb ports 445 139
if [ "$ALLOW_NETBIOS" = "False" ]; then
  NETBIOS_TEXT="
# Disabling netbios + stop listening on its TCP port
   disable netbios = yes
   smb ports = 445"
fi

apt-get update --assume-yes
# Note: This installation also creates a group named "sambashare". Not currently using that for anything
apt-get install samba samba-common-bin --assume-yes

# Don't create home dir, add the user fully noninteractively, and don't allow login to the user
groupadd --system $SAMBA_USER
adduser --system --no-create-home --disabled-password --disabled-login --group --shell /bin/false $SAMBA_USER
# Set the provided password for the samba user
#echo "$SAMBA_USER:$SAMBA_USER_PASSWORD" | /usr/sbin/chpasswd

# Create the user in samba and set the password for it:
printf "%s\n%s" "$SAMBA_USER_PASSWORD" "$SAMBA_USER_PASSWORD" | smbpasswd -a -s samba

# Enable the user
smbpasswd -e $SAMBA_USER

# Create the directory and user and group for the share
# shellcheck disable=SC2174  # --parents is just there to ignore errors if it already exists
mkdir --parents --mode 0777 "$SCAN_DIRECTORY_SOURCE"
# User and group will be overwritten and set to root:user if desktop_toggle_writable.sh has been run, therefore we give the dir 777 access so samba can access and write to it
chown $OUR_USER:$SAMBA_USER "$SCAN_DIRECTORY_SOURCE"

# This is most of the default config, with inactive sections, and print sections removed and only a few changes made (user shares are disabled)
# This was mostly done to disable the default printer sharing
cat <<- EOF > $SAMBA_CONFIG
	#======================= Global Settings =======================

	[global]

	## Browsing/Identification ###

	# Change this to the workgroup/NT-domain name your Samba server will part of
	   workgroup = WORKGROUP

	# server string is the equivalent of the NT Description field
	   server string = %h server (Samba, Ubuntu)

	#### Debugging/Accounting ####

	# This tells Samba to use a separate log file for each machine
	# that connects
	   log file = /var/log/samba/log.%m

	# Cap the size of the individual log files (in KiB).
	   max log size = 1000

	# We want Samba to only log to /var/log/samba/log.{smbd,nmbd}.
	# Append syslog@1 if you want important messages to be sent to syslog too.
	   logging = file

	# Do something sensible when Samba crashes: mail the admin a backtrace
	   panic action = /usr/share/samba/panic-action %d

	### Don't share printers ###
	# https://wiki.archlinux.org/title/Samba#Disable_printer_sharing
	   load printers = no
	   printing = bsd
	   printcap name = /dev/null
	   disable spoolss = yes
	   show add printer wizard = no


	####### Authentication #######

	# Server role. Defines in which mode Samba will operate. Possible
	# values are "standalone server", "member server", "classic primary
	# domain controller", "classic backup domain controller", "active
	# directory domain controller".
	#
	# Most people will want "standalone server" or "member server".
	# Running as "active directory domain controller" will require first
	# running "samba-tool domain provision" to wipe databases and create a
	# new domain.
	   server role = standalone server

	   obey pam restrictions = yes

	# This boolean parameter controls whether Samba attempts to sync the Unix
	# password with the SMB password when the encrypted SMB password in the
	# passdb is changed.
	   unix password sync = yes

	# For Unix password sync to work on a Debian GNU/Linux system, the following
	# parameters must be set (thanks to Ian Kahan <<kahan@informatik.tu-muenchen.de> for
	# sending the correct chat script for the passwd program in Debian Sarge).
	   passwd program = /usr/bin/passwd %u
	   passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .

	# This boolean controls whether PAM will be used for password changes
	# when requested by an SMB client instead of the program listed in
	# 'passwd program'. The default is 'no'.
	   pam password change = yes

	# This option controls how unsuccessful authentication attempts are mapped
	# to anonymous connections # never is the default.
	   map to guest = never

	$AUTH_NTLM_V1_TEXT

	############ Misc ############

	# Maximum number of usershare. 0 means that usershare is disabled.
	usershare max shares = 0

	# Allow users who've been granted usershare privileges to create
	# public shares, not just authenticated ones
	usershare allow guests = no

	$NETBIOS_TEXT

	#======================= Share Definitions =======================
	#
EOF

# Modify some global configuration for all "user shares"
# User shares are shares users can create themselves, without needing root permissions
#sed --in-place --expression '/\[global\]/a\usershare max shares = 100' \
#    --expression '/\[global\]/a\usershare allow guests = yes' \
#    --expression '/\[global\]/a\usershare owner only = false' $SAMBA_CONFIG


# Create the share named $SHARE_NAME. Settings:
# - path: The path to the share on the file system
# - browseable = yes: "this share is seen in the list of available shares in a net view and in the browse list"
# - create mask and force create mode: Ensure new files created in the dir has those permissions
# - directory mask and force directory mode does the same for directories created within the share
# - force user and force group: Forcing the share to be shared as this user/group
# - writeable = yes: allow write access
# - guest ok = no: don't allow connecting to the service without a password
if ! grep "Scanned documents" $SAMBA_CONFIG; then # Idempotency check
	cat <<- EOF >> $SAMBA_CONFIG
		[$SHARE_NAME]
		  comment = Scanned documents
		  path = $SCAN_DIRECTORY_DESTINATION
		  force user = $SAMBA_USER
		  force group = $SAMBA_USER
		  create mask = 0664
		  force create mode = 0664
		  directory mask = 0775
		  force directory mode = 0775
		  browseable = yes
		  writeable = yes
		  guest ok = no
	EOF
fi

# Now restart samba after the configuration changes. If it starts up successfully, the settings should be at least syntactically valid.
systemctl restart $SAMBA_SERVICE
systemctl status $SAMBA_SERVICE

# Check samba status + version info
smbstatus

# Test configuration file correctness
testparm --suppress-prompt

echo "Listing processes listening on TCP, matching smbd"
lsof -nP -iTCP -sTCP:LISTEN | grep smbd

echo "Listing processes using UDP, matching nmbd (netbios)"
lsof -nP -iUDP | grep nmbd
