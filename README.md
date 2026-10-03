# postmarketOS for Lenovo Tab 7 Essential (TB-7304F)

Work in progress, nothing here is tested on the device yet.

MediaTek MT8167, 600x1024. Uses the stock 4.4.22 kernel from
`TB-7304F_S100017_200102_ROW` as a prebuilt, because there is no kernel source
for this board and the Wi-Fi (WMT) driver only exists downstream. That kernel
has no devtmpfs, so `tools/patch-initramfs.py` makes the postmarketOS initramfs
fall back to a tmpfs filled by mdev.

The GitHub Actions workflow builds `boot.img` and `rootfs.img.xz` with
pmbootstrap.
