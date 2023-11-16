#! /usr/bin/env sh

set -x

ACTIVATE="$1"
DIRECTORY_NAME_ON_DESKTOP="${2-scan}" # Set a default argument so rm --recursive below doesn't attempt to delete the desktop if no argument was passed

SCAN_DIRECTORY_SOURCE="/home/.skjult/Skrivebord/$DIRECTORY_NAME_ON_DESKTOP"
SCAN_DIRECTORY_DESTINATION=$(echo "$SCAN_DIRECTORY_SOURCE" | sed 's/.skjult/user/')
SAMBA_CONFIG=/etc/samba/smb.conf
# This share name can really be anything
SHARE_NAME="scan"
SAMBA_SERVICE="smbd"
OUR_USER="user"
OUR_SAMBA_USER="samba"

if [ "$ACTIVATE" != "True" ]; then
	apt-get purge --assume-yes samba samba-common-bin
	rm --recursive "$SCAN_DIRECTORY_SOURCE" "$SCAN_DIRECTORY_DESTINATION"
	userdel $OUR_SAMBA_USER
	groupdel $OUR_SAMBA_USER
	exit 0
fi

apt-get update --assume-yes
# Note: This installation also creates a group named "sambashare". Not currently using that for anything
apt-get install samba samba-common-bin --assume-yes

# Don't create home dir, add the user fully noninteractively, and don't allow login to the user
groupadd --system $OUR_SAMBA_USER
adduser --system --no-create-home --disabled-password --disabled-login --group --shell /bin/false $OUR_SAMBA_USER
# Do we need these?
#smbpasswd -a samba
#smbpasswd -e samba
# TODO: Shouldn't be necessary due to --disabled-password above.
#usermod smbusr -p borger1234

# Create the directory and user and group for the share
# shellcheck disable=SC2174  # --parents is just there to ignore errors if it already exists
mkdir --parents --mode 0777 "$SCAN_DIRECTORY_SOURCE"
# User and group will be overwritten and set to root:user if desktop_toggle_writable.sh has been run, therefore we give the dir 777 access so samba can access and write to it
chown $OUR_USER:$OUR_SAMBA_USER "$SCAN_DIRECTORY_SOURCE"

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
	# to anonymous connections
	   map to guest = bad user

	############ Misc ############

	# Maximum number of usershare. 0 means that usershare is disabled.
	usershare max shares = 0

	# Allow users who've been granted usershare privileges to create
	# public shares, not just authenticated ones
	usershare allow guests = no

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
		  force user = $OUR_SAMBA_USER
		  force group = $OUR_SAMBA_USER
		  create mask = 0664
		  force create mode = 0664
		  directory mask = 0775
		  force directory mode = 0775
		  browseable = yes
		  writeable = yes
		  guest ok = yes
	EOF
fi

# Now restart samba after the configuration changes. If it starts up successfully, the settings should be syntactically valid
systemctl restart $SAMBA_SERVICE
systemctl status $SAMBA_SERVICE
