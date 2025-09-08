# Backup Strategy Comparison

## **Option 1: File-Level Backups (rsync/tar)**
**Script**: `live_system_backup.sh`

### ✅ **Pros:**
- Runs while system is active
- Incremental backups (faster)
- Smaller backup sizes
- Easy to restore individual files
- Can exclude specific directories

### ❌ **Cons:**
- Not bootable system images
- Requires manual restoration process
- May miss some system state
- Bootloader not included

### **Best For:**
- Daily incremental backups
- File recovery
- Quick system state preservation

---

## **Option 2: Live Disk Imaging (partclone)**
**Script**: `live_disk_backup.sh`

### ✅ **Pros:**
- Creates bootable system images
- Runs while system is active
- Complete partition images
- Easy restoration with included script
- Uses Clonezilla's engine (partclone)

### ❌ **Cons:**
- Larger backup sizes (~400-500GB)
- Takes longer to create
- Requires more storage space

### **Best For:**
- Complete system recovery
- Bootable system images
- Disaster recovery

---

## **Option 3: Clonezilla USB (Full Disk Images)**
**Script**: `create_system_image.sh`

### ✅ **Pros:**
- Most reliable (exclusive disk access)
- Complete system images
- Bootable recovery
- Industry standard tool

### ❌ **Cons:**
- Requires booting from USB
- Cannot run while system is active
- Manual process
- Takes several hours

### **Best For:**
- Emergency recovery
- Complete system migration
- One-time full backups

---

## **Recommended Hybrid Strategy:**

### **Daily (Automated):**
- **File-level backups** (`live_system_backup.sh`) at 2 AM
- **Live disk imaging** (`live_disk_backup.sh`) weekly

### **Monthly (Manual):**
- **Clonezilla USB** full system image for emergency recovery

### **Cron Schedule:**
```bash
# Daily file-level backup at 2 AM
0 2 * * * beardface /home/beardface/lab/crash/live_system_backup.sh

# Weekly disk imaging on Sundays at 3 AM  
0 3 * * 0 beardface /home/beardface/lab/crash/live_disk_backup.sh
```

## **Storage Requirements:**
- **File backups**: ~10-50GB per backup (7 days retention)
- **Disk images**: ~400-500GB per backup (3 days retention)
- **Total estimated**: ~1.5TB for both strategies

## **Recovery Options:**
1. **Quick file recovery**: Extract from file-level backups
2. **System recovery**: Use live disk images with restore script
3. **Emergency recovery**: Boot from Clonezilla USB and restore full image
