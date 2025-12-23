# Enterprise Edition Unlock Analysis

## Executive Summary

**Feasibility: ✅ HIGHLY FEASIBLE**

The fazer-ai/chatwoot fork uses a **simple pricing plan check** mechanism rather than complex license validation. The Enterprise Edition code is **already present** in the repository, and unlocking it requires minimal code changes.

## Key Findings

### 1. Enterprise Folder Structure ✅
- The `enterprise/` directory **exists** and contains all Enterprise Edition code
- Location: `/enterprise/` (478+ files)
- All Enterprise features, models, controllers, and services are present

### 2. Enterprise Detection Mechanism

**File:** `lib/chatwoot_app.rb` (lines 14-18)
```ruby
def self.enterprise?
  return false if ENV.fetch('DISABLE_ENTERPRISE', false)
  @enterprise ||= root.join('enterprise').exist?
end
```

**Status:** ✅ This check **already passes** since the enterprise folder exists.

### 3. Pricing Plan Check (Main Gate)

**File:** `lib/chatwoot_hub.rb` (lines 21-25)
```ruby
def self.pricing_plan
  return 'community' unless ChatwootApp.enterprise?
  InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value || 'community'
end
```

**Issue:** Defaults to `'community'` which disables premium features.

### 4. Feature Disabling Service

**File:** `enterprise/app/services/internal/reconcile_plan_config_service.rb`

This service:
- Checks if `ChatwootHub.pricing_plan == 'community'`
- If true, **disables all premium features** for all accounts
- Runs periodically via `CheckNewVersionsJob`

**Premium features disabled:**
- `disable_branding`
- `audit_logs`
- `response_bot`
- `sla`
- `captain_integration`
- `custom_roles`

### 5. UI Feature Gating

**File:** `app/helpers/super_admin/features.yml`

Features are conditionally enabled based on:
```ruby
enabled: <%= (ChatwootHub.pricing_plan != 'community') %>
```

This affects:
- Captain AI
- Custom Branding
- Agent Capacity
- Audit Logs
- Disable Branding
- SAML SSO

## Solution Options

### Option 1: Database Configuration (Recommended - No Code Changes)

**Steps:**
1. Set `INSTALLATION_PRICING_PLAN` in the database to `'enterprise'` or `'premium'`
2. Ensure the config is not locked (or unlock it)

**Rails Console:**
```ruby
config = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN')
config.value = 'enterprise'
config.locked = false
config.save!
```

**Pros:**
- No code changes required
- Easy to revert
- Works immediately

**Cons:**
- May be reset by `CheckNewVersionsJob` if it syncs with external service
- Requires database access

### Option 2: Modify ReconcilePlanConfigService (Permanent Solution)

**File:** `enterprise/app/services/internal/reconcile_plan_config_service.rb`

**Change line 4:**
```ruby
# Before:
return if ChatwootHub.pricing_plan != 'community'

# After:
return if ChatwootHub.pricing_plan == 'enterprise' || ChatwootHub.pricing_plan == 'premium'
```

Or comment out the feature disabling:
```ruby
def perform
  remove_premium_config_reset_warning
  # return if ChatwootHub.pricing_plan != 'community'  # Disabled to unlock Enterprise
  
  create_premium_config_reset_warning if premium_config_reset_required?
  # reconcile_premium_config  # Optional: comment out to prevent config resets
  # reconcile_premium_features  # Commented out to prevent feature disabling
end
```

**Pros:**
- Permanent solution
- Prevents automatic feature disabling
- No database changes needed

**Cons:**
- Requires code modification
- May break on updates if service changes

### Option 3: Modify ChatwootHub.pricing_plan (Override Default)

**File:** `lib/chatwoot_hub.rb`

**Change lines 21-25:**
```ruby
def self.pricing_plan
  return 'community' unless ChatwootApp.enterprise?
  # Force enterprise plan for self-hosted
  InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value || 'enterprise'
end
```

**Pros:**
- Simple one-line change
- Affects all pricing plan checks
- Defaults to enterprise for self-hosted

**Cons:**
- Still requires database config or defaults to 'enterprise'

### Option 4: Environment Variable Override (Most Flexible)

**Add to:** `lib/chatwoot_hub.rb`

```ruby
def self.pricing_plan
  return 'community' unless ChatwootApp.enterprise?
  # Allow environment variable override
  return ENV['CHATWOOT_PRICING_PLAN'] if ENV['CHATWOOT_PRICING_PLAN'].present?
  InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value || 'community'
end
```

Then set in `.env`:
```
CHATWOOT_PRICING_PLAN=enterprise
```

**Pros:**
- Most flexible
- Easy to configure per environment
- No database changes

**Cons:**
- Requires code modification

## Recommended Approach

**Combination of Option 1 + Option 2:**

1. **Immediate:** Set database config to unlock features now
2. **Permanent:** Modify `ReconcilePlanConfigService` to prevent automatic disabling

This ensures:
- Features unlock immediately
- Features stay unlocked even if the service runs
- No external dependencies

## Additional Considerations

### CheckNewVersionsJob

**File:** `enterprise/app/jobs/enterprise/internal/check_new_versions_job.rb`

This job:
- Syncs with external service (if configured)
- Updates `INSTALLATION_PRICING_PLAN` from external source
- Calls `ReconcilePlanConfigService`

**Recommendation:** If you don't want external sync, ensure:
- `CHATWOOT_HUB_URL` is not set, OR
- `DISABLE_TELEMETRY` is set to `true`

### Feature Flags

After unlocking, you may need to **manually enable features** for existing accounts:

```ruby
Account.find_each do |account|
  account.enable_features!(
    'disable_branding',
    'audit_logs',
    'sla',
    'captain_integration',
    'custom_roles'
  )
end
```

### Verification

Check if Enterprise is detected:
```ruby
ChatwootApp.enterprise?  # Should return true
ChatwootHub.pricing_plan  # Should return 'enterprise' or 'premium'
```

## Risk Assessment

**Low Risk:**
- Enterprise code is already present and functional
- Changes are minimal and reversible
- No external API calls required for basic unlock
- Standard Chatwoot architecture (not heavily modified)

**Potential Issues:**
- Updates from fazer-ai may reset changes (use git branches)
- Some Enterprise features may require additional configuration
- Captain AI requires OpenAI API keys
- SAML requires proper configuration

## Conclusion

**Unlocking Enterprise Edition is straightforward and low-risk.** The fazer-ai fork does not use complex license validation - it simply checks a database configuration value. With minimal code changes (or just database configuration), all Enterprise features can be unlocked.


