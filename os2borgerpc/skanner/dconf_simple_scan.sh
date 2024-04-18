#! /usr/bin/env sh
#
# 
# SYNOPSIS
#    dconf_simple_scanner.sh page_size picture_dpi text_dpi
# 
# 
# DESCRIPTION
#    This script sets up the simple scanner settings 
#    
#
# IMPLEMENTATION
#    copyright       Copyright 2024, Magenta ApS
#    license         GNU General Public License

set -x

# Policy
POLICY_PATH="org/gnome/simple-scan"
POLICY="simple_scan_settings"

# A page is defined as height and width instead of A4 or A3 ect.
#Page height 0 = automatic
POLICY_1="paper-height"
POLICY_VALUE_1=0

#Page width, 0 = automatic 
POLICY_2="paper-width"
POLICY_VALUE_2=0


#dpi for pictures, default is 300
POLICY_3="photo-dpi"
POLICY_VALUE_3=300

#dpi for text, default is 150
POLICY_4="text-dpi"
POLICY_VALUE_4=150

# Setting the page size
case "$1" in
	"A3")
		POLICY_VALUE_1=4200
		POLICY_VALUE_2=2970
		;;
	"A4")
		POLICY_VALUE_1=2970
		POLICY_VALUE_2=2100
		;;
	"A5")
		POLICY_VALUE_1=2100
		POLICY_VALUE_2=1480
		;;
	"A6")
		POLICY_VALUE_1=1480
		POLICY_VALUE_2=1050
		;;
	"Auto")
		POLICY_VALUE_1=0
		POLICY_VALUE_2=0
		;;
	*)
		echo "Invalid option. Please choose between A3 to A6."
		;;
esac

# Setting the pictures dpi
if [ "$2" ]; then 
	if [ "$2" -gt 75 ] && [ "$2" -le 2400 ]; then
		POLICY_VALUE_3="$2"
	else
		echo "Invalid option. Please choose between 75 to 2400."
	fi
fi


# Setting the text dpi
if [ "$3" ]; then 
	if [ "$3" -gt 75 ] && [ "$3" -le 2400 ]; then
		POLICY_VALUE_4="$3"
	else
		echo "Invalid option. Please choose between 75 to 2400."
	fi
fi

	
# Policyfiles
POLICY_FILE="/etc/dconf/db/os2borgerpc.d/00-$POLICY"

mkdir --parents "$(dirname "$POLICY_FILE")"

# dconf does not, by default, require the use of a system database, so
# add one (called "os2borgerpc") to store our system-wide settings in
cat > "/etc/dconf/profile/user" <<- END
	user-db:user
	system-db:os2borgerpc
END

#Changeing the values
cat > "$POLICY_FILE" <<- END
	[$POLICY_PATH]
	$POLICY_1=$POLICY_VALUE_1
	$POLICY_2=$POLICY_VALUE_2
	$POLICY_3=$POLICY_VALUE_3
	$POLICY_4=$POLICY_VALUE_4
END

# "dconf update" will only act if the content of the keyfile folder has
# changed: individual files changing are of no consequence. Force an update
# by changing the folder's modification timestamp
touch "$(dirname "$POLICY_FILE")"

# Incorporate all of the text files we've just created into the system's dconf databases
dconf update
