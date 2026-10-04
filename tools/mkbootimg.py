#!/usr/bin/env python3
"""Put an Android boot image (header version 0) together.

Usage: mkbootimg.py <kernel> <ramdisk> <out.img> <cmdline>
The addresses are the ones of the Lenovo TB-7304F.
"""
import hashlib
import struct
import sys

PAGE = 2048
BASE = 0x40078000
KERNEL_ADDR = BASE + 0x00008000
RAMDISK_ADDR = BASE + 0x04488000
SECOND_ADDR = BASE + 0x00f00000
TAGS_ADDR = BASE + 0x0df88000


def pad(data):
    return data + b'\0' * (-len(data) % PAGE)


def main():
    kernel = open(sys.argv[1], 'rb').read()
    ramdisk = open(sys.argv[2], 'rb').read()
    cmdline = sys.argv[4].encode()
    if len(cmdline) > 511:
        sys.exit('the command line is too long')

    sha = hashlib.sha1()
    for part in (kernel, ramdisk, b''):
        sha.update(part)
        sha.update(struct.pack('<I', len(part)))
    image_id = sha.digest().ljust(32, b'\0')

    header = struct.pack('<8s10I16s512s32s1024s', b'ANDROID!',
                         len(kernel), KERNEL_ADDR, len(ramdisk), RAMDISK_ADDR,
                         0, SECOND_ADDR, TAGS_ADDR, PAGE, 0, 0,
                         b'', cmdline, image_id, b'')
    with open(sys.argv[3], 'wb') as out:
        out.write(pad(header))
        out.write(pad(kernel))
        out.write(pad(ramdisk))


if __name__ == '__main__':
    main()
