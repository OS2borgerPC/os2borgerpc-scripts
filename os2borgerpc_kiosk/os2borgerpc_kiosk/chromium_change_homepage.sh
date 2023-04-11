#! /usr/bin/env sh

NEW_URL="$1"

if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en regulær OS2borgerPC-maskine."
  exit 1
fi

CHROMIUM_SCRIPT='/usr/share/os2borgerpc/bin/start_chromium.sh'
sed --in-place --regexp-extended "s%(IURL=\").*%\1$NEW_URL\"%" $CHROMIUM_SCRIPT
