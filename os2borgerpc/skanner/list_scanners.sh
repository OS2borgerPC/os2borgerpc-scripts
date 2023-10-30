#!/bin/bash

# Lists available scanners and
# Author: heini@magenta.dk

set -x
echo "Running scanimage. Use the output of this command for the default scanner script:"
scanimage -L

echo "See if airscan sees any Apple Airscan or Microsoft WSD supporting scanners:"
airscan-discover
