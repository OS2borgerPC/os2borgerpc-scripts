#!/bin/bash

# Updates Sane scanner drivers. http://sane-project.org/
# Author: shg@magenta.dk

add-apt-repository -y ppa:sane-project/sane-release
apt-get update
apt install -y libsane
