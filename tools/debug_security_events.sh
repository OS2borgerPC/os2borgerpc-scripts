#! /usr/bin/env sh

# Feel free to expand with other useful ways to debug security events!

help() {
  printf '%s\n' "This script helps debug security events." \
                "Available options:" \
                "  No arguments: Runs everything below" \
                "  print-authlog: Prints the 500 last lines of auth.log" \
                "  print-syslog: Prints the 500 last lines of syslog" \
                "  print-sudo-entries: Prints all sudo entries in auth.log"
  exit
}

print_authlog() {
    printf "\n\n%s\n\n" "PRINTING THE 500 LAST LINES OF AUTH.LOG"
    tail -n 500 /var/log/auth.log
}

print_syslog() {
    printf "\n\n%s\n\n" "PRINTING THE 500 LAST LINES OF SYSLOG"
    tail -n 500 /var/log/syslog
}

print_sudo_entries() {
    printf "\n\n%s\n\n" "PRINTING THE 500 LAST SUDO LINES IN AUTH.LOG"
    grep 'sudo' /var/log/auth.log | tail -n 500
}

# Runs everything
run_all() {
    print_authlog
    print_syslog
    print_sudo_entries
}

if [ $# -lt 1 ]; then
  run_all
else
  COMMAND=$1

  if [ "$COMMAND" = "print-authlog" ]; then
    print_authlog
  elif [ "$COMMAND" = "print-syslog" ]; then
    print_syslog
  elif [ "$COMMAND" = "print-sudo-entries" ]; then
    print_sudo_entries
  else
    help
  fi

fi
