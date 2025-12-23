#!/bin/bash
# Database backup script for Chatwoot
# Usage: ./backup_database.sh [backup_directory]

set -e

# Configuration
BACKUP_DIR="${1:-./backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/chatwoot_backup_${TIMESTAMP}.sql"
BACKUP_FILE_COMPRESSED="${BACKUP_FILE}.gz"

# Get database credentials from environment or docker-compose
POSTGRES_DB="${POSTGRES_DB:-chatwoot_production}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD}"
POSTGRES_HOST="${POSTGRES_HOST:-postgres}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

echo "Starting database backup..."
echo "Database: ${POSTGRES_DB}"
echo "Host: ${POSTGRES_HOST}:${POSTGRES_PORT}"
echo "Backup file: ${BACKUP_FILE_COMPRESSED}"

# Method 1: If running inside Docker/container with postgres service
if command -v pg_dump &> /dev/null; then
    export PGPASSWORD="${POSTGRES_PASSWORD}"
    pg_dump -h "${POSTGRES_HOST}" \
            -p "${POSTGRES_PORT}" \
            -U "${POSTGRES_USER}" \
            -d "${POSTGRES_DB}" \
            --no-owner \
            --no-acl \
            --clean \
            --if-exists \
            | gzip > "${BACKUP_FILE_COMPRESSED}"
    
    echo "✅ Backup completed: ${BACKUP_FILE_COMPRESSED}"
    echo "Backup size: $(du -h "${BACKUP_FILE_COMPRESSED}" | cut -f1)"
    
# Method 2: Using docker exec (if postgres is in a container)
elif docker ps | grep -q postgres; then
    POSTGRES_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i postgres | head -n 1)
    
    if [ -z "${POSTGRES_CONTAINER}" ]; then
        echo "❌ Error: Could not find PostgreSQL container"
        exit 1
    fi
    
    echo "Found PostgreSQL container: ${POSTGRES_CONTAINER}"
    
    docker exec "${POSTGRES_CONTAINER}" \
        pg_dump -U "${POSTGRES_USER}" \
                -d "${POSTGRES_DB}" \
                --no-owner \
                --no-acl \
                --clean \
                --if-exists \
        | gzip > "${BACKUP_FILE_COMPRESSED}"
    
    echo "✅ Backup completed: ${BACKUP_FILE_COMPRESSED}"
    echo "Backup size: $(du -h "${BACKUP_FILE_COMPRESSED}" | cut -f1)"
    
# Method 3: Using Coolify's database service
else
    echo "⚠️  Could not find pg_dump or PostgreSQL container"
    echo ""
    echo "For Coolify deployments, you have two options:"
    echo ""
    echo "Option 1: Use Coolify's built-in backup feature"
    echo "  1. Go to your Coolify project"
    echo "  2. Navigate to the PostgreSQL database service"
    echo "  3. Click on 'Backups' tab"
    echo "  4. Click 'Create Backup'"
    echo ""
    echo "Option 2: Manual backup via Coolify CLI or SSH"
    echo "  Connect to your server and run this script with proper environment variables"
    echo ""
    exit 1
fi

# Keep only last 7 backups (optional cleanup)
if [ -d "${BACKUP_DIR}" ]; then
    echo ""
    echo "Cleaning up old backups (keeping last 7)..."
    ls -t "${BACKUP_DIR}"/chatwoot_backup_*.sql.gz 2>/dev/null | tail -n +8 | xargs -r rm -f
    echo "✅ Cleanup completed"
fi

echo ""
echo "📦 Backup location: ${BACKUP_FILE_COMPRESSED}"
echo "💾 To restore: gunzip < ${BACKUP_FILE_COMPRESSED} | psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB}"

