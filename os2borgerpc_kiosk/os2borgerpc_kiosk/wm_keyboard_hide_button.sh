#! /usr/bin/env sh

# DESCRIPTION:
# Add a button to show/hide the onscreen keyboard
# ...or more precisely it toggles fullscreen on the browser
# Intended for OS2borgerPC Kiosk.
#
# ARGUMENTS:
# 1: Whether to install / uninstall the button
# 2: The name of the process (e.g. a browser) that should be full screened
# 3: The background image to use for the GTK window (keyboard toggle button)
#
# PREREQUISITES:
# 1. os2borgerpc_kiosk/os2borgerpc_kiosk/chromium_install.sh
# 2. os2borgerpc_kiosk/os2borgerpc_kiosk/chromium_setup.sh
# 3. os2borgerpc_kiosk/os2borgerpc_kiosk/wm_keyboard_install.sh
#
# AUTHOR: mfm@magenta.dk

set -ex

if ! get_os2borgerpc_config os2_product | grep --quiet kiosk; then
  echo "Dette script er ikke designet til at blive anvendt på en regulær OS2borgerPC-maskine."
  exit 1
fi

### SETTINGS ###

lower() {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

[ $# != 4 ] \
  && printf "This script needs exactly four arguments which it wasn't given. Exiting." \
  && exit 1

ACTIVATE=$1
# Needs to be a valid process name - technically it can be any program
# Tested values: chromium
BROWSER="$(lower "$2")"
BUTTON_ICON_PATH="$3"
BUTTON_Y_OFFSET="$4"

# The input is just a number, but if it's positive we want a "+" prepended for the calculation
[ "$BUTTON_Y_OFFSET" -ge 0 ] && BUTTON_Y_OFFSET="+ $BUTTON_Y_OFFSET"

CUSER=chrome
BSPWM_CONFIG="/home/$CUSER/.config/bspwm/bspwmrc"

SCRIPTS_BASE_PATH=/usr/share/os2borgerpc/bin/keyboard-button
# Doesn't work if this is lowercase btn.py.
# The bspc rule supposed to match it no longer matches, so seemingly something uppercases the first letter for window
# name
BUTTON_WINDOW_TITLE="Btn.py"
# Doesn't need to be the same but why not
BUTTON_SCRIPT="$BUTTON_WINDOW_TITLE"
BSPWM_ADD_BUTTON_SCRIPT="bspwm_add_button.sh"
BUTTON_MOVE_SCRIPT="button_move.sh"
FULLSCREEN_TOGGLE_SCRIPT="toggle_fullscreen.sh"
BUTTON_STYLING_CSS_FILE="btn.css"

export DEBIAN_FRONTEND=noninteractive

if [ "$ACTIVATE" = 'True' ]; then

  ### SCRIPT PROPER ###

  # Install some dependencies

  # Could also use cut or something so jq isn't needed
  apt-get install --assume-yes xdotool jq fonts-noto-color-emoji

  # Requirements: python gi

  mkdir --parents "$SCRIPTS_BASE_PATH"
  cd "$SCRIPTS_BASE_PATH" || printf 'Fejl i initialiseringen' || exit 1

  ### FULLSCREEN TOGGLING BUTTON ###

  # To style a button (e.g. change its background color) we need a CSS file:
	cat <<- EOF > $SCRIPTS_BASE_PATH/$BUTTON_STYLING_CSS_FILE
		/* Turn a caret into an arrow down */
		.our-button { background: transparent; color: white; border: none; font-size: 50px; margin: 0;}
		.our-window { border: none; margin: 0; opacity: 0.5; background: url("$SCRIPTS_BASE_PATH/bg.png"); background-size: contain; }
		/*.our-window { border: none; margin: 0; opacity: 0.5; background: black; }*/
	EOF

  # Note that if the font-size is specified in the CSS, the size here is of
  # no importance to the button
  mkdir --parents /home/$CUSER/.config/gtk-3.0
	cat <<- EOF > /home/$CUSER/.config/gtk-3.0/settings.ini
  [Settings]
  gtk-font-name = Noto Color Emoji 15
	EOF

	cat <<- EOF > /home/$CUSER/.config/gtk-3.0/gtk.css
		.window-frame {
		  box-shadow: none;
		  margin: 0;
		}
	EOF

  # Move the uploaded bg image to the location where we load it from
  cp "$BUTTON_ICON_PATH" $SCRIPTS_BASE_PATH/bg.png

	cat <<- EOF > "$BUTTON_SCRIPT"
		#! /usr/bin/env python3

		# "Rules for positioning and sizing floating windows":
		# https://github.com/baskerville/bspwm/issues/263
		# Other resources used:
		# https://www.youtube.com/watch?v=rVjGiOiDl4M
		# https://wiki.archlinux.org/title/GTK#Basic_theme_configuration
		# https://mail.gnome.org/archives/gtk-app-devel-list/2016-August/msg00021.html

		# For calling the script that toggles fullscreen for firefox
		from subprocess import call

		# For the GTK button
		import gi
		gi.require_version('Gtk', '3.0')
		from gi.repository import Gtk, Gdk, Gio  # noqa: E402

		WIDTH = 57
		HEIGHT = 5


		# Customize Gtk.window to have our keyboard button
		class MyWindow(Gtk.Window):
		    # Just a custom function to gather all the logic to actually read a CSS file
		    def setup_css(self):
		        provider = Gtk.CssProvider()
		        provider.load_from_file(Gio.File.new_for_path("$SCRIPTS_BASE_PATH/$BUTTON_STYLING_CSS_FILE"))
		        Gtk.StyleContext.add_provider_for_screen(
		            Gdk.Screen.get_default(),
		            provider,
		            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

		    def __init__(self):
		        Gtk.Window.__init__(self, title="Hello")
		        self.setup_css()
		        # Text to appear on the button
		        #self.btn = Gtk.Button(label="^")
		        # Note: To support emojis install fx. fonts-noto-color-emoji
		        #self.btn = Gtk.Button(label="🎹")
		        #self.btn = Gtk.Button(label="🔽")
		        #self.btn = Gtk.Button(label="⌨")
		        self.btn = Gtk.Button()
		        self.btn.connect("clicked", self.btn_pressed)
		        self.add(self.btn)
		        # Size of the button, unfortunately GTK doesn't seem to care
		        self.set_size_request(WIDTH, HEIGHT)
		        self.btn.set_size_request(WIDTH, HEIGHT)
		        self.set_default_size(WIDTH, HEIGHT)
		        # Apply the CSS attributes specified in the CSS file above
		        self.get_style_context().add_class('our-window')
		        self.btn.get_style_context().add_class('our-button')
		        # Deprecated way of setting background color
		        # Gtk.Window.override_background_color(self.btn, Gtk.StateType.NORMAL, Gdk.RGBA(255,0,0,0))

		    # Button handler
		    def btn_pressed(self, widget):
		        call("$SCRIPTS_BASE_PATH/toggle_fullscreen.sh", shell=True)


		# win = Gtk.Window()
		win = MyWindow()
		win.show_all()
		Gtk.main()
	EOF

  ### BUTTON MOVE SCRIPT ###

	cat <<- EOF > "$BUTTON_MOVE_SCRIPT"
		#! /usr/bin/env sh

		WINDOW_TO_MOVE="$BUTTON_WINDOW_TITLE"

		# Try to match the black border margin of the keyboard, ish
		X_OFFSET=16

		# 1. isolate line with the current resolution
		# 2. isolate resolution
		# 3. isolate y coordinate
		Y_OFFSET=\$(xrandr | grep '*' | cut -d' ' -f 4 | cut -d'x' -f 2)
		# Adjusting Y_OFFSET based off subtracting button height * 2 (set in btn.py)
		# Update: Would LIKE to adjust based off button height, but GTK/bspwm is not
		# respecting the sizes I've set, so...
		Y_OFFSET_ADJUSTED=\$((Y_OFFSET - 26 $BUTTON_Y_OFFSET))

		for line in \$(bspc query -N -n .leaf | xargs -n 1 bspc query -T -n); do
		  if echo "\$line" | grep -q "\$WINDOW_TO_MOVE"; then
		    name=0x"\$(printf "%x\n" \$(echo "\$line" | jq .id))"

		    # NOTE: Both of these can move windows off screen, so fx. moving to a
		    # corner other than top left (0, 0) needs exact coordinates?! :/
		    # relative move via bspc (no option for absolute?)
		    #bspc node "\$name" -v -20 0
		    # absolute move via xdotool
		    xdotool windowmove "\$name" \$X_OFFSET "\$Y_OFFSET_ADJUSTED"
		  fi
		done
	EOF

  ### FULLSCREEN TOGGLE SCRIPT ###

	cat <<- EOF > "$FULLSCREEN_TOGGLE_SCRIPT"
		#! /usr/bin/env sh

		# This script is run by the button.

		PROGRAM="$BROWSER"

		# Set the browser to fullscreen
		for line in \$(bspc query -N -n .leaf | xargs -n 1 bspc query -T -n); do
		  if echo "\$line" | grep -q "\$PROGRAM"; then
		    # Switch out jq with cut or something, to not have that dependency?
		    # Find which one is the dropdown, isolate its ID, which annoyingly is in decimal, so convert it to hex with printf, then at 0x in front as bspc expects
		    name=0x"\$(printf "%x\n" \$(echo "\$line" | jq .id))"
		    bspc node "\$name" -t ~fullscreen # fullscreen. With ~ hopefully it toggles?
		    # OR toggle between monocle/tiling instead (not ideal I think because it monocles
		    # the currently selected window, which will be the keyboard if the keyboard
		    # was pressed most recently rather than the browser?)
		  fi
		done
	EOF

  ### BSPWM ADD BUTTON SCRIPT ###

	cat <<- EOF > "$BSPWM_ADD_BUTTON_SCRIPT"
		# It seems the correct one to target is what's output by xprop as the second
		# WM_CLASS entry! None of the others seem to work?
		# WM_CLASS(STRING) = "btn.py", "btn.py"

		bspc rule -a "$BUTTON_WINDOW_TITLE" state=floating layer=above
		$SCRIPTS_BASE_PATH/$BUTTON_SCRIPT &
		# Give the button a bit of time to appear before we move it
		sleep 5
		$SCRIPTS_BASE_PATH/$BUTTON_MOVE_SCRIPT &
	EOF

  # Set proper permissions on them all
  chown root:$CUSER -R .
  chmod g+rx ./*

  ### APPEND BSPWM ADD BUTTON SCRIPT TO BSPWMRC ###

  # Idempotency: Don't add the button multiple times on multiple runs
  if ! grep --quiet  "$BSPWM_ADD_BUTTON_SCRIPT" $BSPWM_CONFIG; then
    echo "$SCRIPTS_BASE_PATH/$BSPWM_ADD_BUTTON_SCRIPT &" >> "$BSPWM_CONFIG"
  fi
else # CLEANUP
  # apt-get purge -y xdotool jq
  sed -i "\,$BSPWM_ADD_BUTTON_SCRIPT,d" "$BSPWM_CONFIG"
fi
