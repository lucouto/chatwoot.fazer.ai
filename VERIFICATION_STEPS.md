# Verification Steps - Enterprise Unlock

## ✅ Phase 1 Complete!

Based on your Rails console output, the unlock was successful:
- ✅ `INSTALLATION_PRICING_PLAN` set to 'enterprise'
- ✅ Config unlocked (locked = false)
- ✅ Premium features enabled for 2 accounts

## Quick Verification Commands

Run these in Rails console to confirm:

```ruby
# Check Enterprise detection
ChatwootApp.enterprise?
# Should return: true

# Check pricing plan
ChatwootHub.pricing_plan
# Should return: "enterprise"

# Check account features
account = Account.first
account.feature_enabled?(:audit_logs)
# Should return: true

account.feature_enabled?(:sla)
# Should return: true

account.feature_enabled?(:captain_integration)
# Should return: true

account.feature_enabled?(:custom_roles)
# Should return: true

account.feature_enabled?(:disable_branding)
# Should return: true

# List all enabled features
account.enabled_features
# Should show all premium features
```

## UI Verification

1. **Log into Chatwoot dashboard**
2. **Go to Settings > Features** (or Super Admin > Features)
3. **Check for Enterprise features:**
   - ✅ Audit Logs should be visible/enabled
   - ✅ SLA should be visible/enabled
   - ✅ Custom Roles should be visible/enabled
   - ✅ Captain Integration should be visible/enabled
   - ✅ Disable Branding should be visible/enabled

4. **Test specific features:**
   - Try creating an SLA policy
   - Try accessing Audit Logs
   - Try creating a Custom Role
   - Check if Captain AI is accessible

## ⚠️ Important Notes

### Temporary Solution
This unlock is **temporary**. The `ReconcilePlanConfigService` may disable features again when it runs (usually via scheduled job `CheckNewVersionsJob`).

### Monitor for Issues
Watch for:
- Features disappearing after a few hours/days
- Warnings about premium config reset
- Jobs running that disable features

### Next Step: Phase 2
To make this permanent, proceed with **Phase 2: Custom Docker Image** (see `COOLIFY_DEPLOYMENT_GUIDE.md`)

## If Features Get Disabled Again

If you notice features are disabled later, you can quickly re-enable:

```ruby
# Re-enable features
premium_features = %w[disable_branding audit_logs sla captain_integration custom_roles]
Account.find_each { |a| a.enable_features!(*premium_features) }

# Check what disabled them
config = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')
puts "Current plan: #{config.value}"
```

This confirms that `ReconcilePlanConfigService` is running and you need Phase 2.


