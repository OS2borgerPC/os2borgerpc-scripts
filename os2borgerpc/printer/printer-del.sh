#! /usr/bin/env sh

# Delete printer

PRINTER_NAME=$1

# Test if printer is deleted
if lpadmin -x "$PRINTER_NAME"; then
    printf '%s\n' "Printeren $PRINTER_NAME er blevet slettet."
else
    STATUS=$?
    printf '%s\n' "Fejl: Printeren $PRINTER_NAME blev ikke slettet (Fejlkode: $STATUS)" \
                  "Enten eksisterer ingen printer ved det navn, eller også fejlede sletningen."
    exit $STATUS
fi
