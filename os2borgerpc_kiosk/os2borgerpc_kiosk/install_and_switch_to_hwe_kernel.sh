#! /usr/bin/env sh

export DEBIAN_FRONTEND=noninteractive

ACTIVATE=$1

PKG="linux-generic-hwe-20.04"

if [ "$ACTIVATE" = 'True' ]; then
  apt-get install --assume-yes $PKG
else
  apt-get remove --assume-yes $PKG
fi
