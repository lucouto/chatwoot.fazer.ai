# Deployment Recommendation for Coolify

## Your Question: Which Option to Choose?

### ❌ Option 1: Deploy New Instance + Migrate Data
**NOT RECOMMENDED** for your situation because:
- ❌ Unnecessary complexity (data migration)
- ❌ High downtime (hours)
- ❌ Risk of data loss during migration
- ❌ Duplicate infrastructure costs
- ✅ Only advantage: Clean slate

**Verdict:** Skip this option.

---

### ⚠️ Option 2: Patch Production Directly
**PARTIALLY RECOMMENDED** as a **temporary solution**:

**Pros:**
- ✅ Zero downtime
- ✅ Immediate unlock (5 minutes)
- ✅ No infrastructure changes
- ✅ Easy to test

**Cons:**
- ❌ May be reset by `ReconcilePlanConfigService`
- ❌ Not permanent
- ❌ Requires monitoring

**Verdict:** Use this as **Phase 1** (immediate unlock), then move to Option 3.

---

### ✅ Option 3: Hybrid Approach (RECOMMENDED)
**BEST SOLUTION** for Coolify deployment:

**Phase 1: Quick Database Unlock (Today - 5 min)**
- Unlock features immediately via database
- Test and verify
- Zero downtime

**Phase 2: Custom Docker Image (This Week - 30 min)**
- Build custom image with code modifications
- Deploy via Coolify
- Permanent solution

**Pros:**
- ✅ Immediate access (Phase 1)
- ✅ Permanent solution (Phase 2)
- ✅ No data migration needed
- ✅ Minimal downtime (5-10 min for Phase 2)
- ✅ Easy rollback
- ✅ Works with Coolify's workflow

**Cons:**
- ⚠️ Need to build custom image (one-time)
- ⚠️ Need to maintain custom image (merge upstream updates)

**Verdict:** **This is the recommended approach.**

---

## My Recommendation: **Option 3 - Hybrid Approach**

### Immediate Action (Today):

1. **Run the quick unlock script** (5 minutes):
   ```bash
   # In Coolify, access Rails container
   docker exec -it <rails-container> bash
   
   # Run unlock commands
   bundle exec rails runner "
   config = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN')
   config.value = 'enterprise'
   config.locked = false
   config.save!
   
   premium_features = %w[disable_branding audit_logs sla captain_integration custom_roles]
   Account.find_each { |a| a.enable_features!(*premium_features) }
   "
   ```

2. **Verify it works:**
   - Check Settings > Features in UI
   - Test Enterprise features
   - Confirm everything works

### This Week:

1. **Fork the repository** (if you haven't)
2. **Apply code modifications** (see `CODE_MODIFICATIONS.md`)
3. **Build custom Docker image**
4. **Deploy via Coolify** (update image reference)
5. **Verify features stay unlocked**

---

## Why This Approach?

### For Coolify Specifically:

1. **Coolify uses Docker images** - Building a custom image fits perfectly
2. **No volume mounts needed** - Code is baked into image
3. **Easy updates** - Just rebuild and redeploy
4. **Database stays the same** - No migration complexity
5. **Rollback is simple** - Just change image back

### Risk Mitigation:

- **Phase 1** gives you immediate access with zero risk
- **Phase 2** makes it permanent after you've tested
- **Both phases** are reversible if needed

---

## Step-by-Step Implementation

### Step 1: Quick Unlock (5 minutes) ⚡

```bash
# Access Rails console in Coolify
docker exec -it <your-rails-container> bundle exec rails console

# Then run:
config = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN')
config.value = 'enterprise'
config.locked = false
config.save!

premium_features = %w[disable_branding audit_logs sla captain_integration custom_roles]
Account.find_each { |a| a.enable_features!(*premium_features) }

# Verify
ChatwootApp.enterprise?  # => true
ChatwootHub.pricing_plan  # => "enterprise"
```

**Result:** Enterprise features unlocked immediately! ✅

---

### Step 2: Build Custom Image (30 minutes) 🏗️

1. **Clone and modify:**
   ```bash
   git clone https://github.com/fazer-ai/chatwoot.git
   cd chatwoot
   git checkout -b enterprise-unlock
   ```

2. **Apply modifications:**
   - Edit `enterprise/app/services/internal/reconcile_plan_config_service.rb`
   - Edit `lib/chatwoot_hub.rb`
   - (See `CODE_MODIFICATIONS.md` for exact changes)

3. **Build image:**
   ```bash
   docker build -t your-registry/chatwoot:enterprise-unlocked \
     -f docker/Dockerfile .
   ```

4. **Push to registry:**
   ```bash
   docker push your-registry/chatwoot:enterprise-unlocked
   ```

5. **Update Coolify:**
   - Edit docker-compose configuration
   - Change image to your custom image
   - Change `pull_policy: always` to `pull_policy: if_not_present`
   - Redeploy

**Result:** Permanent Enterprise unlock! ✅

---

## Comparison Table

| Aspect | Option 1 | Option 2 | Option 3 (Recommended) |
|--------|----------|----------|----------------------|
| **Downtime** | Hours | None | 5-10 min (Phase 2) |
| **Complexity** | High | Low | Medium |
| **Risk** | Medium | Low | Low |
| **Permanent** | Yes | No | Yes |
| **Data Migration** | Required | None | None |
| **Coolify Fit** | Poor | Good | Excellent |
| **Time to Unlock** | Days | 5 min | 5 min (Phase 1) |

---

## Final Answer

**Choose Option 3 (Hybrid Approach):**

1. ✅ **Start with database unlock** (Phase 1) - immediate, safe, reversible
2. ✅ **Build custom image** (Phase 2) - permanent, fits Coolify workflow
3. ✅ **No data migration** - uses existing database
4. ✅ **Minimal downtime** - only during Phase 2 deployment (5-10 min)

This gives you the best of both worlds:
- Immediate access to Enterprise features
- Permanent solution that works with Coolify
- Low risk and easy rollback

---

## Need Help?

- See `COOLIFY_DEPLOYMENT_GUIDE.md` for detailed steps
- See `CODE_MODIFICATIONS.md` for exact code changes
- Use `coolify-quick-unlock.sh` for automated Phase 1 unlock


