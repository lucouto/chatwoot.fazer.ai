#!/bin/bash
# Installation script for Chatwoot backup
# This will install the backup script following your existing pattern
# (similar to backup-n8n.sh)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT_SOURCE="${SCRIPT_DIR}/backup-chatwoot.sh"
BACKUP_SCRIPT_DEST="/usr/local/bin/backup-chatwoot.sh"
BACKUP_DIR="/var/backups/chatwoot"
LOG_FILE="/var/log/backup-chatwoot.log"

echo "🔧 Installing Chatwoot backup script..."
echo ""

# Step 1: Copy backup script to /usr/local/bin
echo "📝 Copying backup script to ${BACKUP_SCRIPT_DEST}..."
if [ ! -f "${BACKUP_SCRIPT_SOURCE}" ]; then
    echo "❌ Error: Source script not found: ${BACKUP_SCRIPT_SOURCE}"
    exit 1
fi

sudo cp "${BACKUP_SCRIPT_SOURCE}" "${BACKUP_SCRIPT_DEST}"
sudo chmod +x "${BACKUP_SCRIPT_DEST}"
echo "✅ Backup script installed"
echo ""

# Step 2: Create backup directory
echo "📁 Creating backup directory: ${BACKUP_DIR}"
sudo mkdir -p "${BACKUP_DIR}"
sudo chmod 755 "${BACKUP_DIR}"
echo "✅ Backup directory created"
echo ""

# Step 3: Create log file
echo "📋 Creating log file: ${LOG_FILE}"
sudo touch "${LOG_FILE}"
sudo chmod 644 "${LOG_FILE}"
echo "✅ Log file created"
echo ""

# Step 4: Test backup script (optional)
echo "🧪 Testing backup script..."
read -p "Do you want to test the backup script now? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Running test backup..."
    sudo "${BACKUP_SCRIPT_DEST}" || {
        echo "⚠️  Test backup failed, but installation continues..."
        echo "   You may need to adjust database configuration"
    }
    echo ""
fi

# Step 5: Add cron job
echo "⏰ Setting up cron job..."
echo "   Following your existing pattern (5 2 * * * like backup-n8n.sh)"
echo ""

CRON_ENTRY="5 2 * * * ${BACKUP_SCRIPT_DEST} >> ${LOG_FILE} 2>&1"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "backup-chatwoot.sh"; then
    echo "⚠️  Cron job already exists for Chatwoot backup"
    echo "   Current entry:"
    crontab -l | grep "backup-chatwoot.sh"
    echo ""
    read -p "Do you want to replace it? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Remove old entry and add new one
        crontab -l 2>/dev/null | grep -v "backup-chatwoot.sh" | crontab -
        (crontab -l 2>/dev/null; echo "${CRON_ENTRY}") | crontab -
        echo "✅ Cron job updated"
    else
        echo "ℹ️  Keeping existing cron job"
    fi
else
    # Add new cron job
    (crontab -l 2>/dev/null; echo "${CRON_ENTRY}") | crontab -
    echo "✅ Cron job added"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Chatwoot backup installation complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📦 Installation Summary:"
echo "   Script:     ${BACKUP_SCRIPT_DEST}"
echo "   Directory:  ${BACKUP_DIR}"
echo "   Log file:   ${LOG_FILE}"
echo "   Schedule:   5 2 * * * (Daily at 2:05 AM)"
echo ""
echo "📋 Your cron jobs:"
crontab -l | grep -E "(backup-n8n|backup-chatwoot)" || echo "   (No backup cron jobs found)"
echo ""
echo "🔍 Useful commands:"
echo "   View logs:        tail -f ${LOG_FILE}"
echo "   List backups:     ls -lh ${BACKUP_DIR}/"
echo "   Test backup:      sudo ${BACKUP_SCRIPT_DEST}"
echo "   View cron:        crontab -l"
echo ""
echo "💡 Note: Backups older than 30 days are automatically cleaned up"
echo ""

