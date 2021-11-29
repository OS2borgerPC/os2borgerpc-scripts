#! /usr/bin/env python3

import sys
from subprocess import check_output
import os2borgerpc.client.admin_client as admin_client
import socket


def cicero_validate(cicero_user, cicero_pass):

    host_address = (
        check_output(["get_os2borgerpc_config", "admin_url"]).decode().replace("\n", "")
    )
    # Example URL:
    # host_address = "https://os2borgerpc-admin.magenta.dk/admin-xml/"

    # For local testing with VirtualBox
    # host_address = "http://10.0.2.2:9999/admin-xml/"

    # Obtain the site and convert from bytes to regular string
    # and remove the trailing newline
    site = check_output(["get_os2borgerpc_config", "site"]).decode().replace("\n", "")

    # Values it can return - see cicero_login here:
    # https://github.com/OS2borgerPC/admin-site/blob/master/admin_site/system/rpc.py
    # For reference:
    #   r < 0: User is quarantined and may login in -r minutes
    #   r = 0: Unable to authenticate.
    #   r > 0: The user is allowed r minutes of login time.
    admin = admin_client.OS2borgerPCAdmin(host_address + "/admin-xml/")
    try:
        time = admin.citizen_login(cicero_user, cicero_pass, site)
    except (socket.gaierror, TimeoutError):
        time = ""

    # Time is received in minutes
    return time


if __name__ == "__main__":
    print(cicero_validate(sys.argv[1], sys.argv[2]))
