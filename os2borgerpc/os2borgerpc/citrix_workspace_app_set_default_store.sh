#!/bin/bash

set -x

STORE_DIR=/home/.skjult/.ICAClient/cache/Stores

STORE_NAME=$1
DEFAULT_STORE=$2

if [ -z "$DEFAULT_STORE" ] && [ -z "$STORE_NAME" ]; then
    echo "WARNING: Missing argument(s). Not able to set default citrix store."
    exit 1
fi

if [ ! -d "$STORE_DIR" ]; then
    mkdir -p "$STORE_DIR"
fi

if [ ! -f "$STORE_DIR/StoreCache.ctx" ]; then
    touch "$STORE_DIR/StoreCache.ctx"
fi

cat << EOF > "$STORE_DIR/StoreCache.ctx"
<StoreCache>
    <DefaultStore>$DEFAULT_STORE</DefaultStore>
    <ReconnectOnLogon>False</ReconnectOnLogon>
    <ReconnectOnLaunchOrRefresh>False</ReconnectOnLaunchOrRefresh>
    <SharedUserMode>False</SharedUserMode>
    <FullscreenMode>0</FullscreenMode>
    <SelfSelection>True</SelfSelection>
    <SessionWindowedMode>False</SessionWindowedMode>
    <VisibleStores>
        <Store name="$STORE_NAME" type="DS" gatewaystore="" internalbeacon="" externalbeacon="" storeservice="OnPremStore">$DEFAULT_STORE</Store>
    </VisibleStores>
</StoreCache>

EOF



