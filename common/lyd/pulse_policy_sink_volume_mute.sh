#! /usr/bin/env sh

set -ex

ACTIVATE=$1
SINK=$2
PROPERTY_VALUE=$3

OS2BORGERPC_PULSEAUDIO_CONFIG="/etc/pulse/default.pa.d/os2borgerpc.pa"
OLD_OS2BORGERPC_PULSEAUDIO_CONFIG="/etc/pulse/profile.pa.d/os2borgerpc.pa"
PROPERTY_VOLUME="set-sink-volume"
PROPERTY_MUTE="set-sink-mute"
MAX_INT_VOLUME=65356

  # 1 mutes, 0 unmutes
if [ "$PROPERTY_VALUE" = 0 ]; then
  MUTE_MAYBE=1
else
  MUTE_MAYBE=0
fi

VOLUME=$(( MAX_INT_VOLUME * PROPERTY_VALUE / 100 ))

if [ "$PROPERTY_VALUE" -lt 0 ] || [ "$PROPERTY_VALUE" -gt 100 ]; then
  echo "Volume percentage must be between 0 and 100 inclusive. Exiting."
  exit 1
fi

# 20.04 backwards compatibility - in 22.04 the default.pa.d directory and the reference to it is already there
# This function is shared between all the audio scripts
create_os2borgerpc_pulseaudio_config_dir() {
  MAIN_PULSEAUDIO_CONFIG="/etc/pulse/default.pa"

  # Note: There needs to be at least ONE file in here, otherwise pulse will now crash
  # The file can be empty no problem. Therefore we always create the file regardless.
  mkdir --parents "$(dirname $OS2BORGERPC_PULSEAUDIO_CONFIG)"

  if [ -f $OLD_OS2BORGERPC_PULSEAUDIO_CONFIG ]; then
    # Migrate the config at the old location to the new one
    mv $OLD_OS2BORGERPC_PULSEAUDIO_CONFIG $OS2BORGERPC_PULSEAUDIO_CONFIG
    rm --recursive --force "$(dirname $OLD_OS2BORGERPC_PULSEAUDIO_CONFIG)"
    sed --in-place "\@.include $(dirname $OLD_OS2BORGERPC_PULSEAUDIO_CONFIG)@d" $MAIN_PULSEAUDIO_CONFIG
  else
    touch $OS2BORGERPC_PULSEAUDIO_CONFIG
  fi

  # Idempotency + some versions of Ubuntu already have this dir by default, so at some point ideally we don't have to set this up
  if ! grep --quiet ".include $(dirname $OS2BORGERPC_PULSEAUDIO_CONFIG)" $MAIN_PULSEAUDIO_CONFIG ; then
    # Configure PulseAudio to load OS2borgerPC-specific settings from a special directory
    echo ".include $(dirname $OS2BORGERPC_PULSEAUDIO_CONFIG)" >> $MAIN_PULSEAUDIO_CONFIG
  fi
}

create_os2borgerpc_pulseaudio_config_dir

# Current setting for this particular property for this particular card?: Delete it first
sed --in-place --expression "/$PROPERTY_VOLUME $SINK/d" --expression "/$PROPERTY_MUTE $SINK/d" $OS2BORGERPC_PULSEAUDIO_CONFIG

if [ "$ACTIVATE" = "True" ]; then
	cat <<- EOF >> $OS2BORGERPC_PULSEAUDIO_CONFIG
		$PROPERTY_VOLUME $SINK $VOLUME
		$PROPERTY_MUTE $SINK $MUTE_MAYBE
	EOF
fi
