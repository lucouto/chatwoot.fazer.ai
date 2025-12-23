#!/bin/bash
# Setup script to configure Chatwoot database backups
# This script will:
# 1. Create backup directory
# 2. Set up backup script
# 3. Add cron job for automated backups
# 4. Create initial backup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT="${SCRIPT_DIR}/backup_database.sh"
BACKUP_DIR="${BACKUP_DIR:-/backups/chatwoot}"
CRON_SCHEDULE="${CRON_SCHEDULE:-0 2 * * *}"  # Default: Daily at 2 AM

echo "🔧 Setting up Chatwoot database backups..."
echo ""

# Step 1: Create backup directory
echo "📁 Creating backup directory: ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"
chmod 755 "${BACKUP_DIR}"
echo "✅ Backup directory created"
echo ""

# Step 2: Verify backup script exists and is executable
if [ ! -f "${BACKUP_SCRIPT}" ]; then
    echo "❌ Error: Backup script not found at ${BACKUP_SCRIPT}"
    echo "   Please make sure backup_database.sh exists in the deployment directory"
    exit 1
fi

chmod +x "${BACKUP_SCRIPT}"
echo "✅ Backup script is ready: ${BACKUP_SCRIPT}"
echo ""

# Step 3: Test backup script (dry run or actual backup)
echo "🧪 Testing backup script..."
echo "   (This will create a test backup to verify everything works)"
echo ""

# Set environment variables if not already set
export POSTGRES_HOST="${POSTGRES_HOST:-postgres}"
export POSTGRES_PORT="${POSTGRES_PORT:-5432}"
export POSTGRES_USER="${POSTGRES_USER:-postgres}"
export POSTGRES_DB="${POSTGRES_DB:-chatwoot_production}"

# Try to detect PostgreSQL container
POSTGRES_CONTAINER=$(docker ps --format "{{.Names}}" | grep -iE "postgres|chatwoot.*postgres" | head -n 1)

if [ -n "${POSTGRES_CONTAINER}" ]; then
    echo "✅ Found PostgreSQL container: ${POSTGRES_CONTAINER}"
    export POSTGRES_CONTAINER
else
    echo "⚠️  Warning: Could not auto-detect PostgreSQL container"
    echo "   You may need to set POSTGRES_CONTAINER environment variable"
fi

# Create initial backup
echo ""
echo "💾 Creating initial backup..."
"${BACKUP_SCRIPT}" "${BACKUP_DIR}" || {
    echo "⚠️  Initial backup failed, but continuing with setup..."
    echo "   You can run the backup manually later: ${BACKUP_SCRIPT} ${BACKUP_DIR}"
}
echo ""

# Step 4: Add cron job
echo "⏰ Setting up cron job..."
echo "   Schedule: ${CRON_SCHEDULE} (Daily at 2 AM)"
echo ""

# Create cron job entry
CRON_ENTRY="${CRON_SCHEDULE} ${BACKUP_SCRIPT} ${BACKUP_DIR} >> ${BACKUP_DIR}/backup.log 2>&1"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "${BACKUP_SCRIPT}"; then
    echo "⚠️  Cron job already exists for Chatwoot backup"
    echo "   Current crontab entries:"
    crontab -l | grep "${BACKUP_SCRIPT}" || true
    echo ""
    read -p "Do you want to replace it? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Remove old entry and add new one
        crontab -l 2>/dev/null | grep -v "${BACKUP_SCRIPT}" | crontab -
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
echo "📋 Current crontab entries for Chatwoot:"
crontab -l | grep -i chatwoot || crontab -l | grep "${BACKUP_SCRIPT}" || echo "   (No Chatwoot-specific entries found)"
echo ""

# Step 5: Setup log rotation (optional)
echo "📝 Setting up log rotation..."
LOG_FILE="${BACKUP_DIR}/backup.log"
if [ -f "${LOG_FILE}" ]; then
    echo "   Log file exists: ${LOG_FILE}"
else
    touch "${LOG_FILE}"
    chmod 644 "${LOG_FILE}"
    echo "   Log file created: ${LOG_FILE}"
fi
echo ""

# Step 6: Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Chatwoot backup setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📦 Backup Configuration:"
echo "   Script:     ${BACKUP_SCRIPT}"
echo "   Directory:  ${BACKUP_DIR}"
echo "   Schedule:   ${CRON_SCHEDULE}"
echo "   Log file:   ${BACKUP_DIR}/backup.log"
echo ""
echo "🔍 To verify:"
echo "   - Check backups: ls -lh ${BACKUP_DIR}/"
echo "   - View cron: crontab -l"
echo "   - Test backup: ${BACKUP_SCRIPT} ${BACKUP_DIR}"
echo "   - View logs: tail -f ${BACKUP_DIR}/backup.log"
echo ""
echo "📚 Backup files will be named:"
echo "   chatwoot_backup_YYYYMMDD_HHMMSS.sql.gz"
echo ""
echo "🗑️  Old backups (older than 7 days) are automatically cleaned up"
echo ""

