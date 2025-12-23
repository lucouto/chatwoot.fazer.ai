# Enterprise Unlock Guide for Coolify Deployment

## Your Current Setup Analysis

Based on `docker-compose.coolify.yaml`, you're using:
- **Image:** `ghcr.io/fazer-ai/chatwoot:latest` (pre-built Docker image)
- **Pull Policy:** `always` (auto-updates from fazer-ai)
- **Deployment:** Coolify-managed Docker Compose
- **Data:** Persistent volumes for storage, postgres, redis

## Recommendation: **Option 3 - Hybrid Approach** (Best for Coolify)

### Why This Approach?

1. **No data migration needed** - Uses existing database
2. **Minimal downtime** - Database-only changes first, then code
3. **Easy rollback** - Can revert database changes instantly
4. **Custom image** - Build once, deploy via Coolify
5. **Future-proof** - Custom image won't auto-update and break

---

## Step-by-Step Implementation

### Phase 1: Quick Unlock (Database Only) - 5 minutes

**Purpose:** Unlock features immediately with zero downtime

**Steps:**

1. **Access Rails console via Coolify:**
   ```bash
   # In Coolify, go to your Chatwoot service
   # Click "Execute Command" or use terminal
   # Run:
   docker exec -it <rails-container-name> bundle exec rails console
   ```

2. **Unlock Enterprise features:**
   ```ruby
   # Set pricing plan
   config = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN')
   config.value = 'enterprise'
   config.locked = false
   config.save!
   
   # Enable features for all accounts
   premium_features = %w[disable_branding audit_logs sla captain_integration custom_roles]
   Account.find_each do |account|
     account.enable_features!(*premium_features)
     puts "Enabled features for: #{account.name}"
   end
   
   # Verify
   puts "Enterprise?: #{ChatwootApp.enterprise?}"
   puts "Pricing Plan: #{ChatwootHub.pricing_plan}"
   ```

3. **Verify in UI:**
   - Check Settings > Features
   - Enterprise features should be visible

**⚠️ Warning:** Features may be disabled again when `ReconcilePlanConfigService` runs (usually via scheduled job).

---

### Phase 2: Permanent Fix (Custom Docker Image) - 30 minutes

**Purpose:** Prevent automatic feature disabling permanently

#### Option A: Build Custom Image (Recommended)

1. **Fork and modify the code:**
   ```bash
   # Clone fazer-ai fork
   git clone https://github.com/fazer-ai/chatwoot.git
   cd chatwoot
   
   # Create a branch for your modifications
   git checkout -b enterprise-unlock
   ```

2. **Apply code modifications:**

   **File 1:** `enterprise/app/services/internal/reconcile_plan_config_service.rb`
   ```ruby
   def perform
     remove_premium_config_reset_warning
     # Skip feature disabling for self-hosted
     return
     
     # Original code commented:
     # return if ChatwootHub.pricing_plan != 'community'
     # create_premium_config_reset_warning if premium_config_reset_required?
     # reconcile_premium_config
     # reconcile_premium_features
   end
   ```

   **File 2:** `lib/chatwoot_hub.rb`
   ```ruby
   def self.pricing_plan
     return 'community' unless ChatwootApp.enterprise?
     # Default to enterprise for self-hosted
     InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value || 'enterprise'
   end
   ```

3. **Build and push custom Docker image:**
   ```bash
   # Build image
   docker build -t your-registry/chatwoot:enterprise-unlocked -f docker/Dockerfile .
   
   # Or use GitHub Container Registry (if you have access)
   docker build -t ghcr.io/your-username/chatwoot:enterprise-unlocked -f docker/Dockerfile .
   docker push ghcr.io/your-username/chatwoot:enterprise-unlocked
   ```

4. **Update Coolify configuration:**

   **In Coolify dashboard:**
   - Go to your Chatwoot service
   - Edit docker-compose configuration
   - Change image from:
     ```yaml
     image: 'ghcr.io/fazer-ai/chatwoot:latest'
     ```
   - To:
     ```yaml
     image: 'your-registry/chatwoot:enterprise-unlocked'
     # OR
     image: 'ghcr.io/your-username/chatwoot:enterprise-unlocked'
     ```
   - Change `pull_policy` from `always` to `if_not_present` or remove it
   - Save and redeploy

#### Option B: Use Environment Variable Override (Simpler, but less permanent)

1. **Add environment variable in Coolify:**
   - Go to your service environment variables
   - Add: `CHATWOOT_PRICING_PLAN=enterprise`

2. **Modify `lib/chatwoot_hub.rb` in a custom image:**
   ```ruby
   def self.pricing_plan
     return 'community' unless ChatwootApp.enterprise?
     return ENV['CHATWOOT_PRICING_PLAN'] if ENV['CHATWOOT_PRICING_PLAN'].present?
     InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value || 'enterprise'
   end
   ```

3. **Build and deploy custom image** (same as Option A step 3-4)

---

### Phase 3: Alternative - Volume Mount (Advanced)

If you want to patch without rebuilding the image:

1. **Create a patch directory on your VPS:**
   ```bash
   mkdir -p /path/to/chatwoot-patches
   ```

2. **Copy modified files:**
   ```bash
   # Copy your modified files to the patch directory
   cp enterprise/app/services/internal/reconcile_plan_config_service.rb \
      /path/to/chatwoot-patches/
   cp lib/chatwoot_hub.rb /path/to/chatwoot-patches/
   ```

3. **Mount as volume in Coolify:**
   ```yaml
   volumes:
     - 'storage:/app/storage'
     - '/path/to/chatwoot-patches/enterprise/app/services/internal/reconcile_plan_config_service.rb:/app/enterprise/app/services/internal/reconcile_plan_config_service.rb:ro'
     - '/path/to/chatwoot-patches/lib/chatwoot_hub.rb:/app/lib/chatwoot_hub.rb:ro'
   ```

   **⚠️ Note:** This is fragile and may break on updates. Not recommended for production.

---

## Comparison of Options

| Option | Downtime | Complexity | Risk | Maintenance |
|--------|----------|------------|------|-------------|
| **1. New Instance + Migration** | High (hours) | High | Low | Medium |
| **2. Patch Production (DB only)** | None | Low | Medium | High (may reset) |
| **3. Custom Image (Recommended)** | Low (5-10 min) | Medium | Low | Low |

---

## Recommended Workflow

### Immediate (Today):
1. ✅ Run Phase 1 (database unlock) - **5 minutes, zero downtime**
2. ✅ Test Enterprise features
3. ✅ Verify everything works

### This Week:
1. ✅ Build custom Docker image with modifications
2. ✅ Test image in staging/dev environment
3. ✅ Deploy to production via Coolify
4. ✅ Verify features remain unlocked

### Ongoing:
1. ✅ Monitor for any issues
2. ✅ Keep custom image updated with fazer-ai changes (merge upstream)
3. ✅ Document your custom build process

---

## Rollback Plan

### If Database-Only Approach Fails:

```ruby
# In Rails console
config = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')
config&.update(value: 'community')

# Disable features if needed
Account.find_each { |a| a.disable_features!(*premium_features) }
```

### If Custom Image Has Issues:

1. In Coolify, revert image to: `ghcr.io/fazer-ai/chatwoot:latest`
2. Set `pull_policy: always`
3. Redeploy

---

## Coolify-Specific Tips

1. **Backup before changes:**
   - Use Coolify's backup feature for database
   - Export volumes if needed

2. **Use Coolify's environment variables:**
   - Add `CHATWOOT_PRICING_PLAN=enterprise` as env var
   - This works if you modify code to read it

3. **Monitor logs:**
   - Check Coolify logs after deployment
   - Watch for `ReconcilePlanConfigService` warnings

4. **Test in staging first:**
   - Create a staging environment in Coolify
   - Test custom image there first

---

## Quick Command Reference

```bash
# Access Rails console
docker exec -it <rails-container> bundle exec rails console

# Check Enterprise status
ChatwootApp.enterprise?
ChatwootHub.pricing_plan

# Enable features
Account.find_each { |a| a.enable_features!('audit_logs', 'sla', 'captain_integration', 'custom_roles', 'disable_branding') }

# Build custom image
docker build -t your-registry/chatwoot:enterprise-unlocked -f docker/Dockerfile .

# Push to registry
docker push your-registry/chatwoot:enterprise-unlocked
```

---

## Final Recommendation

**Start with Phase 1 (database unlock) immediately** - it's safe, fast, and reversible.

**Then proceed with Phase 2 (custom image)** within a week to make it permanent.

This gives you:
- ✅ Immediate access to Enterprise features
- ✅ Time to test thoroughly
- ✅ Permanent solution without rush
- ✅ Easy rollback if needed


