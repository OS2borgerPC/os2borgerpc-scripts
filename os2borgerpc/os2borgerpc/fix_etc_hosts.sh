#!/usr/bin/env sh

HOSTS=/etc/hosts

# Don't add 127.0.1.1 if it isn't already there
if grep --quiet 127.0.1.1 $HOSTS; then
  sed --in-place /127.0.1.1/d $HOSTS
  sed --in-place "2i 127.0.1.1	$(hostname)" $HOSTS
fi
