#! /usr/bin/env sh

set -ex

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

PRINTER=$1
PAGE_SIZE="$(lower "$2")"
COLOR_MODEL=$3
DUPLEX=$4
# TODO:  to specify Landscape vs Portrait?

if [ "$PAGE_SIZE" != "-" ]
then
    # Verify it takes effect by running get_printer_options
    lpoptions -p "$PRINTER" -o PageSize="$PAGE_SIZE"

    # Alternate approach - untested
    #lpadmin -p "$PRINTER" -o media=$SIZE

    # Additionally globally set the paper size to that size as well
    paperconfig --paper "$PAGE_SIZE"
fi

if [ "$COLOR_MODEL" != "-" ]
then
    lpadmin -p "$PRINTER" -o ColorModel="$COLOR_MODEL"
fi

if [ "$DUPLEX" != "-" ]
then
    lpadmin -p "$PRINTER" -o Duplex="$DUPLEX"
fi
