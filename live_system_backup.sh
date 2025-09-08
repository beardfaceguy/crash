#!/bin/bash
# Live System Backup Script for Cron
# Creates incremental backups while system is running

# Configuration
BACKUP_DIR="/mnt/seagate/backups/crotchwarmer/live-backups"
LOG_FILE="/var/log/live_backup.log"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="live-backup-$DATE"

# Source directories to backup
SOURCE_DIRS=(
    "/etc"
    "/home"
    "/opt"
    "/usr/local"
    "/var/log"
    "/var/spool/cron"
    "/root"
)

# Exclude patterns
EXCLUDE_PATTERNS=(
    "--exclude=/home/*/.cache"
    "--exclude=/home/*/.tmp"
    "--exclude=/home/*/Downloads"
    "--exclude=/var/log/*.log.*"
    "--exclude=/var/log/*.gz"
    "--exclude=/tmp"
    "--exclude=/proc"
    "--exclude=/sys"
    "--exclude=/dev"
    "--exclude=/run"
    "--exclude=/mnt"
    "--exclude=/media"
)

echo "=== Live System Backup Started: $(date) ===" | tee -a "$LOG_FILE"
echo "Backup Name: $BACKUP_NAME" | tee -a "$LOG_FILE"
echo "Backup Directory: $BACKUP_DIR" | tee -a "$LOG_FILE"

# Create backup directory
mkdir -p "$BACKUP_DIR/$BACKUP_NAME"

# Check available space
AVAILABLE_SPACE=$(df "$BACKUP_DIR" | tail -1 | awk '{print $4}')
REQUIRED_SPACE=10000000  # 10GB in KB
echo "Available space: $(($AVAILABLE_SPACE / 1024 / 1024)) GB" | tee -a "$LOG_FILE"

if [ $AVAILABLE_SPACE -lt $REQUIRED_SPACE ]; then
    echo "ERROR: Insufficient space on backup drive" | tee -a "$LOG_FILE"
    echo "Available: $(($AVAILABLE_SPACE / 1024 / 1024)) GB" | tee -a "$LOG_FILE"
    echo "Required: 10 GB" | tee -a "$LOG_FILE"
    exit 1
fi

# Create system information file
cat > "$BACKUP_DIR/$BACKUP_NAME/system-info.txt" << EOF
Live System Backup Information
=============================
Hostname: $(hostname)
Date: $(date)
Kernel: $(uname -r)
Uptime: $(uptime)
Disk Usage: $(df -h /)
Memory Usage: $(free -h)
Network: $(ip addr show | grep -E "inet [0-9]" | head -3)

Installed Packages:
$(dpkg -l | wc -l) packages installed

System Services:
$(systemctl list-units --type=service --state=running | wc -l) services running

Partition Layout:
$(lsblk)
EOF

# Backup each directory
for dir in "${SOURCE_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "Backing up: $dir" | tee -a "$LOG_FILE"
        rsync -av --progress \
            "${EXCLUDE_PATTERNS[@]}" \
            "$dir/" \
            "$BACKUP_DIR/$BACKUP_NAME$(dirname "$dir")/" \
            >> "$LOG_FILE" 2>&1
        
        if [ $? -eq 0 ]; then
            echo "✅ Successfully backed up: $dir" | tee -a "$LOG_FILE"
        else
            echo "❌ Failed to backup: $dir" | tee -a "$LOG_FILE"
        fi
    else
        echo "⚠️  Directory not found: $dir" | tee -a "$LOG_FILE"
    fi
done

# Create package list
echo "Creating package list..." | tee -a "$LOG_FILE"
dpkg -l > "$BACKUP_DIR/$BACKUP_NAME/installed-packages.txt" 2>/dev/null

# Create cron jobs backup
echo "Backing up cron jobs..." | tee -a "$LOG_FILE"
mkdir -p "$BACKUP_DIR/$BACKUP_NAME/cron-backups"
crontab -l > "$BACKUP_DIR/$BACKUP_NAME/cron-backups/user-crontab.txt" 2>/dev/null
sudo crontab -l > "$BACKUP_DIR/$BACKUP_NAME/cron-backups/root-crontab.txt" 2>/dev/null
cp -r /etc/cron.* "$BACKUP_DIR/$BACKUP_NAME/cron-backups/" 2>/dev/null

# Create backup manifest
echo "Creating backup manifest..." | tee -a "$LOG_FILE"
find "$BACKUP_DIR/$BACKUP_NAME" -type f | wc -l > "$BACKUP_DIR/$BACKUP_NAME/manifest-count.txt"
du -sh "$BACKUP_DIR/$BACKUP_NAME" > "$BACKUP_DIR/$BACKUP_NAME/manifest-size.txt"

# Create checksum
echo "Creating checksum..." | tee -a "$LOG_FILE"
find "$BACKUP_DIR/$BACKUP_NAME" -type f -exec sha256sum {} \; > "$BACKUP_DIR/$BACKUP_NAME/checksums.sha256"

# Compress backup (optional - comment out if you want uncompressed)
echo "Compressing backup..." | tee -a "$LOG_FILE"
cd "$BACKUP_DIR"
tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME"
if [ $? -eq 0 ]; then
    echo "✅ Backup compressed successfully" | tee -a "$LOG_FILE"
    # Remove uncompressed directory to save space
    rm -rf "$BACKUP_NAME"
    BACKUP_FILE="$BACKUP_NAME.tar.gz"
else
    echo "❌ Backup compression failed" | tee -a "$LOG_FILE"
    BACKUP_FILE="$BACKUP_NAME"
fi

# Update latest backup symlink
ln -sf "$BACKUP_FILE" "$BACKUP_DIR/latest-backup"

# Cleanup old backups (keep last 7 days)
echo "Cleaning up old backups..." | tee -a "$LOG_FILE"
find "$BACKUP_DIR" -name "live-backup-*" -type f -mtime +7 -delete
find "$BACKUP_DIR" -name "live-backup-*" -type d -mtime +7 -exec rm -rf {} \;

# Final status
BACKUP_SIZE=$(du -sh "$BACKUP_DIR/$BACKUP_FILE" 2>/dev/null | cut -f1 || echo "Unknown")
echo "=== Live System Backup Completed: $(date) ===" | tee -a "$LOG_FILE"
echo "Backup File: $BACKUP_FILE" | tee -a "$LOG_FILE"
echo "Backup Size: $BACKUP_SIZE" | tee -a "$LOG_FILE"
echo "Location: $BACKUP_DIR/$BACKUP_FILE" | tee -a "$LOG_FILE"

# Send notification (if email is configured)
if command -v mail >/dev/null 2>&1; then
    echo "Live backup completed successfully. Size: $BACKUP_SIZE" | mail -s "Backup Complete - $(hostname)" root
fi

exit 0
