#! /usr/bin/env sh

set -x

BASE_URL="https://os2borgerpc-media.magenta.dk/parameter_uploads/"
EXAMPLE_PARAMETER="86538woqsoed1tky1yndnkdxlz7srb7a/1415012771076_wps_1_A_giant_AT_AT_Walker_towe.jpg"
URL=${BASE_URL}${EXAMPLE_PARAMETER}

echo "Try to download a random file from the server our parameters are served from:"
wget $URL --output-document /tmp/random1.jpg
echo "Try without verifying certificates"
wget $URL --no-check-certificate --output-document /tmp/random2.jpg

echo "Check that the files are now on disk"
file /tmp/random1.jpg /tmp/random2.jpg
# cat /tmp/random2.jpg

echo "Cleanup afterwards"
rm --force /tmp/random1.jpg /tmp/random2.jpg
