#! /usr/bin/env sh

SRC=raw_scripts/cicero_install_pam_raw.sh
DST=cicero_install_pam.sh

cp $SRC $DST

# shellcheck disable=SC2016 # We don't want the variable expanded
sed --in-place '/cat << EOF > $CICERO_INTERFACE_PYTHON3/r raw_scripts/cicero_interface.py' $DST

# shellcheck disable=SC2016 # We don't want the variable expanded
sed --in-place '/cat << EOF > $PAM_PYTHON_MODULE/r raw_scripts/pam_module.py' $DST
