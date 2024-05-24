#! /usr/bin/env python3

import os
from urllib.parse import urlparse
from subprocess import check_output
from time import sleep
import sys

if b"kiosk" not in check_output(["get_os2borgerpc_config", "os2_product"]):
    print("This script is not designed to be run on a a regular OS2borgerPC machine.")
    sys.exit(1)

EXPECTED_ARG_COUNT = 4
if len(sys.argv) != EXPECTED_ARG_COUNT + 1:
    print(f"This script takes {EXPECTED_ARG_COUNT} arguments. Exiting.")
    sys.exit(1)

URL = sys.argv[1]
KEY = bytes(sys.argv[2], encoding="utf-8")
VALUE = bytes(sys.argv[3], encoding="utf-8")
KILL_BROWSER = sys.argv[4]

# TODO: Determine these programatically, so it works for both BPC and Kiosk AND Chrome/Chromium?
# Maybe only determine user/path1, but ask for which browser?
BROWSER_PROCESS_NAME = "chrome"
USER = "chrome"
DB_PATH_DIR = "/home/" + USER + "/snap/chromium/common/chromium/Default/Local Storage/"
DB_NAME = "leveldb/"
DB_PATH = DB_PATH_DIR + DB_NAME
PLYVEL_APT_PKG_NAME = "python3-plyvel"
PSUTIL_APT_PKG_NAME = "python3-psutil"

print(check_output(["apt-get", "update"]))
print(
    check_output(
        ["apt-get", "install", "--assume-yes", PLYVEL_APT_PKG_NAME, PSUTIL_APT_PKG_NAME]
    )
)

# Now these can be imported
import plyvel, psutil

browser_running = None
for proc in psutil.process_iter():
    if BROWSER_PROCESS_NAME in proc.name():
        browser_running = proc
        break

if browser_running:
    if KILL_BROWSER:
        # In order to modify Local Storage the browser can't be running. Shut it down.
        browser_running.kill()

        # Give the browser a bit of time to shut down
        sleep(5)
    else:
        print(
            "The browser is running and therefore we can't update LocalStorage - exiting"
        )
        sys.exit(1)

if not os.path.exists(DB_PATH_DIR):
    os.mkdir(DB_PATH_DIR)
    # Note: Use python builtins instead once they becomes less long-winded to use
    print(check_output(["chown", "--recursive", f"{USER}:{USER}", DB_PATH_DIR]))

print(f"About to connect to the leveldb DB_PATH: {DB_PATH}")

parsed_url = urlparse(URL)
url_key = parsed_url.scheme + "://" + parsed_url.netloc

db = plyvel.DB(DB_PATH, create_if_missing=True)
db.put(b"_" + str.encode(url_key) + b"\x00\x01" + KEY, b"\x01" + VALUE, sync=True)

db.close()

# Set the proper permissions on leveldb, as in some cases some files are now
# root owned which is no good, when chromium runs as a regular user:
print(check_output(["chown", "--recursive", f"{USER}:{USER}", DB_PATH_DIR]))

print("DB updated and connection closed.")
