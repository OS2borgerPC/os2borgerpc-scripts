#! /usr/bin/env sh

# Adds, or Removes TeamViewer

ACTIVATE=$1
FILE=$2

if [ "$ACTIVATE" = 'True' ]; then
  echo "##### Attempting to install TeamViewer #####"
  apt-get update --assume-yes
  apt-get install --fix-broken "$FILE" --assume-yes
else
  echo "##### Removing TeamViewer #####"
  apt-get purge teamviewer --assume-yes
fi

rm "$FILE"
apt autoremove --assume-yes
