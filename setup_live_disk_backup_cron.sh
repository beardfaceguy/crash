#!/bin/bash
# Setup Live Disk Backup Cron Job

echo "=== Setting up Live Disk Backup Cron Job ==="

# Remove the old file-level backup cron job
sudo rm -f /etc/cron.d/live-system-backup

# Create new cron job for live disk imaging
sudo tee /etc/cron.d/live-disk-backup << 'EOF'
# Live Disk Backup - Daily at 3 AM (bootable system images)
0 3 * * * beardface /home/beardface/lab/crash/live_disk_backup.sh >> /var/log/live_disk_backup.log 2>&1
EOF

# Set proper permissions
sudo chmod 644 /etc/cron.d/live-disk-backup

# Create log file with proper permissions
sudo touch /var/log/live_disk_backup.log
sudo chown beardface:beardface /var/log/live_disk_backup.log

echo "✅ Cron job created: /etc/cron.d/live-disk-backup"
echo "✅ Log file created: /var/log/live_disk_backup.log"
echo ""
echo "Cron job will run daily at 3:00 AM"
echo "Logs will be written to: /var/log/live_disk_backup.log"
echo ""
echo "To test the backup manually:"
echo "  /home/beardface/lab/crash/live_disk_backup.sh"
echo ""
echo "To view cron jobs:"
echo "  crontab -l"
echo "  sudo crontab -l"
echo ""
echo "To view cron logs:"
echo "  tail -f /var/log/live_disk_backup.log"
echo ""
echo "Backup location: /mnt/seagate/backups/crotchwarmer/live-disk-backups/"
echo "Retention: 3 days (due to large file sizes)"
