# Raspberry Pi Configuration Backup Script

A simple bash script to backup configuration files for AdGuard Home and PiAware installations on Raspberry Pi. Designed to prevent data loss from SD card failures.

## Features

- Backs up AdGuard Home configuration and data
- Backs up PiAware configuration files
- Backs up network configuration (static IP settings)
- Creates timestamped backups with system metadata
- Automatic cleanup of old backups (configurable retention)
- Color-coded console output
- Works with NAS, USB drives, or local storage

## What Gets Backed Up

### AdGuard Home
- `/opt/AdGuardHome/` - Complete configuration directory including:
  - `AdGuardHome.yaml` - Main configuration file
  - Filter lists and custom rules
  - Query logs and statistics (if enabled)
  - User settings and blocklists

### PiAware
- `/boot/piaware-config.txt` - PiAware configuration
- `/boot/dump1090-fa-config.txt` - dump1090 configuration (if present)

### System
- `/etc/dhcpcd.conf` - Network configuration (static IP settings)
- System metadata (hostname, OS version, kernel, backup timestamp)

## Installation

### 1. Download the Script

```bash
# Clone the repository
git clone https://github.com/FranklyFuzzy/pi-backup.git
cd pi-backup

# Make the script executable
chmod +x pi-backup.sh

# Copy to system location (optional but recommended)
sudo cp pi-backup.sh /usr/local/bin/pi-backup.sh
```

### 2. Configure Backup Destination

Edit the script and modify the `BACKUP_BASE` variable (line 7):

```bash
sudo nano /usr/local/bin/pi-backup.sh
```

**Options:**

- **NAS (Network Attached Storage):**
  ```bash
  BACKUP_BASE="/mnt/nas"
  ```

- **USB Drive:**
  ```bash
  BACKUP_BASE="/mnt/usb"
  ```

- **Local Directory (for testing):**
  ```bash
  BACKUP_BASE="/home/pi/backups"
  ```

### 3. Configure Backup Retention (Optional)

Change the number of backups to keep (default is 10):

```bash
KEEP_BACKUPS=10  # Line 10 in the script
```

## Setting Up Storage

### Option A: NAS via NFS

```bash
# Create mount point
sudo mkdir -p /mnt/nas

# Test mount
sudo mount -t nfs 192.168.1.x:/backups /mnt/nas

# Make permanent - add to /etc/fstab
echo "192.168.1.x:/backups /mnt/nas nfs defaults 0 0" | sudo tee -a /etc/fstab
```

### Option B: NAS via SMB/CIFS

```bash
# Install CIFS utilities
sudo apt-get install cifs-utils

# Create mount point
sudo mkdir -p /mnt/nas

# Create credentials file
sudo nano /root/.smbcredentials
```

Add to credentials file:
```
username=your_username
password=your_password
```

```bash
# Secure the credentials file
sudo chmod 600 /root/.smbcredentials

# Add to /etc/fstab
echo "//192.168.1.x/backups /mnt/nas cifs credentials=/root/.smbcredentials,iocharset=utf8 0 0" | sudo tee -a /etc/fstab

# Mount
sudo mount -a
```

### Option C: USB Drive

```bash
# Find your USB drive
lsblk

# Create mount point
sudo mkdir -p /mnt/usb

# Mount manually (assuming /dev/sda1)
sudo mount /dev/sda1 /mnt/usb

# Make permanent - add to /etc/fstab (get UUID first)
sudo blkid /dev/sda1
# Copy the UUID value

# Add to /etc/fstab (replace YOUR-UUID)
echo "UUID=YOUR-UUID /mnt/usb ext4 defaults 0 0" | sudo tee -a /etc/fstab
```

## Usage

### Manual Backup

Run the script manually anytime:

```bash
sudo /usr/local/bin/pi-backup.sh
```

You should see output like:
```
[INFO] Creating backup directory: /mnt/nas/raspberrypi_20250117_143022
[INFO] Backing up AdGuard Home configuration...
[INFO] AdGuard Home backup completed
[INFO] Backing up PiAware configuration...
[INFO] PiAware backup completed
[INFO] Backing up network configuration...
[INFO] Creating backup metadata...
[INFO] Backup completed successfully at: /mnt/nas/raspberrypi_20250117_143022
[INFO] Cleaning up old backups (keeping last 10)...
[INFO] All done!
```

### Automated Backups with Cron

Set up automatic scheduled backups:

```bash
sudo crontab -e
```

**Weekly backups (Sundays at 2 AM):**
```
0 2 * * 0 /usr/local/bin/pi-backup.sh >> /var/log/pi-backup.log 2>&1
```

**Daily backups (3 AM):**
```
0 3 * * * /usr/local/bin/pi-backup.sh >> /var/log/pi-backup.log 2>&1
```

**Monthly backups (1st of month at 2 AM):**
```
0 2 1 * * /usr/local/bin/pi-backup.sh >> /var/log/pi-backup.log 2>&1
```

View backup logs:
```bash
tail -f /var/log/pi-backup.log
```

## Backup Structure

Each backup creates a timestamped directory:

```
/mnt/nas/
├── raspberrypi_20250117_143022/
│   ├── adguard_config.tar.gz
│   ├── piaware-config.txt
│   ├── dump1090-fa-config.txt
│   ├── dhcpcd.conf
│   └── README.txt
├── raspberrypi_20250116_020001/
│   └── ...
└── raspberrypi_20250115_020001/
    └── ...
```

The `README.txt` file contains:
- Hostname
- Backup date/time
- OS version
- Kernel version
- List of backed up files

## Restoring from Backup

### Scenario 1: Fresh SD Card Installation

1. **Flash fresh OS to new SD card**
   - AdGuard Home: Use official Raspberry Pi OS
   - PiAware: Use PiAware SD card image

2. **Install base software** (if needed)
   ```bash
   # For AdGuard Home
   curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v
   ```

3. **Restore configurations** (see below)

### Restoring AdGuard Home

```bash
# Stop AdGuard Home service
sudo systemctl stop AdGuardHome

# Remove existing config (optional - backup first if uncertain)
sudo rm -rf /opt/AdGuardHome/*

# Extract backup (replace with your backup path)
sudo tar -xzf /mnt/nas/raspberrypi_20250117_143022/adguard_config.tar.gz -C /opt/

# Fix permissions
sudo chown -R adguardhome:adguardhome /opt/AdGuardHome

# Start AdGuard Home
sudo systemctl start AdGuardHome

# Verify it's working
sudo systemctl status AdGuardHome
```

### Restoring PiAware

```bash
# Copy config file to boot partition
sudo cp /mnt/nas/raspberrypi_20250117_143022/piaware-config.txt /boot/

# If dump1090 config exists
sudo cp /mnt/nas/raspberrypi_20250117_143022/dump1090-fa-config.txt /boot/

# Reboot to apply changes
sudo reboot
```

### Restoring Network Configuration

```bash
# Restore DHCP/static IP configuration
sudo cp /mnt/nas/raspberrypi_20250117_143022/dhcpcd.conf /etc/dhcpcd.conf

# Restart networking
sudo systemctl restart dhcpcd

# Or reboot
sudo reboot
```

### Quick Restore Script

For convenience, you can create a restore script:

```bash
#!/bin/bash
BACKUP_PATH="$1"

if [ -z "$BACKUP_PATH" ]; then
    echo "Usage: $0 /path/to/backup/directory"
    exit 1
fi

# Restore AdGuard Home
if [ -f "$BACKUP_PATH/adguard_config.tar.gz" ]; then
    echo "Restoring AdGuard Home..."
    sudo systemctl stop AdGuardHome
    sudo tar -xzf "$BACKUP_PATH/adguard_config.tar.gz" -C /opt/
    sudo chown -R adguardhome:adguardhome /opt/AdGuardHome
    sudo systemctl start AdGuardHome
fi

# Restore PiAware
if [ -f "$BACKUP_PATH/piaware-config.txt" ]; then
    echo "Restoring PiAware..."
    sudo cp "$BACKUP_PATH/piaware-config.txt" /boot/
    [ -f "$BACKUP_PATH/dump1090-fa-config.txt" ] && sudo cp "$BACKUP_PATH/dump1090-fa-config.txt" /boot/
fi

# Restore network config
if [ -f "$BACKUP_PATH/dhcpcd.conf" ]; then
    echo "Restoring network configuration..."
    sudo cp "$BACKUP_PATH/dhcpcd.conf" /etc/dhcpcd.conf
fi

echo "Restore complete! Reboot recommended."
```

## Troubleshooting

### Backup directory not found
```
[ERROR] Backup directory /mnt/nas does not exist or is not mounted!
```
**Solution:** Ensure your NAS/USB drive is mounted. Check with `df -h` or `mount | grep /mnt/nas`

### Permission denied
```
[ERROR] AdGuard Home backup failed
```
**Solution:** Run the script with `sudo`

### No old backups to clean up
This is normal if you have fewer backups than the retention limit.

### Backup takes up too much space
- AdGuard Home backups can be large if query logs are enabled
- Consider disabling query log retention in AdGuard or reducing retention days
- Adjust `KEEP_BACKUPS` to keep fewer historical backups

## Best Practices

1. **Test your backups regularly** - Do a test restore on a spare SD card
2. **Store backups off-site** - Use a NAS or cloud storage for redundancy
3. **Monitor backup logs** - Check `/var/log/pi-backup.log` periodically
4. **Keep multiple backup destinations** - Consider backing up to both NAS and USB
5. **Full image backup** - Do a complete SD card image backup when first configured (use `dd` + `pishrink`)

## Security Notes

- Backup files contain sensitive configuration including DNS settings and potentially custom blocklists
- Secure your backup destination with appropriate permissions
- If backing up to SMB/CIFS, use the credentials file method (not inline passwords)
- Consider encrypting backups if stored on untrusted storage

## License

MIT License - Feel free to modify and distribute

## Contributing

Pull requests welcome! Please test thoroughly before submitting.

## Support

For issues or questions:
- Open an issue on GitHub
- Check AdGuard Home docs: https://github.com/AdguardTeam/AdGuardHome
- Check PiAware docs: https://flightaware.com/adsb/piaware/

---

**Remember:** Backups are only useful if you test them! Do a practice restore to make sure everything works.
