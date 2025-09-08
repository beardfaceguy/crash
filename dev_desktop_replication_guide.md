# Dev Desktop Disaster Recovery Setup Guide

**For**: Dev Desktop Machine  
**Date**: September 7, 2025  
**Based on**: crotchwarmer setup  

## Prerequisites
- USB drive (8GB+ recommended)
- Access to Seagate network drive (`/mnt/seagate`)
- Passwordless sudo configured (see commands below)

## Step 1: Configure Passwordless Sudo

Add these commands to `/etc/sudoers.d/ai_assistant_limited`:

```bash
# Disaster Recovery Commands
beardface ALL=(ALL) NOPASSWD: /bin/dd
beardface ALL=(ALL) NOPASSWD: /usr/bin/wget
beardface ALL=(ALL) NOPASSWD: /usr/bin/curl
beardface ALL=(ALL) NOPASSWD: /usr/bin/sync
beardface ALL=(ALL) NOPASSWD: /usr/bin/parted
beardface ALL=(ALL) NOPASSWD: /usr/bin/partprobe
beardface ALL=(ALL) NOPASSWD: /usr/bin/blkid
beardface ALL=(ALL) NOPASSWD: /usr/bin/file
beardface ALL=(ALL) NOPASSWD: /usr/bin/sha256sum
beardface ALL=(ALL) NOPASSWD: /usr/bin/md5sum
```

## Step 2: Identify USB Device

```bash
lsblk
# Look for USB device (usually /dev/sdb, /dev/sdc, etc.)
# Example output: sdb 8:16 1 7.5G 0 disk
```

## Step 3: Download Clonezilla Live ISO

```bash
cd /tmp
wget -O clonezilla-live-3.2.2-15-amd64.iso https://sourceforge.net/projects/clonezilla/files/clonezilla_live_stable/3.2.2-15/clonezilla-live-3.2.2-15-amd64.iso/download
```

## Step 4: Create Bootable USB

```bash
# Replace /dev/sdX with your actual USB device
sudo dd if=/tmp/clonezilla-live-3.2.2-15-amd64.iso of=/dev/sdX bs=4M status=progress
sudo sync
```

## Step 5: Verify USB Creation

```bash
sudo blkid /dev/sdX
# Should show: LABEL="3.2.2-15-amd64" TYPE="iso9660"
```

## Step 6: Create System Image

### Option A: Using Clonezilla Live (Recommended)
1. Boot from USB
2. Select Clonezilla Live
3. Choose "device-image" mode
4. Select "local_dev" for local device
5. Mount network drive: `/mnt/seagate`
6. Create image to: `/mnt/seagate/backups/[hostname]/system-image-$(date +%Y%m%d-%H%M%S).img`

### Option B: Using dd Command (Alternative)
1. Boot from USB
2. Mount network drive: `mkdir -p /mnt/seagate && mount -t cifs //192.168.8.2/seagate /mnt/seagate -o username=[username],password=[password]`
3. Run the system image script

## Step 7: Directory Structure

Create the following structure on Seagate drive:
```
/mnt/seagate/backups/
├── crotchwarmer/          # Laptop machine
│   ├── system-image-*.img
│   ├── system-image-*.sha256
│   ├── system-image-*.info
│   └── timeshift-backups/
└── [dev-desktop-hostname]/ # Dev desktop machine
    ├── system-image-*.img
    ├── system-image-*.sha256
    ├── system-image-*.info
    └── timeshift-backups/
```

## Step 8: Test Recovery Process

1. Boot from Clonezilla USB
2. Select "device-image" mode
3. Choose "local_dev" for local device
4. Mount network drive
5. Test restoring from system image (dry run)

## Commands Summary

```bash
# 1. Identify USB
lsblk

# 2. Download Clonezilla
wget -O clonezilla-live-3.2.2-15-amd64.iso [URL]

# 3. Create bootable USB
sudo dd if=clonezilla-live-3.2.2-15-amd64.iso of=/dev/sdX bs=4M status=progress

# 4. Verify USB
sudo blkid /dev/sdX

# 5. Create backup directory
mkdir -p /mnt/seagate/backups/$(hostname)

# 6. Boot from USB and create system image
```

## Notes
- System image will be large (~400-500GB)
- Process takes several hours
- Ensure sufficient space on Seagate drive
- Test boot from USB after creation
- Keep USB in safe location for emergency recovery
