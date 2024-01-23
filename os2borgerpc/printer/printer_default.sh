#! /usr/bin/env sh

# Check required parameters
if [ $# -ne 1 ]
then
    echo "This script takes 1 required argument."
    exit 1
fi

lpadmin -d "$1" && lpstat -d
