#! /usr/bin/env sh

DOMAIN=$1

echo "Print a list of processes by name running on the computer"
ps -eo comm

echo "Verify connection to the domain:"
ping -c 3 "$DOMAIN"

echo "Verify HTTPS connection working to the domain"
curl -I "https://$DOMAIN"
