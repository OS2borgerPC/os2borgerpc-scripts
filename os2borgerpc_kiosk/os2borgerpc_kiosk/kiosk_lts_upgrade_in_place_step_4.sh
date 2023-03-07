#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    kiosk_lts_upgrade_in_place_step_4.sh
#%
#% DESCRIPTION
#%    Step four of the upgrade from 20.04 to 22.04.
#%    Designed for Kiosk machines
#%
#================================================================
#- IMPLEMENTATION
#-    version         kiosk_lts_upgrade_in_place_step_4.sh 0.0.1
#-    author          Andreas Poulsen
#-    copyright       Copyright 2023, Magenta Aps
#-    license         BSD/MIT
#-    email           info@magenta.dk
#-
#================================================================
#  HISTORY
#     2023/02/01 : ap : Script creation
#
#================================================================
# END_OF_HEADER
#================================================================

set -ex

if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en regulær borgerPC-maskine."
  exit 1
fi

# Make double sure that the crontab has been emptied
TMP_ROOTCRON=/etc/os2borgerpc/tmp_rootcronfile
if [ -f "$TMP_ROOTCRON" ]; then
  crontab -r || true
fi

# Remove the old client and the remainder of the old version of python
NEW_CLIENT="/usr/local/lib/python3.10/dist-packages/os2borgerpc/client/jobmanager.py"
if [ -f $NEW_CLIENT ]; then
  rm -rf /usr/local/lib/python3.8/
  apt-get --assume-yes remove --purge python3.8-minimal || true
fi

# Remove any dependencies of the old version of python that are no longer used
apt-get --assume-yes autoremove

# Set danish timezone and language
timedatectl set-timezone Europe/Copenhagen
dpkg-reconfigure -f noninteractive tzdata
sed -i 's/# \(da_DK.UTF-8 UTF-8\)/\1/'  /etc/locale.gen
dpkg-reconfigure --frontend=noninteractive locales
update-locale LANG=da_DK.UTF-8

# Update the time accordingly
export DEBIAN_FRONTEND=noninteractive
apt-get install -y ntpdate
ntpdate pool.ntp.org

# Setup Chromium user
USER="chrome"
if ! id $USER &>/dev/null; then
  useradd $USER -m -p 12345 -s /bin/bash -U
fi

# Setup autologin of default user
mkdir -p /etc/systemd/system/getty@tty1.service.d

# Note: The empty ExecStart is not insignificant!
# By default the value is appended, so the empty line changes it to an override
cat << EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin $USER %I $TERM
Type=idle
EOF

# Change rotate_screen.sh and .xinitrc to the new versions
ROTATE_SCREEN="/usr/local/bin/rotate_screen.sh"
XINITRC="/home/chrome/.xinitrc"
if [ -f $ROTATE_SCREEN ]; then
  TIME=$(grep "sleep" $ROTATE_SCREEN | cut --delimiter ' ' --fields 2)
  ORIENTATION=$(grep -- "--rotate" $ROTATE_SCREEN | cut --delimiter ' ' --fields 11)
  sed --in-place "s/local\/bin\/rotate_screen.sh/share\/os2borgerpc\/bin\/rotate_screen.sh $TIME $ORIENTATION/" $XINITRC
  rm $ROTATE_SCREEN
fi
mkdir --parents "/usr/share/os2borgerpc/bin"
cat << EOF > /usr/share/os2borgerpc/bin/rotate_screen.sh
#!/usr/bin/env sh

set -x

TIME=\$1
ORIENTATION=\$2

sleep \$TIME

export XAUTHORITY=/home/$USER/.Xauthority

# --listactivemonitors lists the primary monitor first
ALL_MONITORS=\$(xrandr --listactivemonitors | tail -n +2 | cut --delimiter ' ' --fields 6)

# Make all connected monitors display what the first monitor displays, rather than them extending the desktop
PRIMARY_MONITOR=\$(echo "\$ALL_MONITORS" | head -n 1)
OTHER_MONITORS=\$(echo "\$ALL_MONITORS" | tail -n +2)
echo "\$OTHER_MONITORS" | xargs -I {} xrandr --output {} --same-as "\$PRIMARY_MONITOR"

# Rotate screen - and if more than one monitor, rotate them all.
echo "\$ALL_MONITORS" | xargs -I {} xrandr --output {} --rotate \$ORIENTATION
EOF

chmod +x /usr/share/os2borgerpc/bin/rotate_screen.sh

# If they were using an onboard keyboard, maintain our custom settings
if [ -f /usr/share/onboard/layouts/Compact_orig.onboard ]; then
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
chmod 644 /usr/share/onboard/layouts/Compact.onboard
fi

#Enable automatic security updates if they were not already enabled
CONF="/etc/apt/apt.conf.d/90os2borgerpc-automatic-upgrades"
if [ ! -f "$CONF" ]; then
  wget -O - https://github.com/OS2borgerPC/os2borgerpc-scripts/raw/master/common/system/apt_periodic_control.sh | bash -s -- sikkerhed
fi

# Reset jobmanager timeout to default value
set_os2borgerpc_config job_timeout 900

os2borgerpc_push_config_keys job_timeout

# Update distribution to show ubuntu22.04
set_os2borgerpc_config distribution ubuntu22.04

os2borgerpc_push_config_keys distribution

# Fix dpkg settings
cat << EOF > /etc/apt/apt.conf.d/local
Dpkg::Options {
   "--force-confdef";
   "--force-confold";
};
Dpkg::Lock {Timeout "300";};
EOF

# Restore crontab and reenable potential wake plans
TMP_ROOTCRON=/etc/os2borgerpc/tmp_rootcronfile
if [ -f "$TMP_ROOTCRON" ]; then
  crontab $TMP_ROOTCRON
  rm -f $TMP_ROOTCRON
fi
if [ -f /etc/os2borgerpc/plan.json ]; then
  systemctl enable --now os2borgerpc-set_on-off_schedule.service
fi
