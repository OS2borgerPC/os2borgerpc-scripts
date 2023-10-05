#! /usr/bin/env bash

set -x

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

POLICY="/etc/opt/chrome/policies/managed/os2borgerpc-pdf.json"

ACTIVATE=$1

if [ "$ACTIVATE" = "False" ]; then
    rm -f "$POLICY"
else
    if [ ! -d "$(dirname "$POLICY")" ]; then
        mkdir -p "$(dirname "$POLICY")"
    fi

    cat > "$POLICY" <<END
{
    "AlwaysOpenPdfExternally": true,
    "AutoOpenFileTypes": ["pdf"]
}
END
fi
