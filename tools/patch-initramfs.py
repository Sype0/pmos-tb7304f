#!/usr/bin/env python3
"""Make the postmarketOS initramfs work on a kernel without CONFIG_DEVTMPFS.

Usage: patch-initramfs.py <pmaports>/main/postmarketos-initramfs
"""
import re
import sys

pkg = sys.argv[1]

path = pkg + '/init_functions.sh'
src = open(path).read()
old = '\tmount -t devtmpfs -o mode=0755,nosuid dev /dev || echo "Couldn\'t mount /dev"\n'
new = '''\tif ! mount -t devtmpfs -o mode=0755,nosuid dev /dev; then
\t\t# No devtmpfs in this kernel: mdev fills a tmpfs instead
\t\tmount -t tmpfs -o mode=0755,nosuid dev /dev
\t\tmknod -m 600 /dev/console c 5 1
\t\tmknod -m 666 /dev/null c 1 3
\t\tmknod -m 644 /dev/kmsg c 1 11
\t\tmdev -s
\tfi
'''
if old not in src:
    sys.exit('devtmpfs mount line not found in init_functions.sh')
open(path, 'w').write(src.replace(old, new))

path = pkg + '/APKBUILD'
src = open(path).read()
src, n = re.subn(r'^pkgrel=(\d+)$', lambda m: 'pkgrel=%d' % (int(m.group(1)) + 100), src, flags=re.M)
if n != 1:
    sys.exit('pkgrel not found in APKBUILD')
open(path, 'w').write(src)
