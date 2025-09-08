#!/bin/bash
# Live Disk Backup Script - Creates bootable images while system is running
# Uses partclone (Clonezilla's engine) for live disk imaging

# Configuration
BACKUP_DIR="/mnt/seagate/backups/crotchwarmer/live-disk-backups"
LOG_FILE="/var/log/live_disk_backup.log"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="live-disk-backup-$DATE"

echo "=== Live Disk Backup Started: $(date) ===" | tee -a "$LOG_FILE"
echo "Backup Name: $BACKUP_NAME" | tee -a "$LOG_FILE"

# Create backup directory
mkdir -p "$BACKUP_DIR/$BACKUP_NAME"

# Check if partclone is available
if ! command -v partclone.ext4 >/dev/null 2>&1; then
    echo "Installing partclone..." | tee -a "$LOG_FILE"
    sudo apt update && sudo apt install -y partclone
fi

# Get disk information
DISK="/dev/nvme0n1"
echo "Source Disk: $DISK" | tee -a "$LOG_FILE"

# Create disk layout info
sudo fdisk -l "$DISK" > "$BACKUP_DIR/$BACKUP_NAME/disk-layout.txt"
sudo lsblk "$DISK" >> "$BACKUP_DIR/$BACKUP_NAME/disk-layout.txt"

# Backup each partition
for partition in $(lsblk -ln -o NAME "$DISK" | grep -v "^$(basename "$DISK")$"); do
    PART_PATH="/dev/$partition"
    PART_TYPE=$(sudo blkid -o value -s TYPE "$PART_PATH" 2>/dev/null)
    
    echo "Backing up partition: $PART_PATH (Type: $PART_TYPE)" | tee -a "$LOG_FILE"
    
    if [ "$PART_TYPE" = "ext4" ]; then
        # Use partclone for ext4 partitions
        sudo partclone.ext4 -c -s "$PART_PATH" -o "$BACKUP_DIR/$BACKUP_NAME/${partition}.img" \
            --progress >> "$LOG_FILE" 2>&1
    elif [ "$PART_TYPE" = "vfat" ] || [ "$PART_TYPE" = "fat32" ]; then
        # Use partclone for FAT partitions
        sudo partclone.fat32 -c -s "$PART_PATH" -o "$BACKUP_DIR/$BACKUP_NAME/${partition}.img" \
            --progress >> "$LOG_FILE" 2>&1
    else
        # Use dd for other partition types
        echo "Using dd for partition type: $PART_TYPE" | tee -a "$LOG_FILE"
        sudo dd if="$PART_PATH" of="$BACKUP_DIR/$BACKUP_NAME/${partition}.img" bs=4M status=progress \
            >> "$LOG_FILE" 2>&1
    fi
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully backed up: $PART_PATH" | tee -a "$LOG_FILE"
    else
        echo "❌ Failed to backup: $PART_PATH" | tee -a "$LOG_FILE"
    fi
done

# Create system information
cat > "$BACKUP_DIR/$BACKUP_NAME/system-info.txt" << EOF
Live Disk Backup Information
==========================
Hostname: $(hostname)
Date: $(date)
Kernel: $(uname -r)
Uptime: $(uptime)

Disk Information:
$(sudo fdisk -l "$DISK")

Partition Layout:
$(sudo lsblk "$DISK")

Boot Information:
$(sudo efibootmgr -v 2>/dev/null || echo "EFI boot info not available")
EOF

# Create restoration script
cat > "$BACKUP_DIR/$BACKUP_NAME/restore.sh" << 'EOF'
#!/bin/bash
# Restoration script for live disk backup
# WARNING: This will overwrite the target disk!

if [ $# -ne 1 ]; then
    echo "Usage: $0 <target_disk>"
    echo "Example: $0 /dev/sda"
    echo "WARNING: This will overwrite the target disk!"
    exit 1
fi

TARGET_DISK="$1"
BACKUP_DIR="$(dirname "$0")"

echo "WARNING: This will overwrite $TARGET_DISK!"
echo "Press Ctrl+C to cancel, or Enter to continue..."
read

# Restore each partition
for img_file in "$BACKUP_DIR"/*.img; do
    if [ -f "$img_file" ]; then
        partition_name=$(basename "$img_file" .img)
        echo "Restoring partition: $partition_name"
        
        if [[ "$img_file" == *".ext4.img" ]]; then
            sudo partclone.ext4 -r -s "$img_file" -o "/dev/${partition_name}"
        elif [[ "$img_file" == *".fat32.img" ]]; then
            sudo partclone.fat32 -r -s "$img_file" -o "/dev/${partition_name}"
        else
            sudo dd if="$img_file" of="/dev/${partition_name}" bs=4M status=progress
        fi
    fi
done

echo "Restoration completed!"
EOF

chmod +x "$BACKUP_DIR/$BACKUP_NAME/restore.sh"

# Create checksums
echo "Creating checksums..." | tee -a "$LOG_FILE"
find "$BACKUP_DIR/$BACKUP_NAME" -name "*.img" -exec sha256sum {} \; > "$BACKUP_DIR/$BACKUP_NAME/checksums.sha256"

# Compress backup
echo "Compressing backup..." | tee -a "$LOG_FILE"
cd "$BACKUP_DIR"
tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME"
if [ $? -eq 0 ]; then
    echo "✅ Backup compressed successfully" | tee -a "$LOG_FILE"
    rm -rf "$BACKUP_NAME"
    BACKUP_FILE="$BACKUP_NAME.tar.gz"
else
    echo "❌ Backup compression failed" | tee -a "$LOG_FILE"
    BACKUP_FILE="$BACKUP_NAME"
fi

# Update latest backup symlink
ln -sf "$BACKUP_FILE" "$BACKUP_DIR/latest-disk-backup"

# Cleanup old backups (keep last 3 days for disk backups - they're large)
echo "Cleaning up old backups..." | tee -a "$LOG_FILE"
find "$BACKUP_DIR" -name "live-disk-backup-*" -type f -mtime +3 -delete
find "$BACKUP_DIR" -name "live-disk-backup-*" -type d -mtime +3 -exec rm -rf {} \;

# Final status
BACKUP_SIZE=$(du -sh "$BACKUP_DIR/$BACKUP_FILE" 2>/dev/null | cut -f1 || echo "Unknown")
echo "=== Live Disk Backup Completed: $(date) ===" | tee -a "$LOG_FILE"
echo "Backup File: $BACKUP_FILE" | tee -a "$LOG_FILE"
echo "Backup Size: $BACKUP_SIZE" | tee -a "$LOG_FILE"
echo "Location: $BACKUP_DIR/$BACKUP_FILE" | tee -a "$LOG_FILE"

exit 0
