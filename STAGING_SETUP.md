# Staging Environment Setup Guide

## Overview

This guide helps you set up a staging environment in Coolify to safely test Chatwoot upgrades before deploying to production.

## Key Differences from Production

| Aspect | Production | Staging |
|--------|-----------|---------|
| **Image Version** | `v4.8.0-fazer-ai.5-ee` | `v4.9.0-fazer-ai.8-ee` |
| **Database** | `chatwoot_production` | `chatwoot_staging` |
| **Storage Volume** | `storage` | `storage_staging` |
| **Postgres Volume** | `postgres` | `postgres_staging` |
| **Redis Volume** | `redis` | `redis_staging` |
| **URL** | `chatwoot.cheminneuf.community` | `staging-chatwoot.cheminneuf.community` (or your choice) |

## Setup Steps in Coolify

### Step 1: Create New Service Stack

1. **In Coolify Dashboard**:
   - Go to your project
   - Click "New Resource" or "Add Service Stack"
   - Choose "Service Stack" (docker-compose)

2. **Configure Stack**:
   - **Name**: `chatwoot-fazer-staging`
   - **Description**: `Staging environment for testing Chatwoot upgrades`
   - **Docker Compose File**: Use `docker-compose.staging.yaml`

### Step 2: Configure Environment Variables

Set up the same environment variables as production, but you can use:
- **Different database name**: `POSTGRES_DB=chatwoot_staging` (or let it default)
- **Staging URL**: Point `SERVICE_URL_RAILS` to your staging domain
- **Same credentials**: You can reuse production credentials or create new ones

### Step 3: Set Up Database (Optional)

You have two options:

#### Option A: Fresh Database (Recommended for Testing)
- Let migrations run automatically
- Start with clean data
- Test with sample data

#### Option B: Copy Production Data (For Realistic Testing)
```bash
# On your server
# 1. Backup production database
sudo /usr/local/bin/backup-chatwoot.sh

# 2. Copy to staging (adjust container names)
docker exec -i <production-postgres> pg_dump -U <user> chatwoot_production | \
  docker exec -i <staging-postgres> psql -U <user> chatwoot_staging
```

### Step 4: Deploy

1. **Upload docker-compose.staging.yaml** to Coolify
2. **Configure environment variables**
3. **Deploy**

## Testing Workflow

### Initial Testing (Day 1-2)

1. **Deploy to Staging**
   - Monitor logs for errors
   - Check all services are healthy
   - Verify migrations ran successfully

2. **Basic Smoke Tests**
   - [ ] Login works
   - [ ] Dashboard loads
   - [ ] Can create conversation
   - [ ] Can send message
   - [ ] Integrations work

### Extended Testing (Week 1-2)

1. **Feature Testing**
   - [ ] All Enterprise features
   - [ ] Captain AI functionality
   - [ ] Custom attributes
   - [ ] Integrations (WhatsApp, etc.)
   - [ ] Reporting features

2. **Fix Issues**
   - Document any problems
   - Fix in staging
   - Re-test fixes

### Production Readiness (Week 3-4)

1. **Final Verification**
   - [ ] All tests pass
   - [ ] Performance is acceptable
   - [ ] No critical bugs
   - [ ] Documentation updated

2. **Production Deployment**
   - Update production docker-compose
   - Deploy during maintenance window
   - Monitor closely

## Switching Between Versions

### Test New Version
```yaml
# In docker-compose.staging.yaml
image: 'ghcr.io/fazer-ai/chatwoot:v4.9.0-fazer-ai.8-ee'
```

### Test Specific Fix
```yaml
# If you build custom image
image: 'ghcr.io/lucouto/chatwoot.fazer.ai:test-branch-ee'
```

### Rollback in Staging
```yaml
# Revert to previous version
image: 'ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.5-ee'
```

## Environment Variables

### Required (Same as Production)
- `SERVICE_USER_POSTGRES`
- `SERVICE_PASSWORD_POSTGRES`
- `SERVICE_PASSWORD_64_SECRETKEYBASE`
- `SERVICE_PASSWORD_REDIS`
- `SERVICE_URL_RAILS` (point to staging URL)
- `BAILEYS_PROVIDER_*` (if using)
- `MAILER_SENDER_EMAIL`
- `RESEND_API_KEY`

### Optional (Staging-Specific)
- `POSTGRES_DB=chatwoot_staging` (defaults in compose file)
- `RAILS_ENV=production` (or `staging` if you configure it)
- Any test-specific configurations

## Monitoring Staging

### Check Logs
```bash
# Rails logs
docker logs <staging-rails-container> --tail 50

# Sidekiq logs
docker logs <staging-sidekiq-container> --tail 50
```

### Check Health
```bash
# Container status
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep staging
```

### Database Status
```bash
# Check migrations
docker exec <staging-rails-container> bundle exec rails db:migrate:status
```

## Cleanup

If you need to reset staging:

```bash
# Stop and remove containers
docker-compose -f docker-compose.staging.yaml down

# Remove volumes (⚠️ deletes all staging data)
docker volume rm <project>_postgres_staging
docker volume rm <project>_storage_staging
docker volume rm <project>_redis_staging

# Redeploy fresh
```

## Best Practices

1. **Keep Staging Separate**
   - Never point staging to production database
   - Use separate volumes
   - Use separate Redis instance

2. **Test Regularly**
   - Test new versions in staging first
   - Keep staging updated with latest code
   - Test rollback procedures

3. **Document Issues**
   - Keep notes of problems found
   - Document fixes applied
   - Share learnings with team

4. **Automate Testing** (Future)
   - Consider automated smoke tests
   - Health check monitoring
   - Performance benchmarks

## Troubleshooting

### Staging Won't Start
- Check environment variables
- Verify database credentials
- Check volume permissions
- Review logs for errors

### Database Issues
- Verify `POSTGRES_DB` is set correctly
- Check database exists
- Verify migrations ran

### Version Mismatch
- Ensure docker-compose.staging.yaml has correct image tag
- Check Coolify is using the right compose file
- Verify image exists in registry

## Next Steps

1. ✅ Create staging stack in Coolify
2. ✅ Upload docker-compose.staging.yaml
3. ✅ Configure environment variables
4. ✅ Deploy and test
5. ✅ Fix any issues found
6. ✅ Deploy to production when ready

---

## Quick Reference

**Staging Compose File**: `docker-compose.staging.yaml`  
**Production Compose File**: `docker-compose.coolify.yaml`  
**Staging Database**: `chatwoot_staging`  
**Staging Version**: `v4.9.0-fazer-ai.8-ee`  
**Production Version**: `v4.8.0-fazer-ai.5-ee`

