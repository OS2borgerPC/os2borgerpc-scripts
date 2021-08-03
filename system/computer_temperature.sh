#!/bin/bash

# Install acpi
dpkg -l acpi > /dev/null 2>&1 
HAS_ACPI=$?

if [[ $HAS_ACPI == 1 ]]
then
    apt-get update
    apt-get install -y acpi
fi

# Aflæs temperaturen

acpi -t
