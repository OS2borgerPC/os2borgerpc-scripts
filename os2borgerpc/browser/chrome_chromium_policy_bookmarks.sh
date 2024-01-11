#! /usr/bin/env sh

# Sets a few Chrome policies related to bookmarks
#
# Related Chrome/Chromium policies:
# EditBookmarksEnabled: Prevents users from changing bookmarks: https://chromeenterprise.google/policies/#EditBookmarksEnabled
# BookmarkBarEnabled: Shows the BookmarksBar by default: https://chromeenterprise.google/policies/#BookmarkBarEnabled
# ManagedBookmarks: Creates a folder in the bookmarksbar, with any number of bookmarks directly accessible, and any
# number of subdirectories (children) with their own bookmarks. It's seemingly not possible to set individual bookmarks directly in
# the top level outside that directory: https://chromeenterprise.google/policies/#ManagedBookmarks

# Example value for the argument JSON_BOOKMARKS

#		    {
#		      "name": "DuckDuckGo",
#		      "url": "duckduckgo.com"
#		    },
#		    {
#		      "name": "Subdirectory 1",
#		      "children": [
#		        {
#		          "name":  "OS2",
#		          "url": "os2.eu"
#		        },
#		        {
#		          "name":  "Magenta",
#		          "url": "magenta.dk"
#		        }
#		      ]
#		    }

set -ex

if get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en kiosk-maskine."
  exit 1
fi

ACTIVATE="$1"
TOPLEVEL_FOLDER_NAME="$2"
ALLOW_EDITING_BOOKMARKS="$3"
JSON_BOOKMARKS="$4" # This argument is a file

POLICY="/etc/opt/chrome/policies/managed/os2borgerpc-bookmarks.json"
JSON_BOOKMARKS_TMP="/tmp/json-bookmarks.txt"

if [ ! -d "$(dirname "$POLICY")" ]; then
    mkdir --parents "$(dirname "$POLICY")"
fi

# Fix file encoding on JSON_BOOKMARKS in case it's latin-1, as apparently Chrome fails to read æøå in that case
# and it never loads the policy.
if file --brief --mime "$JSON_BOOKMARKS" | grep --quiet 'iso-8859-1'; then
	iconv --from-code iso-8859-1 --to-code utf-8 "$JSON_BOOKMARKS" --output "$JSON_BOOKMARKS_TMP"
	JSON_BOOKMARKS=$JSON_BOOKMARKS_TMP
fi

if [ "$ALLOW_EDITING_BOOKMARKS" = "False" ]; then
	EDIT_BOOKMARKS='"EditBookmarksEnabled": false,'
fi

if [ "$ACTIVATE" = "True" ]; then

  cat <<- EOF > "$POLICY"
		{
		  "BookmarkBarEnabled": true,
			$EDIT_BOOKMARKS
			"ManagedBookmarks": [
				{
					"toplevel_name": "$TOPLEVEL_FOLDER_NAME"
				},
				$(cat "$JSON_BOOKMARKS")
			]
		}
	EOF

else
	rm "$POLICY"
fi
