#!/bin/bash
# Script to find the correct PostgreSQL credentials

echo "🔍 Finding PostgreSQL credentials..."
echo ""

# Find PostgreSQL container
POSTGRES_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i postgres | head -n 1)

if [ -z "${POSTGRES_CONTAINER}" ]; then
    echo "❌ Could not find PostgreSQL container"
    exit 1
fi

echo "✅ Found container: ${POSTGRES_CONTAINER}"
echo ""

# Method 1: Check environment variables in the container
echo "📋 Environment variables in PostgreSQL container:"
docker exec "${POSTGRES_CONTAINER}" env | grep -iE "POSTGRES|DATABASE" | sort
echo ""

# Method 2: Try to list databases with different common users
echo "🔑 Trying to connect with different users..."
echo ""

# Common PostgreSQL users to try
USERS=("postgres" "chatwoot" "chatwoot_prod" "admin" "root")

for USER in "${USERS[@]}"; do
    echo "Trying user: ${USER}"
    if docker exec "${POSTGRES_CONTAINER}" psql -U "${USER}" -l 2>/dev/null | head -5; then
        echo "✅ Success with user: ${USER}"
        echo ""
        echo "Available databases:"
        docker exec "${POSTGRES_CONTAINER}" psql -U "${USER}" -l
        echo ""
        break
    else
        echo "❌ Failed with user: ${USER}"
    fi
done

# Method 3: Check docker-compose or inspect container for env vars
echo "📦 Container environment (from docker inspect):"
docker inspect "${POSTGRES_CONTAINER}" | grep -iE "POSTGRES_USER|POSTGRES_DB" | head -10
echo ""

# Method 4: Check if we can connect without specifying user (uses default)
echo "🔓 Trying default connection (no user specified):"
docker exec "${POSTGRES_CONTAINER}" psql -l 2>&1 | head -10
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Next steps:"
echo "1. Note the working username from above"
echo "2. Check the database name (might not be 'chatwoot_production')"
echo "3. Update the backup script with correct credentials"
echo ""

