#! /usr/bin/env sh

set -ex

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
URL="https://packages.princh.com/linux/debian/amd64/PrinchCloudPrinter/production/current"

# This will return "" if not installed, which is also fine as that means it'll be installed
PRINCH_VERSION_AVAILABLE="$(curl --head --silent $URL | grep version | cut --delimiter ' ' --fields 2 | cut --delimiter '.' --fields 1,2,3)"
PRINCH_VERSION_INSTALLED="$(dpkg --status princh-cloud-printer | grep Version | cut --delimiter ' ' --fields 2)"

[ -z "$PRINCH_VERSION_AVAILABLE" ] && printf "%s\n" "Failed to obtain the current Princh version from Princh's servers" && exit 1

# Remove the older versions of Princh, ignore if not existing
apt-get remove --assume-yes princh || true
# Remove their old PPA
add-apt-repository --remove --yes ppa:princh/stable || true

# No princh-cloud-printer binary in path, so checking for princh-setup
if  [ "$PRINCH_VERSION_AVAILABLE" != "$PRINCH_VERSION_INSTALLED" ]; then

   FILE="princh.deb"
   # Change the file name of the download file to be something
   # predictable for the command to install it below
   curl $URL --output $FILE
   dpkg --install $FILE

else
    printf '%s\n' "Princh is already installed and in the most recent version."
fi

# Create Princh autostart
princh_autostart_dir=/home/.skjult/.config/autostart

mkdir --parents $princh_autostart_dir

# This will fail if the symlink already exists, but the exit status is still 0 so no problem
ln -sf /usr/share/applications/com-princh-print-daemon.desktop $princh_autostart_dir
