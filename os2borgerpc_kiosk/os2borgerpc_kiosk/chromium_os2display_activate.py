#!/usr/bin/env python3

# """
# Activates an OS2display screen.
# Arguments: [url, activation_code]
# """
#
# __copyright__  = "Copyright 2022, Magenta Aps"
# __credits__    = ["Allan Grauenkjaer"]
# __license__    = "GPL"

# What it does:
# When activating a screen you type in an activation code and a token and
# a uuid is saved to local storage, and as a result the slideshow starts
# and it will persist across reboots.
# This script replicates that with a POST request, and saving it to Chromiums
# storage via plyvel.

# Ideas for changes: If updating from 16.04 .config/chromium can be deleted.

import os
import sys
import subprocess
from urllib.parse import urlparse
import re
import requests
from time import sleep


def activate(url, api_key, activation_code):
    # Manual test:
    # curl --insecure --data 'activationCode={activation_code_here}&apikey=middleware-main-api-key' {url_here}/proxy/screen/activate
    data = {"activationCode": activation_code, "apikey": api_key}
    # verify=False in case their ssl certificate is invalid which my test site's was at least
    resp = requests.post(url + "/proxy/screen/activate", json=data, verify=False)

    print(f"Response status code: {resp.status_code}")
    print(f"Response text: {resp.text}")

    # It might have some invalid characters that json.loads dislikes
    token = resp.json()["token"]

    print(f"Token: {token}")

    return (resp.status_code, token)


username = "chrome"

subprocess.call([sys.executable, "-m", "pip", "install", "plyvel"])

print("Installed plyvel.")

# Ignore E402 "module level import not at top of file"
# It isn't at the top because plyvel hasn't been installed at that point.
import plyvel  # noqa: E402


if len(sys.argv) == 3:
    url = sys.argv[1]
    # Remove trailing slash if the user typed the URL in with one
    if url[-1] == "/":
        url = url[:-1]
    activation_code = sys.argv[2]
    print(f"URL: {url}")
    print(f"Activation Code: {activation_code}")
else:
    print("Missing input parameters.")
    exit(1)

# FETCHING THE API KEY
CONFIG_URL = "/app/config.js"
resp_config = requests.get(url + CONFIG_URL, verify=False)
print(f"Status code response from {CONFIG_URL}: {resp_config.status_code}")

if resp_config.status_code == 200:
    api_key_match = re.search(r'(?<="apikey": ")[^"]+', resp_config.text)

    if not api_key_match:
        print(
            "Failed to find the API Key in the output from {url}{CONFIG_URL}. Exiting."
        )
        exit(1)
    else:
        api_key = api_key_match.group()
        print(f"API KEY: {api_key}")
else:
    print(
        f"Request to {CONFIG_URL} failed, which is required to fetch the API key. Exiting."
    )
    exit(1)

# Stepwise process
# 1. Attempt to activate to get the token related to this activationCode
# 2. Kick other screens using this activation code (normally you're asked in a popup to continue or not)
# 3. Now authenticate again, just like step one, but this time uninterrupted because no other screen is using it

resp_status_code, temp_token = activate(url, api_key, activation_code)

if resp_status_code != 200:
    print(
        "An existing screen is activated using the activation code. Attempting to kick it:"
    )

    # Kick existing screens using this code
    kick_url = "/proxy/screen/kick"
    headers = {"Authorization": f"Bearer {temp_token}"}
    data_kick = {"token": temp_token}
    resp = requests.post(url + kick_url, json=data_kick, verify=False, headers=headers)
    if resp.status_code != 200:
        print("Failed to kick the existing screen using the activation code.")
        print(f"Status code received was: {resp.status_code}")
        print(f"Data sent was: {data_kick}")
        print(f"URL was: {url}{kick_url}")
        print("Data received was:")
        print(resp.text)
        print("Exiting")
        exit(1)
    else:
        print("Existing screen kicked successfully. Attempting to activate it again.")

    # ...and now activate again, which produces a different token:
    resp_status_code, token = activate(url, api_key, activation_code)

    if resp_status_code != 200:
        print("The server couldn't activate the screen correctly. Exiting.")
        print(f"Status code was: {resp_status_code}")
        exit(1)
    else:
        print(
            "Screen activated correctly with the API. About to update local storage leveldb with the information:"
        )
else:
    print(
        "Activation code not currently in use. No need to kick any existing screens using it."
    )
    token = temp_token

# The value of the uuid seemingly doesn't matter - it changes between calls
# uuid = "randomstring"
uuid = "1Nlv3s4w4dybf"  # Actual example from a manual activation

# Making sure all instances of Chromium are shut down,
# or leveldb will be inaccessible to plyvel
# chromium's binary is also called chrome
subprocess.call("killall chrome", shell=True)
sleep(5)

db_path = f"/home/{username}/snap/chromium/common/chromium/Default/Local Storage/"
if not os.path.exists(db_path):
    os.makedirs(db_path)

db_name = "leveldb/"
db_path += db_name
print(f"Connecting to leveldb db_path: {db_path}")

parsed_url = urlparse(url)
url_key = parsed_url.scheme + "://" + parsed_url.netloc

# If not working try adding compression=None
db = plyvel.DB(db_path, create_if_missing=True)
db.put(
    b"_" + bytes(url_key, "ascii") + b"\x00\x01indholdskanalen_uuid",
    b"\x01" + bytes(uuid, "ascii"),
    sync=True,
)
db.put(
    b"_" + bytes(url_key, "ascii") + b"\x00\x01indholdskanalen_token",
    b"\x01" + bytes(token, "ascii"),
    sync=True,
)

db.close()

# Set the proper permissions on leveldb, as in some cases some files are now
# root owned which is no good, when chromium runs as a regular user:
subprocess.call(["chown", "-R", f"{username}:{username}", db_path])

print("DB updated and connection closed.")
