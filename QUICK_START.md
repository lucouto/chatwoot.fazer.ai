# Quick Start: Unlock Enterprise Edition

## TL;DR - Fastest Method

### Option 1: Database Only (No Code Changes)

```bash
# Run in Rails console
rails console

# Then execute:
config = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN')
config.value = 'enterprise'
config.locked = false
config.save!

# Enable features for all accounts
premium_features = %w[disable_branding audit_logs sla captain_integration custom_roles]
Account.find_each { |a| a.enable_features!(*premium_features) }
```

**⚠️ Warning:** This may be reset by `ReconcilePlanConfigService` if it runs.

---

### Option 2: Code Modification (Permanent)

**1. Modify the reconcile service:**
```bash
# Edit: enterprise/app/services/internal/reconcile_plan_config_service.rb
# Change line 4 from:
return if ChatwootHub.pricing_plan != 'community'

# To:
return  # Skip feature disabling
```

**2. Set default pricing plan:**
```bash
# Edit: lib/chatwoot_hub.rb
# Change line 24 from:
InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value || 'community'

# To:
InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value || 'enterprise'
```

**3. Run unlock script:**
```bash
bundle exec rails runner unlock_enterprise.rb
```

**4. Restart application**

---

## Verification

After applying changes, verify in Rails console:

```ruby
ChatwootApp.enterprise?  # => true
ChatwootHub.pricing_plan  # => "enterprise"
Account.first.feature_enabled?(:audit_logs)  # => true
```

---

## What Gets Unlocked?

✅ **Audit Logs** - Track account activities  
✅ **SLA Policies** - Service level agreements  
✅ **Custom Roles** - Advanced permission management  
✅ **Disable Branding** - Remove Chatwoot branding  
✅ **Captain AI** - AI-powered conversations (needs OpenAI API key)  
✅ **SAML SSO** - Single sign-on authentication  
✅ **Agent Capacity** - Auto-assignment limits  
✅ **Advanced Search** - Enhanced search capabilities  
✅ **Companies** - Company management features  

---

## Need Help?

See detailed documentation:
- `ENTERPRISE_UNLOCK_ANALYSIS.md` - Full analysis
- `CODE_MODIFICATIONS.md` - Detailed code changes
- `unlock_enterprise.rb` - Automated unlock script


