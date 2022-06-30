#! /usr/bin/env python3

# Arguments:
# 1. The command to run:
#   - fetch:
#   - put:
#   - delete: Deletes all the database content
#   - print_all: Print a list of all key-value pairs

import sys  # For CLI arguments
import plyvel  # For accessing the database

user = "chrome"


class PlyvelInterface:
    """
    Used to manage Plyvel databases, which are fx. used by Chromium/Chrome
    for browser storage.
    The database has key-value-pairs and this script can read and write them.
    Fx. relevant to debug the OS2display script (auto_activate_chromium).
    """

    def __init__(self):

        # self.db = plyvel.DB('/home/' + user + '/snap/chromium/common/chromium/Default/Sync Data/LevelDB', create_if_missing=True, compression=None)  # noqa E501
        self.db = plyvel.DB(
            "/home/"
            + user
            + "/snap/chromium/common/chromium/Default/Local Storage/leveldb",
            create_if_missing=True,
            compression=None,
        )
        # self.db = plyvel.DB('/home/'+ user + '/.config/chromium/Default/Local Storage/leveldb', create_if_missing=True, compression=None)  # noqa E501

    def fetch(self):
        for key, _value in self.keys:
            print(self.db.get(key))

    def put(self):
        for key, value in self.keys:
            self.db.put(key, value, sync=True)

    def delete(self):
        for key, value in self.keys:
            self.db.delete(key)

    def print_all(self):
        for key, value in self.db:
            print("Key:")
            print(key)
            print("Value:")
            print(value)

    def close(self):
        from time import sleep

        self.db.close()

        while not self.db.closed:
            sleep(1)
        print("Database connection closed")

    @classmethod
    def help(cls):
        return (
            "This script needs one argument: The command to run\n"
            + "Available commands: fetch, put, delete, print_all"
        )


if len(sys.argv) != 2:
    raise ValueError(PlyvelInterface.help())
else:
    pi = PlyvelInterface()

    arg = sys.argv[1]
    if arg == "fetch":
        pi.fetch()
    elif arg == "put":
        pi.put()
    elif arg == "delete":
        pi.delete()
    elif arg == "print_all":
        pi.print_all()
    else:
        raise ValueError(PlyvelInterface.help())

# Cleanup! Otherwise corruption errors might occur, I think?!
pi.close()
