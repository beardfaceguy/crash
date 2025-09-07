# Cursor Passwordless Sudo Setup Guide

## Overview
This guide outlines the steps to grant Cursor's AI assistant passwordless sudo access in phases, starting with limited commands and expanding to full access after testing.

## Prerequisites
- ✅ Complete Timeshift backup system setup
- ✅ Test backup restoration capability
- ✅ Verify system stability

## Phase 1: Limited Command Access

### Step 1: Create Limited Sudoers File
```bash
# Create limited sudoers file for specific commands only
sudo tee /etc/sudoers.d/ai_assistant_limited << 'EOF'
# AI Assistant Limited Access
# Allows specific system administration commands without password
beardface ALL=(ALL) NOPASSWD: /usr/bin/timeshift
beardface ALL=(ALL) NOPASSWD: /usr/sbin/smartctl
beardface ALL=(ALL) NOPASSWD: /usr/bin/systemctl
beardface ALL=(ALL) NOPASSWD: /usr/bin/dmesg
beardface ALL=(ALL) NOPASSWD: /usr/bin/journalctl
beardface ALL=(ALL) NOPASSWD: /usr/bin/uptime
beardface ALL=(ALL) NOPASSWD: /usr/bin/free
beardface ALL=(ALL) NOPASSWD: /usr/bin/df
beardface ALL=(ALL) NOPASSWD: /usr/bin/lsblk
beardface ALL=(ALL) NOPASSWD: /usr/bin/mount
beardface ALL=(ALL) NOPASSWD: /usr/bin/umount
beardface ALL=(ALL) NOPASSWD: /usr/bin/fdisk
beardface ALL=(ALL) NOPASSWD: /usr/bin/ls
beardface ALL=(ALL) NOPASSWD: /usr/bin/cat
beardface ALL=(ALL) NOPASSWD: /usr/bin/grep
beardface ALL=(ALL) NOPASSWD: /usr/bin/find
beardface ALL=(ALL) NOPASSWD: /usr/bin/cp
beardface ALL=(ALL) NOPASSWD: /usr/bin/mv
beardface ALL=(ALL) NOPASSWD: /usr/bin/rm
beardface ALL=(ALL) NOPASSWD: /usr/bin/mkdir
beardface ALL=(ALL) NOPASSWD: /usr/bin/chmod
beardface ALL=(ALL) NOPASSWD: /usr/bin/chown
beardface ALL=(ALL) NOPASSWD: /usr/bin/realpath
beardface ALL=(ALL) NOPASSWD: /usr/bin/which
beardface ALL=(ALL) NOPASSWD: /usr/bin/ps
beardface ALL=(ALL) NOPASSWD: /usr/bin/pkill
beardface ALL=(ALL) NOPASSWD: /usr/bin/kill
beardface ALL=(ALL) NOPASSWD: /usr/bin/tail
beardface ALL=(ALL) NOPASSWD: /usr/bin/head
beardface ALL=(ALL) NOPASSWD: /usr/bin/wc
beardface ALL=(ALL) NOPASSWD: /usr/bin/du
beardface ALL=(ALL) NOPASSWD: /usr/bin/date
beardface ALL=(ALL) NOPASSWD: /usr/bin/echo
beardface ALL=(ALL) NOPASSWD: /usr/bin/tee
EOF
```

### Step 2: Set Proper Permissions
```bash
# Set correct permissions for sudoers file
sudo chmod 440 /etc/sudoers.d/ai_assistant_limited
```

### Step 3: Test Limited Access
```bash
# Test each command works without password
sudo timeshift --list
sudo smartctl -a /dev/nvme0n1
sudo systemctl status
sudo dmesg | head -5
sudo journalctl --no-pager | head -5
```

### Step 4: Monitor and Log
```bash
# Create monitoring script
sudo tee /usr/local/bin/ai_assistant_monitor.sh << 'EOF'
#!/bin/bash
# AI Assistant Activity Monitor
LOG_FILE="/var/log/ai_assistant_activity.log"
echo "$(date): AI Assistant command executed: $@" >> "$LOG_FILE"
EOF

sudo chmod +x /usr/local/bin/ai_assistant_monitor.sh

# Add to sudoers for monitoring
echo "beardface ALL=(ALL) NOPASSWD: /usr/local/bin/ai_assistant_monitor.sh" | sudo tee -a /etc/sudoers.d/ai_assistant_limited
```

## Phase 2: Full Access (After Phase 1 Testing)

### Step 1: Backup Current Configuration
```bash
# Backup the limited sudoers file
sudo cp /etc/sudoers.d/ai_assistant_limited /etc/sudoers.d/ai_assistant_limited.backup
```

### Step 2: Create Full Access File
```bash
# Create full access sudoers file
sudo tee /etc/sudoers.d/ai_assistant_full << 'EOF'
# AI Assistant Full Access
# WARNING: This grants full root access without password
# Only use after thorough testing of limited access
beardface ALL=(ALL) NOPASSWD: ALL
EOF
```

### Step 3: Set Permissions
```bash
sudo chmod 440 /etc/sudoers.d/ai_assistant_full
```

### Step 4: Test Full Access
```bash
# Test full access works
sudo whoami
sudo id
sudo ls -la /root
```

## Phase 3: SSH Key Authentication (Optional)

### Step 1: Generate SSH Key Pair
```bash
# Generate SSH key for AI assistant
ssh-keygen -t ed25519 -f ~/.ssh/ai_assistant_key -N ""
```

### Step 2: Configure Root SSH Access
```bash
# Create root SSH directory
sudo mkdir -p /root/.ssh
sudo chmod 700 /root/.ssh

# Copy public key to root's authorized_keys
sudo cp ~/.ssh/ai_assistant_key.pub /root/.ssh/authorized_keys
sudo chmod 600 /root/.ssh/authorized_keys
```

### Step 3: Configure SSH Server
```bash
# Enable root login with key authentication
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Restart SSH service
sudo systemctl restart sshd
```

### Step 4: Test SSH Access
```bash
# Test SSH key authentication
ssh -i ~/.ssh/ai_assistant_key root@localhost "whoami"
```

## Security Considerations

### Risks
- **System modification**: AI could accidentally break system files
- **Security vulnerabilities**: Root access bypasses normal protections
- **Data loss**: Could delete important files
- **Network exposure**: SSH access could be security risk

### Mitigations
- **Backup system**: Timeshift snapshots for quick recovery
- **Phased approach**: Start with limited access
- **Activity logging**: Monitor all root activities
- **Network isolation**: Ensure SSH isn't exposed to internet
- **Regular backups**: Maintain current backup schedule

## Rollback Procedures

### Remove Limited Access
```bash
sudo rm /etc/sudoers.d/ai_assistant_limited
```

### Remove Full Access
```bash
sudo rm /etc/sudoers.d/ai_assistant_full
```

### Remove SSH Access
```bash
sudo rm /root/.ssh/authorized_keys
sudo sed -i 's/PermitRootLogin yes/#PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

## Testing Checklist

### Phase 1 Testing
- [ ] All limited commands work without password
- [ ] Commands not in list still require password
- [ ] System stability maintained
- [ ] No unexpected behavior

### Phase 2 Testing
- [ ] Full sudo access works
- [ ] System remains stable
- [ ] Backup system still functional
- [ ] No security issues

### Phase 3 Testing
- [ ] SSH key authentication works
- [ ] Password authentication disabled
- [ ] Root login works via SSH
- [ ] Network security maintained

## Implementation Timeline

1. **Complete backup setup** (Current task)
2. **Test backup restoration** (Verify recovery works)
3. **Implement Phase 1** (Limited command access)
4. **Monitor for 24-48 hours** (Ensure stability)
5. **Implement Phase 2** (Full access if needed)
6. **Optional: Implement Phase 3** (SSH key access)

## Notes

- This is an experimental setup for a test system
- Regular backups are essential before implementing
- Monitor system logs for any issues
- Be prepared to rollback if problems occur
- Consider this a learning exercise in AI-assisted system administration

---
*Created: $(date)*
*Purpose: Enable AI assistant system administration without password prompts*
