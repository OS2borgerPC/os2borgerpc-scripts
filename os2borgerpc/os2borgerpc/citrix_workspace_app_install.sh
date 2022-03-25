#!/bin/bash

set -x

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

ACTIVATE="$(lower "$1")"

if [ "$ACTIVATE" != 'false' ] && [ "$ACTIVATE" != 'falsk' ] &&
   [ "$ACTIVATE" != 'no' ] && [ "$ACTIVATE" != 'nej' ]; then

    DEB_FILE=$2

    SHADOW_DIR=/home/.skjult
    ICA_DIR=$SHADOW_DIR"/.ICAClient"
    MIMEAPPSLIST_DIR=$SHADOW_DIR"/.local/share/applications"

    if dpkg -l "icaclient" > /dev/null
    then
        # Remove already installed icaclient and conf.
        apt-get purge icaclient -y
        rm -R $ICA_DIR
        rm $MIMEAPPSLIST_DIR"/mimeapps.list"
        rm $SHADOW_DIR"/Skrivebord/wfica.desktop"
        rm /opt/AppProtectionremove.sh
    fi

    if [ -d "$ICA_DIR" ]; then
        # If icaclient isn't installed, but leftover-conf is detected - remove it.
        rm -r "$ICA_DIR"
    fi

    # Installing icaclient.
    export DEBIAN_FRONTEND="noninteractive"
    debconf-set-selections <<< "icaclient app_protection/install_app_protection select yes"
    debconf-show icaclient 2>&1
    apt-get -o DPkg::Lock::Timeout=900 install -f "$DEB_FILE" --allow-unauthenticated -y
    rm "$DEB_FILE"

    apt-get update -y
    apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --with-new-pkgs upgrade -y
    apt autoremove -y

    # AcceptEULA agreement
    mkdir $ICA_DIR && touch "$ICA_DIR/.eula_accepted"

    # Remove user 'citrixlog' from login screen
    usermod -s /usr/sbin/nologin citrixlog

    # https://docs.citrix.com/en-us/citrix-workspace-app-for-linux/get-started.html
    xdg-mime query default application/x-ica
    export ICAROOT=/opt/Citrix/ICAClient
    xdg-icon-resource install --size 64 $ICAROOT"/icons/000_Receiver_64.png" "Citrix Workspace app-"
    xdg-mime default wfica.desktop application/x-ica
    xdg-mime default new_store.desktop application/vnd.citrix.receiver.configure

    mkdir -p $MIMEAPPSLIST_DIR
    touch $MIMEAPPSLIST_DIR"/mimeapps.list"
    if ! grep -q -- "x-ica wfica" $MIMEAPPSLIST_DIR"/mimeapps.list"; then
        echo "application/x-ica=wfica.desktop;" >> $MIMEAPPSLIST_DIR"/mimeapps.list"
        echo "application/vnd.citrix.receiver.configure=new_store.desktop;" >> $MIMEAPPSLIST_DIR"/mimeapps.list"
    fi

else # [ "$ACTIVATE" != 'false' ] ...

    sudo apt purge "icaclient" --assume-yes

fi


