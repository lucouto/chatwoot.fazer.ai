#!/bin/bash
# Script to verify we're backing up the correct Chatwoot database

echo "🔍 Verifying Chatwoot database..."
echo ""

# Find PostgreSQL container
POSTGRES_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i postgres | head -n 1)

if [ -z "${POSTGRES_CONTAINER}" ]; then
    echo "❌ Could not find PostgreSQL container"
    exit 1
fi

echo "✅ Found PostgreSQL container: ${POSTGRES_CONTAINER}"
echo ""

# Get PostgreSQL user
POSTGRES_USER=$(docker exec "${POSTGRES_CONTAINER}" env 2>/dev/null | grep "^POSTGRES_USER=" | cut -d'=' -f2 | head -1 || echo "")

if [ -z "${POSTGRES_USER}" ]; then
    echo "❌ Could not determine PostgreSQL user"
    exit 1
fi

echo "📋 PostgreSQL user: ${POSTGRES_USER}"
echo ""

# List all databases
echo "📊 All databases in this PostgreSQL instance:"
docker exec "${POSTGRES_CONTAINER}" psql -U "${POSTGRES_USER}" -l 2>/dev/null || docker exec "${POSTGRES_CONTAINER}" psql -l 2>/dev/null
echo ""

# Check Chatwoot application environment for database name
echo "🔍 Checking Chatwoot application containers for database configuration..."
echo ""

CHATWOOT_CONTAINERS=$(docker ps --format "{{.Names}}" | grep -iE "chatwoot|rails" | grep -v postgres)

if [ -n "${CHATWOOT_CONTAINERS}" ]; then
    for CONTAINER in ${CHATWOOT_CONTAINERS}; do
        echo "Container: ${CONTAINER}"
        echo "  POSTGRES_DB:"
        docker exec "${CONTAINER}" env 2>/dev/null | grep "POSTGRES_DB" || echo "    (not found)"
        echo "  POSTGRES_DATABASE:"
        docker exec "${CONTAINER}" env 2>/dev/null | grep "POSTGRES_DATABASE" || echo "    (not found)"
        echo ""
    done
else
    echo "⚠️  Could not find Chatwoot application containers"
    echo "   Looking for containers with 'chatwoot' or 'rails' in name"
    echo ""
fi

# Check docker-compose or environment files
echo "🔍 Checking for database name in docker-compose..."
if [ -f "docker-compose.coolify.yaml" ]; then
    echo "Found docker-compose.coolify.yaml:"
    grep -i "POSTGRES_DB\|POSTGRES_DATABASE" docker-compose.coolify.yaml | head -5
    echo ""
fi

# Ask user to confirm
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Please verify:"
echo "1. Which database name is Chatwoot using?"
echo "2. Is 'chatwoot_production' the correct database?"
echo ""
echo "Common database names:"
echo "  - chatwoot_production"
echo "  - chatwoot"
echo "  - chatwoot_prod"
echo "  - Or a custom name from your Coolify configuration"
echo ""

