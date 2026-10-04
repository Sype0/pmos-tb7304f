#!/bin/sh
# Copies the logs of this boot to pmos-log on the cache partition, where the
# recovery can read them. Runs a few times while the system comes up.

part() {
	for p in /sys/block/mmcblk0/mmcblk0p*; do
		if grep -q "^PARTNAME=$1\$" "$p/uevent"; then
			echo "/dev/${p##*/}"
			return
		fi
	done
}

CACHE=$(part cache)
[ -b "$CACHE" ] || exit 0
mkdir -p /run/tb7304f-cache

for delay in 5 15 30 60 120 300; do
	sleep "$delay"
	mount -t ext4 "$CACHE" /run/tb7304f-cache || continue
	out=/run/tb7304f-cache/pmos-log
	mkdir -p "$out"
	dmesg > "$out/dmesg.txt"
	ps -ef > "$out/ps.txt" 2>&1
	rc-status -a > "$out/rc-status.txt" 2>&1
	ls -l /dev /dev/input > "$out/dev.txt" 2>&1
	ip addr > "$out/ip.txt" 2>&1
	cat /proc/mounts > "$out/mounts.txt"
	for f in /var/log/messages /var/log/Xorg.0.log /var/log/tb7304f-x.log /var/log/tb7304f-wifi.log /var/log/rc.log; do
		[ -f "$f" ] && cp "$f" "$out/"
	done
	sync
	umount /run/tb7304f-cache
done
