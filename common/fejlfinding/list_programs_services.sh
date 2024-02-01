#! /usr/bin/env sh

printf "\n\n%s\n\n" "===== LIST INSTALLED PACKAGES (PROGRAMS): $0 ====="
#apt list --installed
dpkg -l | grep --invert-match "^rc"  # Don't show packages that WERE installed

printf "\n\n%s\n\n" "===== LIST ALL SERVICES: $0 ====="
systemctl list-units

printf "\n\n%s\n\n" "===== LIST PROGRAMS IN /usr/share/applications: $0 ====="
ls -l /usr/share/applications
