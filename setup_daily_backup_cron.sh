#!/bin/bash
# Setup Daily Backup Cron Job

echo "=== Setting up Daily Backup Cron Job ==="

# Create cron job file
sudo tee /etc/cron.d/live-system-backup << 'EOF'
# Live System Backup - Daily at 2 AM
0 2 * * * beardface /home/beardface/lab/crash/live_system_backup.sh >> /var/log/live_backup.log 2>&1
EOF

# Set proper permissions
sudo chmod 644 /etc/cron.d/live-system-backup

# Create log file with proper permissions
sudo touch /var/log/live_backup.log
sudo chown beardface:beardface /var/log/live_backup.log

echo "✅ Cron job created: /etc/cron.d/live-system-backup"
echo "✅ Log file created: /var/log/live_backup.log"
echo ""
echo "Cron job will run daily at 2:00 AM"
echo "Logs will be written to: /var/log/live_backup.log"
echo ""
echo "To test the backup manually:"
echo "  /home/beardface/lab/crash/live_system_backup.sh"
echo ""
echo "To view cron jobs:"
echo "  crontab -l"
echo "  sudo crontab -l"
echo ""
echo "To view cron logs:"
echo "  tail -f /var/log/live_backup.log"
