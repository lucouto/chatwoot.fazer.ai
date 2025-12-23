#!/bin/bash
# Chatwoot database backup script
# Follows the same pattern as backup-n8n.sh
# Usage: Called by cron job

set -e

# Configuration - adjust these based on your setup
BACKUP_DIR="${CHATWOOT_BACKUP_DIR:-/var/backups/chatwoot}"
LOG_FILE="${CHATWOOT_BACKUP_LOG:-/var/log/backup-chatwoot.log}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/chatwoot_backup_${TIMESTAMP}.sql.gz"

# Database configuration
# These can be set via environment variables or detected automatically
POSTGRES_DB="${POSTGRES_DB:-chatwoot_production}"
POSTGRES_USER="${POSTGRES_USER:-${SERVICE_USER_POSTGRES}}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-${SERVICE_PASSWORD_POSTGRES}}"

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

log "Starting Chatwoot database backup..."

# Try to find PostgreSQL container
# Method 1: Look for container with postgres in name (Coolify pattern)
POSTGRES_CONTAINER=$(docker ps --format "{{.Names}}" | grep -iE "postgres|chatwoot.*postgres" | head -n 1)

# Method 2: Look for container running postgres image
if [ -z "${POSTGRES_CONTAINER}" ]; then
    POSTGRES_CONTAINER=$(docker ps --format "{{.Names}}\t{{.Image}}" | grep -i postgres | cut -f1 | head -n 1)
fi

# Method 3: Look for container in chatwoot project/stack
if [ -z "${POSTGRES_CONTAINER}" ]; then
    POSTGRES_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i chatwoot | grep -i postgres | head -n 1)
fi

if [ -z "${POSTGRES_CONTAINER}" ]; then
    log "ERROR: Could not find PostgreSQL container"
    log "Available containers:"
    docker ps --format "{{.Names}}" | while read -r container; do
        log "  - $container"
    done
    exit 1
fi

log "Found PostgreSQL container: ${POSTGRES_CONTAINER}"

# Detect database user if not set
if [ -z "${POSTGRES_USER}" ] || [ "${POSTGRES_USER}" = "postgres" ]; then
    log "Detecting PostgreSQL user from container..."
    POSTGRES_USER=$(docker exec "${POSTGRES_CONTAINER}" env 2>/dev/null | grep "^POSTGRES_USER=" | cut -d'=' -f2 | head -1 || echo "")
    if [ -z "${POSTGRES_USER}" ]; then
        # Try docker inspect as fallback
        POSTGRES_USER=$(docker inspect "${POSTGRES_CONTAINER}" 2>/dev/null | grep -i "POSTGRES_USER" | head -1 | sed 's/.*POSTGRES_USER=\([^"]*\).*/\1/' | cut -d',' -f1 | tr -d '"' || echo "")
    fi
    if [ -z "${POSTGRES_USER}" ]; then
        log "⚠️  Could not detect POSTGRES_USER from environment"
        log "Trying to connect without specifying user (uses container default)..."
        # Test if we can connect without user (uses default)
        if docker exec "${POSTGRES_CONTAINER}" psql -l >/dev/null 2>&1; then
            POSTGRES_USER=""  # Empty means use default
            log "✅ Can connect with default user"
        else
            log "❌ ERROR: Could not determine PostgreSQL user"
            log "Please set POSTGRES_USER environment variable"
            exit 1
        fi
    else
        log "✅ Detected user: ${POSTGRES_USER}"
    fi
fi

if [ -n "${POSTGRES_USER}" ]; then
    log "Using PostgreSQL user: ${POSTGRES_USER}"
else
    log "Using default PostgreSQL user"
fi
log "Using database: ${POSTGRES_DB}"

# Perform backup using docker exec
BACKUP_SUCCESS=false
ERROR_OUTPUT=""

# Build pg_dump command
if [ -n "${POSTGRES_USER}" ]; then
    PG_DUMP_CMD="pg_dump -U ${POSTGRES_USER} -d ${POSTGRES_DB}"
else
    PG_DUMP_CMD="pg_dump -d ${POSTGRES_DB}"
fi

log "Running: ${PG_DUMP_CMD}"

# Execute backup
if docker exec "${POSTGRES_CONTAINER}" ${PG_DUMP_CMD} --no-owner --no-acl --clean --if-exists 2>"/tmp/backup_error_$$.log" | gzip > "${BACKUP_FILE}"; then
    BACKUP_SIZE=$(stat -f%z "${BACKUP_FILE}" 2>/dev/null || stat -c%s "${BACKUP_FILE}" 2>/dev/null || echo "0")
    if [ "${BACKUP_SIZE}" -gt 100 ]; then
        BACKUP_SUCCESS=true
    else
        ERROR_OUTPUT=$(cat "/tmp/backup_error_$$.log" 2>/dev/null || echo "Backup file is too small (${BACKUP_SIZE} bytes)")
        log "⚠️  Backup file size: ${BACKUP_SIZE} bytes (expected > 100 bytes)"
    fi
else
    ERROR_OUTPUT=$(cat "/tmp/backup_error_$$.log" 2>/dev/null || echo "pg_dump command failed")
fi

# Clean up temp error file
rm -f "/tmp/backup_error_$$.log"

if [ "${BACKUP_SUCCESS}" = true ]; then
    BACKUP_SIZE_H=$(du -h "${BACKUP_FILE}" | cut -f1)
    log "✅ Backup completed successfully: ${BACKUP_FILE} (${BACKUP_SIZE_H})"
else
    log "❌ Backup failed!"
    if [ -n "${ERROR_OUTPUT}" ]; then
        log "Error details: ${ERROR_OUTPUT}"
    fi
    log "Troubleshooting:"
    log "  - Container: ${POSTGRES_CONTAINER}"
    log "  - Database: ${POSTGRES_DB}"
    log "  - User: ${POSTGRES_USER:-postgres}"
    log "  - Try: docker exec ${POSTGRES_CONTAINER} psql -U postgres -l"
    exit 1
fi

# Cleanup old backups (keep last 30 days)
log "Cleaning up old backups (keeping last 30 days)..."
find "${BACKUP_DIR}" -name "chatwoot_backup_*.sql.gz" -type f -mtime +30 -delete 2>/dev/null || true
REMAINING=$(find "${BACKUP_DIR}" -name "chatwoot_backup_*.sql.gz" -type f | wc -l)
log "Cleanup completed. Remaining backups: ${REMAINING}"

log "Backup process finished successfully"

