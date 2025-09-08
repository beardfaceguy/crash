#!/bin/bash
# System Image Creation Script for Clonezilla Live
# Run this script after booting from Clonezilla Live USB

echo "=== System Image Creation Script ==="
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo ""

# Set variables
SOURCE_DEVICE="/dev/nvme0n1"
BACKUP_DIR="/mnt/seagate/backups/crotchwarmer"
IMAGE_NAME="system-image-$(date +%Y%m%d-%H%M%S).img"
IMAGE_PATH="$BACKUP_DIR/$IMAGE_NAME"

echo "Source Device: $SOURCE_DEVICE"
echo "Backup Directory: $BACKUP_DIR"
echo "Image Name: $IMAGE_NAME"
echo "Full Path: $IMAGE_PATH"
echo ""

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
fi

# Check available space
AVAILABLE_SPACE=$(df "$BACKUP_DIR" | tail -1 | awk '{print $4}')
REQUIRED_SPACE=500000000  # 500GB in KB
echo "Available space: $(($AVAILABLE_SPACE / 1024 / 1024)) GB"
echo "Required space: ~500 GB"
echo ""

if [ $AVAILABLE_SPACE -lt $REQUIRED_SPACE ]; then
    echo "ERROR: Insufficient space on backup drive"
    echo "Available: $(($AVAILABLE_SPACE / 1024 / 1024)) GB"
    echo "Required: ~500 GB"
    exit 1
fi

echo "Starting system image creation..."
echo "This will take several hours for a 476GB drive"
echo ""

# Create the system image using dd
echo "Creating system image: $IMAGE_PATH"
sudo dd if="$SOURCE_DEVICE" of="$IMAGE_PATH" bs=4M status=progress

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ System image created successfully!"
    echo "Image: $IMAGE_PATH"
    echo "Size: $(du -h "$IMAGE_PATH" | cut -f1)"
    
    # Create checksum for verification
    echo "Creating SHA256 checksum..."
    sha256sum "$IMAGE_PATH" > "$IMAGE_PATH.sha256"
    echo "Checksum saved to: $IMAGE_PATH.sha256"
    
    # Create info file
    cat > "$IMAGE_PATH.info" << EOF
System Image Information
=======================
Hostname: $(hostname)
Created: $(date)
Source Device: $SOURCE_DEVICE
Image Size: $(du -h "$IMAGE_PATH" | cut -f1)
SHA256: $(cat "$IMAGE_PATH.sha256" | cut -d' ' -f1)

Source Device Info:
$(sudo fdisk -l "$SOURCE_DEVICE")

Partition Layout:
$(sudo lsblk "$SOURCE_DEVICE")
EOF
    
    echo "Info file saved to: $IMAGE_PATH.info"
    echo ""
    echo "🎉 System image creation completed successfully!"
    
else
    echo "❌ ERROR: System image creation failed"
    exit 1
fi
