#! /usr/bin/env sh
#
# SYNOPSIS
#    dconf_simple_scanner.sh page_size picture_dpi text_dpi
#
# DESCRIPTION
#    This script sets up the simple scanner settings
#
# IMPLEMENTATION
#    copyright       Copyright 2024, Magenta ApS
#    license         GNU General Public License

# NOTE: This script does not set a dconf lock as people are free to temporarily change the settings from the defaults.

set -x

POLICY_PATH="org/gnome/simple-scan"
POLICY="simple_scan_settings"
POLICY_FILE="/etc/dconf/db/os2borgerpc.d/00-$POLICY"

PAPER_SIZE_NAME=$1

# DPI for photos default is 300
# Value must be 75, 150, 200, 300, 600, 1200 or 2400.
PHOTO_DPI=${2:-300}

# DPI for text default is 150
# Value must be 75, 150, 200, 300, 600, 1200 or 2400.
TEXT_DPI=${3:-150}

# A page is defined as height and width instead of A4 or A3 ect.
# Convert paper size names to width and height
# Page height 0 = automatic
# Page width 0 = automatic
case "$PAPER_SIZE_NAME" in
	"A3")
		PAPER_HEIGHT=4200
		PAPER_WIDTH=2970
		;;
	"A4")
		PAPER_HEIGHT=2970
		PAPER_WIDTH=2100
		;;
	"A5")
		PAPER_HEIGHT=2100
		PAPER_WIDTH=1480
		;;
	"A6")
		PAPER_HEIGHT=1480
		PAPER_WIDTH=1050
		;;
	"Auto")
		PAPER_HEIGHT=0
		PAPER_WIDTH=0
		;;
	*)
		echo "Invalid option. Please choose A3-A6 or Auto."
		exit 1
		;;
esac

mkdir --parents "$(dirname "$POLICY_FILE")"

# dconf does not, by default, require the use of a system database, so
# add one (called "os2borgerpc") to store our system-wide settings in
cat > "/etc/dconf/profile/user" <<- END
	user-db:user
	system-db:os2borgerpc
END

# Setting the policies
cat > "$POLICY_FILE" <<- END
	[$POLICY_PATH]
	paper-height=$PAPER_HEIGHT
	paper-width=$PAPER_WIDTH
	photo-dpi=$PHOTO_DPI
	text-dpi=$TEXT_DPI
END

# "dconf update" will only act if the content of the keyfile folder has
# changed: individual files changing are of no consequence. Force an update
# by changing the folder's modification timestamp
touch "$(dirname "$POLICY_FILE")"

# Incorporate all of the text files we've just created into the system's dconf databases
dconf update
