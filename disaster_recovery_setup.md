# Disaster Recovery Setup - Emergency USB & Machine Image

**Date**: September 7, 2025  
**Hostname**: crotchwarmer  
**Target USB**: /dev/sda (232.4G)  
**Backup Location**: /mnt/seagate/backups/crotchwarmer  

## Step 1: Download Clonezilla Live ISO
- **Source**: https://sourceforge.net/projects/clonezilla/files/clonezilla_live_stable/3.2.2-15/clonezilla-live-3.2.2-15-amd64.iso/download
- **Version**: Clonezilla Live 3.2.2-15 (AMD64)
- **Size**: ~400 MB
- **Status**: Downloading to /tmp/clonezilla-live-3.2.2-15-amd64.iso

## Step 2: Create Bootable USB
- **Command**: `sudo dd if=/tmp/clonezilla-live-3.2.2-15-amd64.iso of=/dev/sda bs=4M status=progress`
- **Target**: /dev/sda (USB device)
- **Status**: ✅ COMPLETED (484 MB copied in 96.7 seconds)
- **Verification**: USB shows as bootable Clonezilla Live 3.2.2-15

## Step 3: Create Machine Image
- **Tool**: Clonezilla (from bootable USB) OR dd command
- **Source**: /dev/nvme0n1 (476.9G NVMe drive)
- **Destination**: /mnt/seagate/backups/crotchwarmer/system-image-$(date +%Y%m%d-%H%M%S).img
- **Method**: Disk-to-image
- **Status**: ✅ READY - Boot from USB and run create_system_image.sh
- **Script**: /home/beardface/lab/crash/create_system_image.sh (executable)

## Directory Structure
```
/mnt/seagate/backups/
├── crotchwarmer/          # This machine
│   ├── system-image-*.iso
│   └── timeshift-backups/
└── [dev-desktop-hostname]/ # Other machine (to be created)
    ├── system-image-*.iso
    └── timeshift-backups/
```

## Commands for Dev Desktop Replication
1. Identify USB device: `lsblk`
2. Download Clonezilla: `wget -O clonezilla-live-3.2.2-15-amd64.iso [URL]`
3. Create bootable USB: `sudo dd if=clonezilla-live-3.2.2-15-amd64.iso of=/dev/[usb-device] bs=4M status=progress`
4. Boot from USB and create system image to `/mnt/seagate/backups/[hostname]/`

## Notes
- USB device must be unmounted before dd command
- System image will be large (~400GB+)
- Ensure sufficient space on Seagate drive
- Test boot from USB after creation
