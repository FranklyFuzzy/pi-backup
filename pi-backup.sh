#!/bin/bash

# Pi Configuration Backup Script
# Backs up AdGuard Home and PiAware configurations

# Configuration
BACKUP_BASE="/mnt/backup"  # Change this to your NAS/USB mount point
HOSTNAME=$(hostname)
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${BACKUP_BASE}/${HOSTNAME}_${DATE}"
KEEP_BACKUPS=10  # Number of backups to keep

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if backup directory is accessible
if [ ! -d "$BACKUP_BASE" ]; then
    log_error "Backup directory $BACKUP_BASE does not exist or is not mounted!"
    log_error "Please create the directory or mount your NAS/USB drive first."
    exit 1
fi

# Create backup directory
log_info "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Backup AdGuard Home (if installed)
if [ -d "/opt/AdGuardHome" ]; then
    log_info "Backing up AdGuard Home configuration..."
    sudo tar -czf "${BACKUP_DIR}/adguard_config.tar.gz" \
        -C /opt AdGuardHome/ \
        2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_info "AdGuard Home backup completed"
    else
        log_error "AdGuard Home backup failed"
    fi
else
    log_warn "AdGuard Home not found at /opt/AdGuardHome, skipping..."
fi

# Backup PiAware configuration (if installed)
if [ -f "/boot/piaware-config.txt" ]; then
    log_info "Backing up PiAware configuration..."
    sudo cp /boot/piaware-config.txt "${BACKUP_DIR}/piaware-config.txt"
    
    # Also backup dump1090 config if it exists
    if [ -f "/boot/dump1090-fa-config.txt" ]; then
        sudo cp /boot/dump1090-fa-config.txt "${BACKUP_DIR}/dump1090-fa-config.txt"
    fi
    
    log_info "PiAware backup completed"
else
    log_warn "PiAware config not found, skipping..."
fi

# Backup system network configuration (useful for static IPs)
if [ -f "/etc/dhcpcd.conf" ]; then
    log_info "Backing up network configuration..."
    sudo cp /etc/dhcpcd.conf "${BACKUP_DIR}/dhcpcd.conf"
fi

# Create a README with system info
log_info "Creating backup metadata..."
cat > "${BACKUP_DIR}/README.txt" << EOF
Backup Information
==================
Hostname: $HOSTNAME
Date: $(date)
OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
Kernel: $(uname -r)

Contents:
EOF

ls -lh "$BACKUP_DIR" >> "${BACKUP_DIR}/README.txt"

# Set permissions
sudo chmod -R 644 "${BACKUP_DIR}"/*
sudo chmod 755 "${BACKUP_DIR}"

log_info "Backup completed successfully at: $BACKUP_DIR"

# Cleanup old backups
log_info "Cleaning up old backups (keeping last $KEEP_BACKUPS)..."
cd "$BACKUP_BASE"
ls -dt ${HOSTNAME}_* 2>/dev/null | tail -n +$((KEEP_BACKUPS + 1)) | xargs rm -rf 2>/dev/null

if [ $? -eq 0 ]; then
    log_info "Cleanup completed"
else
    log_warn "No old backups to clean up"
fi

log_info "All done!"
