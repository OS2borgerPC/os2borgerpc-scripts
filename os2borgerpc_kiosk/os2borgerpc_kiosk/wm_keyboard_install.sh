#! /usr/bin/env sh

# DESCRIPTION:
# This script installs, sets up and enables a wm (bspwm)
# and an on-screen keyboard (onboard).
# Intended for OS2borgerPC Kiosk.
#
# ARGUMENTS:
# 1: Whether to install / uninstall the wm + onscreen keyboard
#
# PREREQUISITES:
# 1. OS2borgerPC Kiosk - Installer Chromium
# 2. OS2borgerPC Kiosk - Autostart Chromium
#
# Would like to skip installing sxhkd but it's not trivial to do as it's
# classified as a "required dependency" for bspwm
#
# AUTHOR: mfm@magenta.dk

set -ex

if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en regulær OS2borgerPC-maskine."
  exit 1
fi

[ -z "$1" ] && exit 1

ACTIVATE=$1

CHROMIUM_SCRIPT='/usr/share/os2borgerpc/bin/start_chromium.sh'
USER=chrome
XINITRC="/home/$USER/.xinitrc"
# Note: Only the Compact keyboard layout is changed to not have Ctrl, Alt etc.
ONBOARD_OPTIONS="--theme=/usr/share/onboard/themes/HighContrast.theme --layout /usr/share/onboard/layouts/Compact.onboard"
# For apt installations/removals
export DEBIAN_FRONTEND=noninteractive

if [ "$ACTIVATE" = 'True' ]; then

  # Keyboard options: onboard (~100 mb incl. dependencies?), xvkbd (almost no
  # dependencies), florence (~500 mb incl. dependencies?!),
  # gnome onscreen keyboard, carabou
  # TODO: language-pack-da is now in install_dependencies.sh but older installs
  # ran a previous version of that, so keeping it here too
  apt-get update
  apt-get install -y language-pack-da bspwm onboard lemonbar- dmenu-

  cd /home/$USER || exit 1
  # Make the directory for the config
  # -p is also there to suppress errors in case someone re-runs this script,
  # and it already exists
  mkdir -p .config/bspwm

  # onboard: If we want a non-default keyboard theme this is apparently necessary
  # because it attempts to create a file in there
  mkdir -p .config/dconf
  chown $USER:$USER .config/dconf

  # Configure bspwm
cat << EOF > .config/bspwm/bspwmrc
#! /bin/sh

bspc monitor -d I

bspc config border_width         0
bspc config window_gap           0
bspc config borderless_monocle   true
bspc config gapless_monocle      true

# leave 20% space for the keyboard
bspc config split_ratio          0.80

# Always split downwards/vertically instead of whichever direction there is
# more space (typically horizontally to begin with)
bspc rule -a "*" split_dir=south

# Test if no difference?: Don't default to monocle?
# bspc desktop I --layout tiled

# layer=normal is needed at least, to ensure it doesn't cover the entire
# screen by default
bspc rule -a Onboard state=tiled layer=normal

# Onboard preferences shouldn't be shown at all. TODO: Not working, but it also
# doesn't matter right now because the button to show them is no longer there.
# bspc rule -a "Onboard Preferences" layer=below flag=hidden

# Launch chromium
$CHROMIUM_SCRIPT wm &

# we want æøå on the keyboard
setxkbmap dk

#sleep 5  # Go back to this solution if the below solution fails

# Wait until a window (the browser) exists because onboard needs to be below it
while ! bspc query -N -n .leaf > /dev/null; do
  sleep 0.5
done

# First time setup of onboard. Attempt at solving a bug where the keyboard
# doesn't appear, seemingly due to first time initialization
if [ ! -f /home/$USER/.config/dconf/user ]; then
  onboard $ONBOARD_OPTIONS &
  # Give it some time to start
  sleep 3
  killall onboard
  sleep 1
fi

# Not certain setting the options is outright necessary past first time setup
onboard $ONBOARD_OPTIONS &
EOF

  # Give it the same permissions as /usr/share/doc/bspwm/examples/bspwmrc
  chmod 755 .config/bspwm/bspwmrc

  # Don't auto-start chromium from xinitrc
  sed -i "s,\(.*$CHROMIUM_SCRIPT.*\),#\1," $XINITRC

  # Instead start autostarting bspwm - don't add it multiple times though
if ! grep -q -- 'exec bspwm' "$XINITRC"; then
cat << EOF >> "$XINITRC"
exec bspwm
EOF
fi

  # Backup the original Compact layout
  cp /usr/share/onboard/layouts/Compact.onboard /usr/share/onboard/layouts/Compact_orig.onboard

  # Use our own Onboard model without ctrl, alt, super etc.
  # This is simply the original file with several sections (keys) commented out.
cat << EOF > /usr/share/onboard/layouts/Compact.onboard
<?xml version="1.0" ?>
<!-- OS2borgerPC Kiosk: Comment out Control, Alt, Quit and Settings buttons -->

<!--
Copyright © 2013 Francesco Fumanti <francesco.fumanti@gmx.net>
Copyright © 2011-2014 marmuta <marmvta@gmail.com>

This file is part of Onboard.

Onboard is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

Onboard is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
-->

<keyboard
    id="Compact"
    format="3.2"
    section="system"
    summary="Medium size desktop keyboard" >

    <include file='key_defs.xml'/>

    <box border="0.5" spacing="1.5" orientation="vertical">

        <!--- word suggestions -->
        <panel filename='Compact-Alpha.svg' scan_priority='1'>
            <include file='word_suggestions.xml'/>
        </panel>

        <box spacing='1.5'>
            <box spacing='2'>
                <!--- keyboard, multiple layers -->
                <panel>
                    <panel layer="alpha" filename="Compact-Alpha.svg">
                        <key group="alphanumeric" id="AB01"/>
                        <key group="alphanumeric" id="AE02"/>
                        <key group="alphanumeric" id="AE03"/>
                        <key group="alphanumeric" id="AD09"/>
                        <key group="alphanumeric" id="AE01"/>
                        <key group="alphanumeric" id="AE06"/>
                        <key group="alphanumeric" id="AE07"/>
                        <key group="alphanumeric" id="AE04"/>
                        <key group="alphanumeric" id="AE05"/>
                        <key group="alphanumeric" id="AD03"/>
                        <key group="alphanumeric" id="AD02"/>
                        <key group="alphanumeric" id="AD01"/>
                        <key group="alphanumeric" id="AE09"/>
                        <key group="alphanumeric" id="AD07"/>
                        <key group="alphanumeric" id="AD06"/>
                        <key group="alphanumeric" id="AD05"/>
                        <key group="alphanumeric" id="AD04"/>
                        <key group="alphanumeric" id="AB10"/>
                        <key group="alphanumeric" id="AC11"/>
                        <key group="alphanumeric" id="AC10"/>
                        <key group="alphanumeric" id="TLDE"/>
                        <key group="alphanumeric" id="LSGT"/>
                        <key group="alphanumeric" id="BKSL"/>
                        <key group="alphanumeric" id="AD10"/>
                        <key group="alphanumeric" id="AD11"/>
                        <key group="alphanumeric" id="AD12"/>
                        <key group="alphanumeric" id="AB08"/>
                        <key group="alphanumeric" id="AE11"/>
                        <key group="alphanumeric" id="AE10"/>
                        <key group="alphanumeric" id="AE12"/>
                        <key group="alphanumeric" id="AC04"/>
                        <key group="alphanumeric" id="AC05"/>
                        <key group="alphanumeric" id="AC06"/>
                        <key group="alphanumeric" id="AC07"/>
                        <key group="alphanumeric" id="AB09"/>
                        <key group="alphanumeric" id="AC01"/>
                        <key group="alphanumeric" id="AC02"/>
                        <key group="alphanumeric" id="AC03"/>
                        <key group="alphanumeric" id="AB05"/>
                        <key group="alphanumeric" id="AB04"/>
                        <key group="alphanumeric" id="AE08"/>
                        <key group="alphanumeric" id="AB06"/>
                        <key group="alphanumeric" id="AC08"/>
                        <key group="alphanumeric" id="AC09"/>
                        <key group="alphanumeric" id="AB03"/>
                        <key group="alphanumeric" id="AB02"/>
                        <key group="alphanumeric" id="AD08"/>
                        <key group="alphanumeric" id="AB07"/>

                        <key group='misc'      id='CAPS'/>
                        <key group='shifts'    id='LFSH'/>
                        <key group='shifts'    id='RTSH'/>
                        <!--<key group='bottomrow' id='LCTL'/>
                        <key group='bottomrow' id='LALT'/>
                        <key group='bottomrow' id='RALT'/>
                        <key group="bottomrow" id="LWIN"/>-->

                        <key group="bottomrow" id="SPCE"/>
                        <key group="bottomrow" id="DELE.next-to-backspace"/>
                        <key group="bottomrow" id="BKSP"/>
                        <key group="misc" id="TAB"/>
                        <key group="misc" id="RTRN" label_x_align='0.65'/>
                        <key group="directions_alpha" id="LEFT"/>
                        <key group="directions_alpha" id="RGHT"/>
                        <key group="directions_alpha" id="UP"/>
                        <key group="directions_alpha" id="DOWN"/>
                    </panel>
                    <panel layer="numbers" filename="Compact-Numbers.svg" border="2">

                        <key group='keypadmisc' id='NMLK' scan_priority='2'/>
                        <key group="keypadmisc" id="KPDL" scan_priority="2"/>
                        <key group="keypadmisc" id="KPEN" scan_priority="2"/>
                        <key group="keypadnumber" id="KP0" scan_priority="2"/>
                        <key group="keypadnumber" id="KP1" scan_priority="2"/>
                        <key group="keypadnumber" id="KP2" scan_priority="2"/>
                        <key group="keypadnumber" id="KP3" scan_priority="2"/>
                        <key group="keypadnumber" id="KP4" scan_priority="2"/>
                        <key group="keypadnumber" id="KP5" scan_priority="2"/>
                        <key group="keypadnumber" id="KP6" scan_priority="2"/>
                        <key group="keypadnumber" id="KP7" scan_priority="2"/>
                        <key group="keypadnumber" id="KP8" scan_priority="2"/>
                        <key group="keypadnumber" id="KP9" scan_priority="2"/>
                        <key group="keypadoperators" id="KPSU" scan_priority="2"/>
                        <key group="keypadoperators" id="KPDV" scan_priority="2"/>
                        <key group="keypadoperators" id="KPAD" scan_priority="2"/>
                        <key group="keypadoperators" id="KPMU" scan_priority="2"/>
                        <key group="directions" id="LEFT" scan_priority="1"/>
                        <key group="directions" id="RGHT" scan_priority="1"/>
                        <key group="directions" id="UP" scan_priority="1"/>
                        <key group="directions" id="DOWN" scan_priority="1"/>
                        <key group="editing" id="INS"/>
                        <key group="editing" id="DELE"  label='Del' image=''/>
                        <key group="editing" id="HOME"/>
                        <key group="editing" id="END"/>
                        <key group="editing" id="PGUP"/>
                      <key group="editing" id="PGDN"/>

                        <key group="bottomrow" id="ESC"/>
                        <key group="fkeys" id="F1.rows_of_six"/>
                        <key group="fkeys" id="F2.rows_of_six"/>
                        <key group="fkeys" id="F3.rows_of_six"/>
                        <key group="fkeys" id="F4.rows_of_six"/>
                        <key group="fkeys" id="F5.rows_of_six"/>
                        <key group="fkeys" id="F6.rows_of_six"/>
                        <key group="fkeys" id="F7.rows_of_six"/>
                        <key group="fkeys" id="F8.rows_of_six"/>
                        <key group="fkeys" id="F9.rows_of_six"/>
                        <key group="fkeys" id="F12.rows_of_six"/>
                        <key group="fkeys" id="F10.rows_of_six"/>
                        <key group="fkeys" id="F11.rows_of_six"/>
                        <key group="editing" id="Prnt" scan_priority="1"/>
                        <key group="editing" id="Pause" scan_priority="1"/>
                        <key group="editing" id="Scroll" scan_priority="1"/>
                    </panel>
                    <!--
                    <panel layer="utils" filename="Compact-Utils.svg" border="2">
                        <key group='snippets' id='m0'/>
                        <key group='snippets' id='m1'/>
                        <key group='snippets' id='m2'/>
                        <key group='snippets' id='m3'/>
                        <key group='snippets' id='m4'/>
                        <key group='snippets' id='m5'/>
                        <key group='snippets' id='m6'/>
                        <key group='snippets' id='m7'/>
                        <key group='snippets' id='m8'/>
                        <key group='snippets' id='m9'/>
                        <key group='snippets' id='m10'/>
                        <key group='snippets' id='m11'/>
                        <key group='snippets' id='m12'/>
                        <key group='snippets' id='m13'/>
                        <key group='snippets' id='m14'/>
                        <key group='snippets' id='m15'/>
                        <key group='bottomrow' id='quit' scan_priority="1"/>
                        <key group='bottomrow' id='settings' scan_priority="1"/>
                    </panel>-->
                </panel>

            </box>

            <!--- click helpers -->
            <!--
            <panel id="click" filename="Compact-Alpha.svg" >
                <key group='click' id='middleclick'/>
                <key group='click' id='secondaryclick'/>
                <key group='click' id='doubleclick'/>
                <key group='click' id='dragclick'/>
                <key group='click' id='hoverclick.bottom-row' unlatch_layer="false"/>
            </panel>-->

            <!--- side bar -->
            <panel id="paneswitch" filename="Compact-Alpha.svg">
                <box compact="true" orientation='vertical'>
                    <panel group='nowordlist'>
                        <!-- <key group='bottomrow' id='hide'/> -->
                        <box orientation='vertical'>
                            <box orientation="horizontal" expand="false">
                              <!-- <key group="bottomrow" id="showclick"/> -->
                              <!-- <key group="bottomrow" id="move"/> -->
                            </box>
                            <!-- <key group="bottomrow" id="layer0" show_active="false" scan_priority="3"/> -->
                            <!-- <key group="bottomrow" id="layer1" scan_priority="3"/> -->
                            <!-- <key group="bottomrow" id="layer2" scan_priority="3"/> -->
                        </box>
                    </panel>
                    <panel group='wordlist'>
                        <box orientation='vertical'>
                          <!--
                            <key group='sidebar' id='move' svg_id='move.wordlist' expand='false' label_margin='2.5'/>
                            <key group='sidebar' id='showclick' svg_id='showclick.wordlist' label_margin='2' expand='false'/>
                            <key group='bottomrow' id='layer0' show_active="false" svg_id='layer0.wordlist' scan_priority='3'/>
                            <key group='bottomrow' id='layer1' svg_id='layer1.wordlist' scan_priority='3'/>
                            <key group="bottomrow" id="layer2" svg_id='layer2.wordlist' scan_priority="3"/>
                          -->
                      </box>
                    </panel>
                </box>
            </panel>

        </box>
    </box>
</keyboard>
EOF

  # Give it the same permission as the file it overwrites
  chmod 644 /usr/share/onboard/layouts/Compact.onboard

else # Go back to not using a wm or the onscreen keyboard

  apt-get remove -y bspwm onboard
  apt-get autoremove -y

  # Restore the original Compact layout in case it hasn't been deleted - ignore
  # errors if fx. the dir no longer exists.
  # true is here to prevent stopping if set -e is set
  cp /usr/share/onboard/layouts/Compact_orig.onboard /usr/share/onboard/layouts/Compact.onboard 2>/dev/null || true

  # Start chromium from xinitrc instead of bspwm
  sed -i "s,#\(.*$CHROMIUM_SCRIPT.*\),\1," $XINITRC
  sed -i "/\(exec bspwm\)/d" $XINITRC
fi
