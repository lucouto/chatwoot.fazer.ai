#!/bin/bash
# Quick script to check deployment status

echo "🔍 Checking Chatwoot deployment status..."
echo ""

# Check container statuses
echo "📊 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | grep -E "NAME|chatwoot|rails|sidekiq|postgres|redis|baileys" || docker ps
echo ""

# Check Rails logs (last 50 lines)
echo "📋 Rails Logs (last 50 lines):"
RAILS_CONTAINER=$(docker ps --format "{{.Names}}" | grep -iE "rails|chatwoot" | grep -v sidekiq | head -1)
if [ -n "${RAILS_CONTAINER}" ]; then
    echo "Container: ${RAILS_CONTAINER}"
    docker logs --tail 50 "${RAILS_CONTAINER}" 2>&1 | tail -50
else
    echo "⚠️  Rails container not found"
fi
echo ""

# Check Sidekiq logs (last 50 lines)
echo "📋 Sidekiq Logs (last 50 lines):"
SIDEKIQ_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i sidekiq | head -1)
if [ -n "${SIDEKIQ_CONTAINER}" ]; then
    echo "Container: ${SIDEKIQ_CONTAINER}"
    docker logs --tail 50 "${SIDEKIQ_CONTAINER}" 2>&1 | tail -50
else
    echo "⚠️  Sidekiq container not found"
fi
echo ""

# Check for common errors
echo "🔍 Checking for common errors..."
if [ -n "${SIDEKIQ_CONTAINER}" ]; then
    echo "Sidekiq errors:"
    docker logs "${SIDEKIQ_CONTAINER}" 2>&1 | grep -iE "error|fatal|exception|failed" | tail -10 || echo "No obvious errors found"
fi
echo ""

# Check database migrations
echo "📊 Database migration status:"
if [ -n "${RAILS_CONTAINER}" ]; then
    docker exec "${RAILS_CONTAINER}" bundle exec rails db:migrate:status 2>&1 | tail -20 || echo "Could not check migration status"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 Next steps:"
echo "1. Check the logs above for specific errors"
echo "2. Wait a few minutes for Rails to finish starting"
echo "3. If Sidekiq keeps failing, check for:"
echo "   - Database connection issues"
echo "   - Missing environment variables"
echo "   - Migration errors"
echo "   - Redis connection issues"
echo ""

