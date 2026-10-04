# postmarketOS for Lenovo Tab 7 Essential (TB-7304F)

Work in progress, nothing here is tested on the device yet.

MediaTek MT8167, 600x1024. Uses the stock 4.4.22 kernel from
`TB-7304F_S100017_200102_ROW` as a prebuilt, because there is no kernel source
for this board and the Wi-Fi (WMT) driver only exists downstream.

That kernel has neither devtmpfs nor virtual terminals, which the
postmarketOS initramfs and its user interfaces build on. So:

- `initramfs/init` replaces the postmarketOS initramfs. It fills `/dev` with
  mdev, mounts the root filesystem from `userdata` and saves the kernel log to
  `pmos-log` on the `cache` partition. If there is no root filesystem it
  reboots to the recovery.
- The root filesystem is a regular postmarketOS installation (OpenRC). mdev
  keeps `/dev` up to date in place of udev.
- The display is the framebuffer of the stock kernel: Xorg with the fbdev
  driver on a seat of its own (no virtual terminals), with an Xfce session.
  There is no GPU acceleration.
- The logs of every boot are copied to `pmos-log` on `cache`, where the
  recovery can read them.

The GitHub Actions workflow builds the root filesystem with pmbootstrap and
puts the boot image and a TWRP flashable zip together.

## Installing

The zip overwrites `userdata` (all Android data) and `boot`. Before that it
saves stock `boot`, `nvram`, `proinfo` and `/data/nvram` to `/cache/pmos-backup`
(and to the microSD card if there is one). The zip must not be on internal
storage, so sideload it or put it on a microSD card:

```
adb sideload postmarketos-lenovo-tb7304f-twrp.zip
```

The user is `user` with the password `147147`; the session starts without a
login.

To go back to Android, write `stock-boot.img` back to `boot` and format data in
TWRP.
