#! /usr/bin/env sh

set -ex

ACTIVATE=$1
PROPERTY_VALUE=$2

OS2BORGERPC_PULSEAUDIO_CONFIG="/etc/pulse/profile.pa.d/os2borgerpc.pa"
PROPERTY="set-default-sink"

# This function is shared between all the audio scripts, as its not currently built in
create_os2borgerpc_pulseaudio_config_dir() {
  MAIN_PULSEAUDIO_CONFIG="/etc/pulse/default.pa"

  # Note: There needs to be at least ONE file in here, otherwise pulse will now crash
  # The file can be empty no problem. Therefore we always create the file regardless.
  mkdir --parents "$(dirname $OS2BORGERPC_PULSEAUDIO_CONFIG)"
  touch $OS2BORGERPC_PULSEAUDIO_CONFIG

  # Idempotency + some versions of Ubuntu already have this dir by default, so at some point ideally we don't have to set this up
  if ! grep --quiet ".include $(dirname $OS2BORGERPC_PULSEAUDIO_CONFIG)" $MAIN_PULSEAUDIO_CONFIG ; then
    # Configure PulseAudio to load OS2borgerPC-specific settings from a special directory
    printf ".include /etc/pulse/profile.pa.d" >> $MAIN_PULSEAUDIO_CONFIG
  fi
}

create_os2borgerpc_pulseaudio_config_dir

# Delete ANY default sink setting
sed --in-place "/$PROPERTY/d" $OS2BORGERPC_PULSEAUDIO_CONFIG

if [ "$ACTIVATE" = 'True' ]; then
  echo "$PROPERTY $PROPERTY_VALUE" >> $OS2BORGERPC_PULSEAUDIO_CONFIG
fi
