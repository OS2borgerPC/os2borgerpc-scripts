#! /usr/bin/env sh

printf "\n\n%s\n\n" "===== LIST INSTALLED PROGRAMS: $0 ====="
#apt list --installed
dpkg -l

printf "\n\n%s\n\n" "===== LIST ALL SERVICES: $0 ====="
systemctl list-units
