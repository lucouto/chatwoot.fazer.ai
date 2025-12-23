#!/bin/bash
# Test script to diagnose backup issues

set -e

echo "🔍 Diagnosing Chatwoot backup issue..."
echo ""

# Find PostgreSQL container
POSTGRES_CONTAINER=$(docker ps --format "{{.Names}}" | grep -iE "postgres|chatwoot.*postgres" | head -n 1)

if [ -z "${POSTGRES_CONTAINER}" ]; then
    POSTGRES_CONTAINER=$(docker ps --format "{{.Names}}\t{{.Image}}" | grep -i postgres | cut -f1 | head -n 1)
fi

if [ -z "${POSTGRES_CONTAINER}" ]; then
    echo "❌ Could not find PostgreSQL container"
    echo "Available containers:"
    docker ps --format "{{.Names}}"
    exit 1
fi

echo "✅ Found container: ${POSTGRES_CONTAINER}"
echo ""

# Test 1: Check if container is running
echo "Test 1: Container status"
docker ps --format "{{.Names}}\t{{.Status}}" | grep "${POSTGRES_CONTAINER}"
echo ""

# Test 2: List databases
echo "Test 2: Available databases"
docker exec "${POSTGRES_CONTAINER}" psql -U postgres -l 2>/dev/null || {
    echo "⚠️  Could not list databases. Trying with different user..."
    docker exec "${POSTGRES_CONTAINER}" psql -U "${POSTGRES_USER:-postgres}" -l 2>/dev/null || true
}
echo ""

# Test 3: Check database exists and has tables
echo "Test 3: Checking chatwoot_production database"
DB_NAME="${POSTGRES_DB:-chatwoot_production}"
docker exec "${POSTGRES_CONTAINER}" psql -U postgres -d "${DB_NAME}" -c "\dt" 2>/dev/null | head -20 || {
    echo "⚠️  Could not list tables. Trying with different user..."
    docker exec "${POSTGRES_CONTAINER}" psql -U "${POSTGRES_USER:-postgres}" -d "${DB_NAME}" -c "\dt" 2>/dev/null | head -20 || true
}
echo ""

# Test 4: Count tables
echo "Test 4: Table count"
TABLE_COUNT=$(docker exec "${POSTGRES_CONTAINER}" psql -U postgres -d "${DB_NAME}" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ' || echo "unknown")
echo "Tables in ${DB_NAME}: ${TABLE_COUNT}"
echo ""

# Test 5: Try pg_dump directly
echo "Test 5: Testing pg_dump directly"
TEMP_BACKUP="/tmp/test_backup_$(date +%Y%m%d_%H%M%S).sql"
docker exec "${POSTGRES_CONTAINER}" pg_dump -U postgres -d "${DB_NAME}" --no-owner --no-acl 2>&1 | head -50 > "${TEMP_BACKUP}" || {
    echo "⚠️  pg_dump with postgres user failed. Trying with different user..."
    docker exec "${POSTGRES_CONTAINER}" pg_dump -U "${POSTGRES_USER:-postgres}" -d "${DB_NAME}" --no-owner --no-acl 2>&1 | head -50 > "${TEMP_BACKUP}" || true
}

if [ -f "${TEMP_BACKUP}" ]; then
    BACKUP_SIZE=$(wc -c < "${TEMP_BACKUP}")
    echo "Backup file size: ${BACKUP_SIZE} bytes"
    if [ "${BACKUP_SIZE}" -gt 100 ]; then
        echo "✅ Backup has content. First 20 lines:"
        head -20 "${TEMP_BACKUP}"
    else
        echo "⚠️  Backup is very small. Content:"
        cat "${TEMP_BACKUP}"
    fi
    rm -f "${TEMP_BACKUP}"
fi
echo ""

# Test 6: Check environment variables
echo "Test 6: Environment variables"
echo "POSTGRES_DB: ${POSTGRES_DB:-chatwoot_production}"
echo "POSTGRES_USER: ${POSTGRES_USER:-postgres}"
echo ""

# Test 7: Check actual database name from container
echo "Test 7: Database names in container"
docker exec "${POSTGRES_CONTAINER}" psql -U postgres -c "\l" 2>/dev/null | grep -E "Name|chatwoot" || {
    docker exec "${POSTGRES_CONTAINER}" psql -U "${POSTGRES_USER:-postgres}" -c "\l" 2>/dev/null | grep -E "Name|chatwoot" || true
}
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Diagnosis complete!"
echo ""
echo "Next steps:"
echo "1. Check if the database name is correct (might not be 'chatwoot_production')"
echo "2. Verify the database has data (table count should be > 0)"
echo "3. Check if pg_dump is working correctly"
echo ""

