# System Monitoring & Recovery Project

This repository contains tools and scripts for monitoring system health, managing backups, and providing event-driven notifications through Cursor Background Agents.

## Project Structure

- `memory.md` - System analysis and findings
- `sudo_test_log.md` - Passwordless sudo testing log
- `cursor_sudoless.md` - Sudo configuration guide
- `mcp-send-email/` - Resend MCP server for email notifications
- `monitoring/` - System monitoring scripts and logs
- `backups/` - Backup management scripts

## Background Agent Integration

This repository is designed to work with Cursor Background Agents for event-driven notifications. System monitoring scripts write status updates to files within this repository, allowing Background Agents to:

1. Monitor system health metrics
2. Track backup operations
3. Report on long-running processes
4. Provide automated status updates

## Key Features

- NVMe drive health monitoring
- Timeshift backup management
- System crash analysis
- Automated email notifications
- Passwordless sudo configuration
- Duplicate file detection

## Usage

The repository serves as a central hub for system administration tasks, with Background Agents providing automated monitoring and reporting capabilities.
