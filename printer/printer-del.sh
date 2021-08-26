#!/usr/bin/env bash

# Delete printer
lpadmin -x "$1"

# Test if printer is deleted
if ! (lpc status | grep --quiet --null-data "$1")
then
    echo "$1 er blevet slettet"
else
    echo "Der er sket en fejl og $1 blev ikke slettet"
    exit 1
fi
