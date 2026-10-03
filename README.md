# postmarketOS for Lenovo Tab 7 Essential (TB-7304F)

Work in progress, nothing here is tested on the device yet.

MediaTek MT8167, 600x1024. Uses the stock 4.4.22 kernel from
`TB-7304F_S100017_200102_ROW` as a prebuilt, because there is no kernel source
for this board and the Wi-Fi (WMT) driver only exists downstream. That kernel
has no devtmpfs, so `tools/patch-initramfs.py` makes the postmarketOS initramfs
fall back to a tmpfs filled by mdev.

The GitHub Actions workflow builds the image with pmbootstrap and publishes
`boot.img` and a TWRP flashable zip as a pre-release.

## Installing

The zip overwrites `userdata` (all Android data) and `boot`. Before that it
saves stock `boot`, `nvram`, `proinfo` and `/data/nvram` to `/cache/pmos-backup`
(and to the microSD card if there is one). The zip must not be on internal
storage, so sideload it or put it on a microSD card:

```
adb sideload postmarketos-lenovo-tb7304f-twrp.zip
```

Login is `user` / `147147`. There is no graphical interface yet and the stock
kernel has no framebuffer console, access is over USB networking (SSH).

To go back to Android, write `stock-boot.img` back to `boot` and format data in
TWRP.
