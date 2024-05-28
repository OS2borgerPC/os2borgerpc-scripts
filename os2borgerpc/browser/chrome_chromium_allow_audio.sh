#! /usr/bin/env sh

# AutoplayAllowed should enable autoplay globally while the other makes an exception and allows it for a specific
# webpage. So really, both shouldn't be needed.
# AudioOutputAllowed is probably irrelevant, but might as well start out with the sledge hammer approach and then refine
# from there

ACTIVATE="$1"
URL_1="$2"
URL_2="$3"
URL_3="$4"

URLS="$URL_1 $URL_2 $URL_3"
AUDIO_POLICY="/etc/opt/chrome/policies/managed/os2borgerpc-audio-allow.json"

set -x

if [ "$ACTIVATE" = "False" ]; then
  rm --force $AUDIO_POLICY
  exit
fi

# Add the head
cat > "$AUDIO_POLICY" <<EOF
{
  "AudioOutputAllowed": true,
  "AutoplayAllowed": true,
  "AutoplayAllowlist": [
EOF

# Add the URLs
# Isolate the last argument because json is badly designed when it comes to commas
# NOTE: This won't work if two URLs/arguments are identical
for last in $URLS; do :; done

for url in $URLS; do
    if [ "$url" != "$last" ]; then
      echo "    \"$url\"," >> $AUDIO_POLICY
    else
      echo "    \"$url\"" >> $AUDIO_POLICY
    fi
done

# Add the tail
cat >> "$AUDIO_POLICY" <<EOF
  ]
}
EOF
