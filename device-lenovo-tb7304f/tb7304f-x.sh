#!/bin/sh
# Starts Xorg on the framebuffer of the stock kernel and an Xfce session for
# the first user. The kernel has no virtual terminals, so the server runs on
# a seat of its own, which makes it leave them alone; there is no udev either,
# so the input devices are named here.

exec > /var/log/tb7304f-x.log 2>&1

# input <name>: the event node of the input device with that name
input() {
	for d in /sys/class/input/event*; do
		if [ "$(cat "$d/device/name" 2>/dev/null)" = "$1" ]; then
			echo "/dev/input/${d##*/}"
			return
		fi
	done
}

for i in $(seq 1 30); do
	[ -e /dev/fb0 ] && break
	sleep 0.5
done
ls -l /dev/fb0 /dev/input
for d in /sys/class/input/event*; do
	echo "${d##*/}: $(cat "$d/device/name" 2>/dev/null)"
done

TOUCH=$(input mtk-tpd)
KEYS=$(input mtk-kpd)
echo "touch=$TOUCH keys=$KEYS"

mkdir -p /etc/X11/xorg.conf.d
{
	cat <<EOF
Section "ServerFlags"
	Option "AutoAddDevices" "false"
	Option "AutoEnableDevices" "false"
	Option "DontVTSwitch" "true"
	Option "BlankTime" "0"
	Option "StandbyTime" "0"
	Option "SuspendTime" "0"
	Option "OffTime" "0"
EndSection

Section "Device"
	Identifier "framebuffer"
	Driver "fbdev"
	Option "fbdev" "/dev/fb0"
EndSection

Section "Screen"
	Identifier "screen"
	Device "framebuffer"
EndSection
EOF
	layout=""
	if [ -n "$TOUCH" ]; then
		cat <<EOF

Section "InputDevice"
	Identifier "touchscreen"
	Driver "evdev"
	Option "Device" "$TOUCH"
EndSection
EOF
		layout="$layout	InputDevice \"touchscreen\" \"CorePointer\"
"
	fi
	if [ -n "$KEYS" ]; then
		cat <<EOF

Section "InputDevice"
	Identifier "keys"
	Driver "evdev"
	Option "Device" "$KEYS"
EndSection
EOF
		layout="$layout	InputDevice \"keys\" \"CoreKeyboard\"
"
	fi
	cat <<EOF

Section "ServerLayout"
	Identifier "layout"
	Screen "screen"
$layout
EndSection
EOF
} > /etc/X11/xorg.conf.d/10-tb7304f.conf
cat /etc/X11/xorg.conf.d/10-tb7304f.conf

USER_NAME=$(awk -F: '$3 >= 10000 && $3 < 60000 { print $1; exit }' /etc/passwd)
USER_ID=$(id -u "$USER_NAME")
echo "user=$USER_NAME ($USER_ID)"
mkdir -p "/run/user/$USER_ID"
chown "$USER_NAME" "/run/user/$USER_ID"
chmod 700 "/run/user/$USER_ID"

cat > /run/tb7304f-session <<EOF
#!/bin/sh
xhost +SI:localuser:$USER_NAME
xset s off -dpms
exec su -l $USER_NAME -c 'export DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/$USER_ID; exec dbus-launch --exit-with-session startxfce4'
EOF
chmod 755 /run/tb7304f-session

exec xinit /run/tb7304f-session -- /usr/bin/Xorg :0 -seat seat1 -nolisten tcp -noreset -verbose 4
