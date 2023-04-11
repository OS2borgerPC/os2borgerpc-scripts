#!/bin/bash

# Reference: https://chromeenterprise.google/policies/#IncognitoModeAvailability

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

ACTIVATE=$1
INPUT_MODE=$2
POLICY="/etc/opt/chrome/policies/managed/os2borgerpc-enforce-incognito.json"

case $INPUT_MODE in
0)
    INCOGNITO_MODE=0
    ;;
1)
    INCOGNITO_MODE=1
    ;;
2)
    INCOGNITO_MODE=2
    ;;
*)
    echo "$INPUT_MODE IS NOT a valid option. Exiting ..."
    exit 1
    ;;
esac


if [ "$ACTIVATE" = "True" ]
then
    
    if [ ! -d "$(dirname "$POLICY")" ]
    then
        mkdir -p "$(dirname "$POLICY")"
    fi

    cat << EOF > "$POLICY"
{
    "IncognitoModeAvailability": $INCOGNITO_MODE
}

EOF

else
    rm $POLICY
fi