#! /usr/bin/env sh

# Activate sound in OS2BorgerPC Booking (Ubuntu Server)
# Reboot afterwards for it to take effect.
# Arguments:
#   1. What command to run: 0-2
#   2: What sound device (sink) to enable (this parameter is only relevant for command 2)

OPTION=$1
SINK="$2"
export DEBIAN_FRONTEND=noninteractive
FILE=/home/chrome/.xinitrc

# Hacky workaround to be able to run pactl as root
# https://stackoverflow.com/a/64932897/1172409
run_pactl_command() {
  # Access to pulseaudio will fail if not in the right group
  # note: still has an exit status of 0 if root is already in the group
  adduser --quiet root pulse-access
  #adduser root pulse
  # Running a systemwide pulseaudio instance, for pactl
  pulseaudio --system=true 2>/dev/null &
  PID=$!

  # Give the pulseaudio server a bit of time to start
  sleep 5

  # Circumvent a permissions error since it's owned by the pulse user and we
  # can't su to that service user
  chown root:root /var/run/pulse

  # shellcheck disable=SC2086 # We actually want word-splitting here
  XDG_RUNTIME_DIR=/var/run pactl $1

  # Cleanup: Stop the process again, though leave the user in the group
  kill $PID
}

install_pa_if_missing() {
  if ! dpkg -s pulseaudio > /dev/null 2>&1; then
    apt-get update --assume-yes --quiet
    apt-get install --assume-yes --quiet pulseaudio
  fi
}

case $OPTION in
  0) # 1. List all cards (no option to only list details for a single card).
    install_pa_if_missing
    run_pactl_command "list sinks"
    ;;

  1) # Setup
    install_pa_if_missing
    # While this, too, is possible to do through root, it doesn't seem to affect the running
    # pulseaudio server, and so it stays muted there. So we reluctantly set it in .xinitrc instead
    #run_pactl_command "set-sink-mute $SINK 0"
    sed --in-place "/rotate_screen.sh/a\ \npactl set-sink-mute $SINK 0\npactl set-sink-volume $SINK 80%" $FILE
    ;;

  2) # Uninstall
    #sed -in-place '/pactl/d' $FILE
    apt-get remove --assume-yes pulseaudio
    ;;

  *)
    printf "%s\n" "Ugyldigt inputparameter: Gyldige værdige er: 0-2"
    ;;
esac
