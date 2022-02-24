#! /usr/bin/env sh

# Relevant info:
# https://unix.stackexchange.com/questions/419422/wifi-disable-hotspot-login-screen
#
# Or you can do it manually like this:
# https://www.ubuntubuzz.com/2018/03/disable-hotspot-login-on-ubuntu-1710-and-1804.html

apt-get remove --assume-yes network-manager-config-connectivity-ubuntu
