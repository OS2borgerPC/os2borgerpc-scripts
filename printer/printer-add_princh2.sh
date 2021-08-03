#!/usr/bin/env bash


# Replace space with underscore
printer_name=$(echo $1 | tr ' ' '_')
printer_id=$2
printer_descr=$3

if [ "$(which princh)" ]
then
   lpadmin -p $printer_name -v princh:$printer_id -D "$printer_descr" -E -P /usr/share/ppd/princh/princh.ppd
   exit 0
else
   echo "Princh er ikke installeret"
   exit 1
fi
