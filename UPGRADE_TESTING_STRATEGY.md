# Testing and Upgrade Strategy for Chatwoot

## Current Situation

- **Production**: v4.8.0-fazer-ai.5-ee (stable, working)
- **Target**: v4.9.0-fazer-ai.8-ee (has Zeitwerk issue that needs fixing)
- **Future**: v5.0 (when available)

## Recommended Approach: Staging Environment

### Option 1: Separate Staging Stack in Coolify (Recommended)

Create a separate service stack in Coolify for testing:

#### Step 1: Create Staging Stack

1. In Coolify, create a new **Production Stack** (or use a separate environment)
2. Name it: `chatwoot-fazer-staging`
3. Use the same docker-compose but with:
   - Different database (or separate schema)
   - Different URL/domain
   - Test data

#### Step 2: Configure Staging Environment

**docker-compose.staging.yaml** (create this file):
```yaml
version: '3'

services:
  rails:
    image: 'ghcr.io/fazer-ai/chatwoot:v4.9.0-fazer-ai.8-ee'  # Test version
    # ... same config as production but with staging database
    environment:
      - POSTGRES_DATABASE=chatwoot_staging  # Separate database
      - FRONTEND_URL=https://staging-chatwoot.cheminneuf.community
    # ... rest of config

  sidekiq:
    image: 'ghcr.io/fazer-ai/chatwoot:v4.9.0-fazer-ai.8-ee'
    # ... same config

  postgres:
    # Use separate volume for staging
    volumes:
      - 'postgres_staging:/var/lib/postgresql/data'
    environment:
      - POSTGRES_DB=chatwoot_staging
    # ... rest of config
```

#### Step 3: Testing Workflow

1. **Deploy to staging** with new version
2. **Test all features**:
   - Basic functionality
   - Enterprise features
   - Integrations (WhatsApp, etc.)
   - Captain AI features
   - Custom configurations
3. **Fix any issues** in staging
4. **Once stable**, deploy to production

---

### Option 2: Use Feature Branch + Separate Coolify Stack

1. **Create a feature branch** for testing:
   ```bash
   git checkout -b test/v4.9.0-upgrade
   ```

2. **Apply fixes** (like the Zeitwerk fix) in the branch

3. **Configure Coolify** to build from this branch:
   - Point staging stack to `test/v4.9.0-upgrade` branch
   - Test thoroughly

4. **Merge to main** when ready for production

---

### Option 3: Local Testing with Docker Compose

Test locally before deploying:

```bash
# Clone your repo
git clone <your-repo>
cd chatwoot

# Checkout version to test
git checkout <commit-with-v4.9.0>

# Build and test locally
docker-compose -f docker-compose.production.yaml up

# Test features
# Fix any issues
# Then deploy to staging/production
```

---

## Step-by-Step Upgrade Process

### Phase 1: Preparation (Before Testing)

1. **Backup Production** ✅ (You already have this set up!)
   ```bash
   # Your automated backup runs daily
   # Create manual backup before upgrade
   ssh coolify-vm "sudo /usr/local/bin/backup-chatwoot.sh"
   ```

2. **Review Changelog**
   - Check fazer-ai releases for breaking changes
   - Review migration notes
   - Check for deprecated features

3. **Check Dependencies**
   - Ruby version compatibility
   - Node.js version
   - Database migrations required

### Phase 2: Staging Deployment

1. **Deploy to Staging**
   - Use staging stack in Coolify
   - Deploy v4.9.0-fazer-ai.8-ee
   - Monitor for errors

2. **Run Migrations**
   - Check migration status
   - Verify all migrations succeed
   - Test rollback if needed

3. **Smoke Tests**
   - Login/logout
   - Create conversation
   - Send message
   - Test integrations
   - Test Enterprise features

### Phase 3: Fix Issues in Staging

1. **Identify Problems**
   - Check logs for errors
   - Test all features
   - Document issues

2. **Apply Fixes**
   - Fix code issues (like Zeitwerk)
   - Update configurations
   - Test fixes

3. **Re-test**
   - Verify fixes work
   - Run full test suite
   - Performance testing

### Phase 4: Production Deployment

1. **Pre-deployment Checklist**
   - [ ] Staging is stable
   - [ ] All fixes applied
   - [ ] Backup created
   - [ ] Rollback plan ready
   - [ ] Team notified

2. **Deploy to Production**
   - Update docker-compose
   - Deploy during low-traffic window
   - Monitor closely

3. **Post-deployment**
   - Verify all services healthy
   - Test critical features
   - Monitor for 24-48 hours
   - Keep backup for rollback if needed

---

## Testing Checklist

### Basic Functionality
- [ ] User login/logout
- [ ] Dashboard loads
- [ ] Conversations list
- [ ] Message sending/receiving
- [ ] File attachments
- [ ] Search functionality

### Enterprise Features
- [ ] Captain AI features
- [ ] Custom attributes
- [ ] Advanced reporting
- [ ] SLA policies
- [ ] Custom roles

### Integrations
- [ ] WhatsApp (Baileys)
- [ ] Email
- [ ] Other channels

### Data Integrity
- [ ] All conversations accessible
- [ ] All contacts present
- [ ] Custom attributes intact
- [ ] Settings preserved

---

## Rollback Plan

If something goes wrong:

### Quick Rollback (5 minutes)

1. **In Coolify**:
   - Stop current deployment
   - Revert docker-compose to previous version
   - Redeploy

2. **Database Rollback** (if needed):
   ```bash
   # Restore from backup
   gunzip < /var/backups/chatwoot/chatwoot_backup_YYYYMMDD_HHMMSS.sql.gz | \
     docker exec -i <postgres-container> \
     psql -U <user> -d chatwoot_production
   ```

### Full Rollback (if database changed)

1. Restore database from backup
2. Revert code changes
3. Redeploy previous version

---

## For v5.0 Upgrade (Future)

When v5.0 is released:

1. **Wait for Stability**
   - Let fazer-ai release a few patches
   - Monitor for critical issues

2. **Extended Staging Period**
   - Test for at least 2 weeks in staging
   - Test with production-like data volume
   - Performance testing

3. **Gradual Rollout** (if possible)
   - Consider canary deployment
   - Monitor metrics
   - Rollback if issues

---

## Best Practices

1. **Always test in staging first**
2. **Keep production backups** (you have this ✅)
3. **Document all customizations** (Azure OpenAI, etc.)
4. **Test rollback procedure** before upgrading
5. **Monitor closely** after deployment
6. **Have a rollback window** (keep old version ready)

---

## Quick Reference

### Create Staging Environment
```bash
# In Coolify:
1. Create new Production Stack
2. Name: chatwoot-fazer-staging
3. Use separate database
4. Point to staging branch or use test image tag
```

### Test Upgrade
```bash
# 1. Deploy to staging
# 2. Run smoke tests
# 3. Fix issues
# 4. Re-test
# 5. Deploy to production when stable
```

### Rollback
```bash
# 1. Stop in Coolify
# 2. Revert docker-compose
# 3. Redeploy
# 4. Restore database if needed
```

---

## Recommended Timeline

For v4.9.0 upgrade:
- **Week 1**: Set up staging, deploy v4.9.0
- **Week 2**: Test and fix issues (like Zeitwerk)
- **Week 3**: Extended testing
- **Week 4**: Deploy to production (if stable)

For v5.0 (when available):
- **Month 1**: Monitor fazer-ai releases, wait for stability
- **Month 2**: Deploy to staging, extensive testing
- **Month 3**: Production deployment (if ready)

---

## Tools and Scripts

You already have:
- ✅ Automated backups (`/usr/local/bin/backup-chatwoot.sh`)
- ✅ Backup verification scripts
- ✅ Deployment scripts

Consider adding:
- Staging deployment script
- Automated smoke tests
- Health check monitoring

