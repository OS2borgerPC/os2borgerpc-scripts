#!/bin/bash

set -x

CERT_FILE_PATH=$1

CERT_FILE_NAME=$(basename "$CERT_FILE_PATH")
ICA_KEYSTORE_PATH="/opt/Citrix/ICAClient/keystore/cacerts"
cp "$CERT_FILE_PATH" $ICA_KEYSTORE_PATH/
chmod 644 $ICA_KEYSTORE_PATH/"$CERT_FILE_NAME"
/opt/Citrix/ICAClient/util/ctx_rehash