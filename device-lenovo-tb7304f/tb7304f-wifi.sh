#!/bin/sh
# Brings up the Wi-Fi of the stock kernel. Its WMT driver is started by two
# Android programs of the stock firmware, which run here on the C library
# they came with (/system/bin/linker64 and /system/lib64). After that,
# writing 1 to /dev/wmtWifi creates wlan0, which NetworkManager takes over.

exec >> /var/log/tb7304f-wifi.log 2>&1
echo "== $(date)"

part() {
	for p in /sys/block/mmcblk0/mmcblk0p*; do
		if grep -q "^PARTNAME=$1\$" "$p/uevent"; then
			echo "/dev/${p##*/}"
			return
		fi
	done
}

CACHE=$(part cache)
mkdir -p /run/tb7304f-wifi-cache
cache() {
	mount -t ext4 "$CACHE" /run/tb7304f-wifi-cache || return 1
	"$@"
	rc=$?
	sync
	umount /run/tb7304f-wifi-cache
	return $rc
}

# The driver may take the kernel down. If the last attempt did not get to the
# end, leave it alone on this boot so that the tablet stays usable.
attempt_pending() {
	[ -e /run/tb7304f-wifi-cache/pmos-log/wifi-attempt ]
}
if cache attempt_pending; then
	echo "the last attempt did not finish, not trying on this boot"
	cache rm -f /run/tb7304f-wifi-cache/pmos-log/wifi-attempt
	exit 0
fi

# The driver reads its calibration from /data/nvram, which the installer
# saved from Android
restore_nvram() {
	[ -s /run/tb7304f-wifi-cache/pmos-backup/data-nvram.tar ] || return 0
	mkdir -p /data
	tar -x -f /run/tb7304f-wifi-cache/pmos-backup/data-nvram.tar -C /data
}
[ -d /data/nvram ] || cache restore_nvram
ls -l /data/nvram/APCFG/APRDEB 2>&1

# Where the kernel looks for firmware when it is not handed over by udev
mkdir -p /lib/firmware
for f in /vendor/firmware/*; do
	ln -sf "$f" "/lib/firmware/${f##*/}"
done

sleep 45
mark() {
	mkdir -p /run/tb7304f-wifi-cache/pmos-log
	touch /run/tb7304f-wifi-cache/pmos-log/wifi-attempt
}
cache mark

# wmt_launcher waits for a property that wmt_loader sets, and there is no
# Android property service here: this library, preloaded into the two, keeps
# the properties in files and sends their log to stderr
PRELOAD=/system/lib64/libtb7304f-props.so
mkdir -p /run/tb7304f-props

ls -l /dev/wmtdetect /dev/stpwmt /dev/wmtWifi 2>&1
echo "wmt_loader"
LD_PRELOAD=$PRELOAD /vendor/bin/wmt_loader
echo "wmt_loader: $?"
ls -l /dev/wmtdetect /dev/stpwmt /dev/wmtWifi 2>&1
grep . /run/tb7304f-props/* 2>&1
LD_PRELOAD=$PRELOAD /vendor/bin/wmt_launcher -p /vendor/firmware/ 2>&1 |
	grep -v "fwlog.status\|dynamic.dump" &
echo "wmt_launcher started"
sleep 8
echo 1 > /dev/wmtWifi
echo "wmtWifi: $?"
sleep 5
ip link 2>&1

# NetworkManager leaves a device alone until udev has announced it. udev is
# not running on this system (the kernel has no devtmpfs, mdev fills /dev),
# so it is started here for its database only and told about the network
# devices.
if ! pidof udevd > /dev/null; then
	udevd --daemon
	sleep 1
fi
udevadm trigger --type=devices --subsystem-match=net --action=add
udevadm settle --timeout=15
echo "udev: $?"
sleep 5
nmcli device 2>&1

cache rm -f /run/tb7304f-wifi-cache/pmos-log/wifi-attempt
echo "done"
wait
