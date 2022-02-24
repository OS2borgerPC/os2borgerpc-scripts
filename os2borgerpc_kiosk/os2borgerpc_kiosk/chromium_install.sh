#!/bin/bash
# Minimal install of X and Chromium and connectivity.

set -ex

export DEBIAN_FRONTEND=noninteractive

apt-get update -y

apt-get install -y xinit xserver-xorg-core x11-xserver-utils --no-install-recommends --no-install-suggests
apt-get install -y xdg-utils xserver-xorg-video-qxl xserver-xorg-video-intel xserver-xorg-video-all xserver-xorg-input-all libleveldb-dev
# Hvorfor > /dev/null?:
# Chromium-install udskriver "scroll"-kommentarer for at have én linje, der bladrer forbi
# i stedet for at fylde skærmen, og dette giver pt. ugyldig XML, når svaret sendes tilbage til serveren.
apt-get install -y chromium-browser > /dev/null
