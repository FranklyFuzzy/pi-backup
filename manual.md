## Step-by-Step Process

**1. Insert SD card into your Linux machine**

- Plug in the SD card reader with your Pi's SD card

**2. Find the device name**

```bash
lsblk
# or
sudo fdisk -l
```

Look for your SD card - it'll be something like `/dev/sdb` or `/dev/mmcblk0` (usually the one matching your card size like 64GB). **Make absolutely sure you have the right device** - using the wrong one could wipe your hard drive!

**3. Unmount the SD card (if auto-mounted)**

```bash
sudo umount /dev/sdb1
sudo umount /dev/sdb2
# (unmount any partitions that were mounted)
```

**4. Create the image**

```bash
# Create a backup directory first
mkdir ~/pi-backups
cd ~/pi-backups

# Create the image (this will take a while - maybe 30+ minutes for 64GB)
sudo dd if=/dev/sdb bs=4M status=progress of=adguard-backup.img

# Compress it
gzip adguard-backup.img
# This creates adguard-backup.img.gz
```

**5. Shrink the image**

```bash
# Download PiShrink
wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh
chmod +x pishrink.sh

# Decompress first (PiShrink needs the .img file, not .gz)
gunzip adguard-backup.img.gz

# Shrink it
sudo ./pishrink.sh adguard-backup.img

# Optionally compress again
gzip adguard-backup.img
```

**6. Remove the SD card safely**

```bash
sync
sudo eject /dev/sdb
```

Now you have a shrunken image that's only as big as your used space and can be restored to any SD card that's at least that size (or larger).

## To Restore Later:

```bash
gunzip adguard-backup.img.gz
sudo dd if=adguard-backup.img of=/dev/sdb bs=4M status=progress
sync
```

The partition will automatically expand to fill the new SD card on first boot.

Does this clarify the process?
