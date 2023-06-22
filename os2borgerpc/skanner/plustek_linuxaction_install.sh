#!/usr/bin/env bash

set -x

FILE=$1

apt-get --assume-yes update

dpkg -i "$FILE"

apt-get --assume-yes --fix-broken install
