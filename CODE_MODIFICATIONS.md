# Code Modifications to Unlock Enterprise Edition

## File 1: Prevent Automatic Feature Disabling

**File:** `enterprise/app/services/internal/reconcile_plan_config_service.rb`

### Modification Option A: Skip Feature Disabling (Recommended)

Replace the `perform` method:

```ruby
def perform
  remove_premium_config_reset_warning
  # Skip feature disabling for self-hosted installations
  # return if ChatwootHub.pricing_plan != 'community'
  
  # Only disable features if explicitly on community plan AND not self-hosted
  return if ChatwootHub.pricing_plan == 'community' && ChatwootApp.chatwoot_cloud?

  create_premium_config_reset_warning if premium_config_reset_required?

  reconcile_premium_config
  # Comment out to prevent automatic feature disabling
  # reconcile_premium_features
end
```

### Modification Option B: Complete Disable (Simpler)

Replace the `perform` method:

```ruby
def perform
  remove_premium_config_reset_warning
  # Enterprise features unlocked - skip reconciliation
  return
  
  # Original code commented out:
  # return if ChatwootHub.pricing_plan != 'community'
  # create_premium_config_reset_warning if premium_config_reset_required?
  # reconcile_premium_config
  # reconcile_premium_features
end
```

---

## File 2: Override Default Pricing Plan

**File:** `lib/chatwoot_hub.rb`

### Modification: Default to Enterprise for Self-Hosted

Replace the `pricing_plan` method (lines 21-25):

```ruby
def self.pricing_plan
  return 'community' unless ChatwootApp.enterprise?
  
  # Allow environment variable override
  return ENV['CHATWOOT_PRICING_PLAN'] if ENV['CHATWOOT_PRICING_PLAN'].present?
  
  # Default to 'enterprise' for self-hosted installations
  InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value || 'enterprise'
end
```

**Alternative (simpler):**
```ruby
def self.pricing_plan
  return 'community' unless ChatwootApp.enterprise?
  # Force enterprise for self-hosted
  InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value || 'enterprise'
end
```

---

## File 3: Environment Variable Support (Optional)

Add to your `.env` file:

```bash
# Unlock Enterprise Edition
CHATWOOT_PRICING_PLAN=enterprise

# Disable telemetry to prevent external sync
DISABLE_TELEMETRY=true
```

---

## Implementation Steps

### Step 1: Apply Code Modifications

1. **Modify ReconcilePlanConfigService:**
   ```bash
   # Backup original
   cp enterprise/app/services/internal/reconcile_plan_config_service.rb \
      enterprise/app/services/internal/reconcile_plan_config_service.rb.bak
   
   # Apply modification (use Option B for simplicity)
   ```

2. **Modify ChatwootHub:**
   ```bash
   # Backup original
   cp lib/chatwoot_hub.rb lib/chatwoot_hub.rb.bak
   
   # Apply modification
   ```

### Step 2: Run Unlock Script

```bash
# In Rails console or via runner
bundle exec rails runner unlock_enterprise.rb
```

Or manually in Rails console:
```ruby
# Set pricing plan
config = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN')
config.value = 'enterprise'
config.locked = false
config.save!

# Enable features for all accounts
premium_features = %w[disable_branding audit_logs sla captain_integration custom_roles]
Account.find_each { |a| a.enable_features!(*premium_features) }
```

### Step 3: Verify

```ruby
# In Rails console
ChatwootApp.enterprise?  # Should return true
ChatwootHub.pricing_plan  # Should return 'enterprise'

# Check an account
account = Account.first
account.feature_enabled?(:audit_logs)  # Should return true
account.feature_enabled?(:sla)  # Should return true
```

### Step 4: Restart Application

```bash
# Restart your Rails server/application
# For Docker:
docker-compose restart

# For systemd:
sudo systemctl restart chatwoot

# For manual:
# Stop and start your application server
```

---

## Rollback Instructions

If you need to revert changes:

1. **Restore backup files:**
   ```bash
   cp enterprise/app/services/internal/reconcile_plan_config_service.rb.bak \
      enterprise/app/services/internal/reconcile_plan_config_service.rb
   
   cp lib/chatwoot_hub.rb.bak lib/chatwoot_hub.rb
   ```

2. **Reset database config:**
   ```ruby
   config = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')
   config&.update(value: 'community')
   ```

3. **Restart application**

---

## Testing Checklist

After modifications, verify:

- [ ] `ChatwootApp.enterprise?` returns `true`
- [ ] `ChatwootHub.pricing_plan` returns `'enterprise'`
- [ ] Enterprise features visible in UI (Settings > Features)
- [ ] Audit Logs accessible
- [ ] SLA policies can be created
- [ ] Custom Roles can be created
- [ ] Branding can be disabled
- [ ] Captain AI accessible (if configured)
- [ ] Features remain enabled after app restart
- [ ] Features not disabled by ReconcilePlanConfigService

---

## Notes

1. **Captain AI** requires OpenAI API keys to function
2. **SAML SSO** requires proper configuration
3. **Some features** may need additional setup in the UI
4. **Database migrations** may be required for some Enterprise features
5. **Updates** from fazer-ai may overwrite changes - consider maintaining a patch branch


