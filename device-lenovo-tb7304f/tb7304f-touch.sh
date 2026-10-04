#!/bin/sh
# Makes the Xfce session usable with fingers on the 7" 600x1024 panel: larger
# text and controls, single tap to open, and an on-screen keyboard that shows
# up when a text field gets the focus. Runs at the start of every session;
# the settings are only applied once, so that they can be changed afterwards.

MARK="$HOME/.config/tb7304f-touch-2"

if [ ! -e "$MARK" ]; then
	mkdir -p "$HOME/.config"

	set_prop() {
		xfconf-query -c "$1" -p "$2" -n -t "$3" -s "$4"
	}

	# Text and controls
	set_prop xsettings /Xft/DPI int 132
	set_prop xsettings /Gtk/FontName string "Sans 11"
	set_prop xsettings /Gtk/CursorThemeSize int 32
	set_prop xsettings /Gtk/ToolbarIconSize int 3
	set_prop xsettings /Net/DndDragThreshold int 24
	set_prop xsettings /Net/DoubleClickDistance int 24

	# Window decorations with buttons that a finger can hit; no compositing,
	# there is no GPU to do it
	set_prop xfwm4 /general/theme string Default-xhdpi
	set_prop xfwm4 /general/title_font string "Sans Bold 11"
	set_prop xfwm4 /general/use_compositing bool false
	set_prop xfwm4 /general/snap_to_border bool true
	set_prop xfwm4 /general/borderless_maximize bool true

	# Panels
	set_prop xfce4-panel /panels/panel-1/size uint 44
	set_prop xfce4-panel /panels/panel-1/icon-size uint 28
	set_prop xfce4-panel /panels/panel-2/size uint 56
	set_prop xfce4-panel /panels/panel-2/icon-size uint 40

	# One tap opens things
	set_prop xfce4-desktop /desktop-icons/single-click bool true
	set_prop xfce4-desktop /desktop-icons/icon-size uint 64
	set_prop thunar /misc-single-click bool true

	# On-screen keyboard: docked to the bottom, shown when text is edited
	gsettings set org.gnome.desktop.interface toolkit-accessibility true
	gsettings set org.onboard.auto-show enabled true
	gsettings set org.onboard.window docking-enabled true
	gsettings set org.onboard.window.landscape dock-height 260
	gsettings set org.onboard.window.portrait dock-height 300
	gsettings set org.onboard layout Compact
	gsettings set org.onboard start-minimized true
	gsettings set org.onboard show-status-icon true
	gsettings set org.onboard.icon-palette in-use true

	touch "$MARK"
fi

exec onboard
