#!/usr/bin/env sh

HOSTS=/etc/hosts

sed --in-place /127.0.1.1/d $HOSTS
sed --in-place "2i 127.0.1.1	$(hostname)" $HOSTS
