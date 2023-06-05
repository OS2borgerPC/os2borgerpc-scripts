#! /usr/bin/env sh

set -ex

ACTIVATE=$1
SINK=$2
MUTE_STATUS=$3

OS2BORGERPC_PULSEAUDIO_CONFIG="/etc/pulse/profile.pa.d/os2borgerpc.pa"
PROPERTY="set-sink-mute"

if [ "$MUTE_STATUS" = "True" ]; then
  PROPERTY_VALUE=1  # 1 mutes, 0 unmutes
else
  PROPERTY_VALUE=0
fi

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

# Current setting for this particular property for this particular card?: Delete it first
sed --in-place "/$PROPERTY $SINK/d" $OS2BORGERPC_PULSEAUDIO_CONFIG

if [ "$ACTIVATE" = 'True' ]; then
  echo "$PROPERTY $SINK $PROPERTY_VALUE" >> $OS2BORGERPC_PULSEAUDIO_CONFIG
fi
