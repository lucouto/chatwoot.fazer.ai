# Complete Fix for Enterprise Edition Unlock

## Root Cause

The `01_inject_enterprise_edition_module.rb` initializer loads Enterprise modules by iterating over `ChatwootApp.extensions`. If `extensions` returns an empty array (because `enterprise?` is false), **no Enterprise modules get loaded**, even if the code exists.

## Complete Solution

### Step 1: Fix `lib/chatwoot_app.rb`

Modify both `enterprise?` and `extensions` methods:

```ruby
# frozen_string_literal: true

require 'pathname'

module ChatwootApp
  def self.root
    Pathname.new(File.expand_path('..', __dir__))
  end

  def self.max_limit
    100_000
  end

  def self.enterprise?
    return false if ENV.fetch('DISABLE_ENTERPRISE', false) == 'true' || ENV.fetch('DISABLE_ENTERPRISE', false) == '1'
    
    # Check folder first
    folder_exists = root.join('enterprise').exist?
    
    # Fallback: check database config if folder doesn't exist
    if !folder_exists
      config = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN') rescue nil
      return config&.value == 'enterprise' if config
    end
    
    folder_exists
  end

  def self.chatwoot_cloud?
    enterprise? && GlobalConfig.get_value('DEPLOYMENT_ENV') == 'cloud'
  end

  def self.custom?
    @custom ||= root.join('custom').exist?
  end

  def self.help_center_root
    ENV.fetch('HELPCENTER_URL', nil) || ENV.fetch('FRONTEND_URL', nil)
  end

  def self.extensions
    # Check database config as fallback if folder doesn't exist
    is_enterprise = enterprise?
    
    if custom?
      %w[enterprise custom]
    elsif is_enterprise
      %w[enterprise]
    else
      %w[]
    end
  end

  def self.advanced_search_allowed?
    enterprise? && ENV.fetch('OPENSEARCH_URL', nil).present?
  end
end
```

### Step 2: Fix `lib/chatwoot_hub.rb`

Modify `pricing_plan` to check database first:

```ruby
def self.pricing_plan
  # Check database config first (doesn't require enterprise folder check)
  config = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN') rescue nil
  return config.value if config&.value.present? && config.value != 'community'
  
  # Fallback to enterprise check
  return 'community' unless ChatwootApp.enterprise?
  InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value || 'enterprise'
end
```

### Step 3: Rails Console Workaround (Immediate)

Run this in Rails console to patch both methods:

```ruby
# Fix ChatwootApp.enterprise?
module ChatwootApp
  def self.enterprise?
    return false if ENV.fetch('DISABLE_ENTERPRISE', false) == 'true' || ENV.fetch('DISABLE_ENTERPRISE', false) == '1'
    
    folder_exists = root.join('enterprise').exist?
    
    if !folder_exists
      config = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN') rescue nil
      return config&.value == 'enterprise' if config
    end
    
    folder_exists
  end
  
  # Clear cached value
  @enterprise = nil
end

# Fix ChatwootHub.pricing_plan
module ChatwootHub
  def self.pricing_plan
    config = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN') rescue nil
    return config.value if config&.value.present? && config.value != 'community'
    
    return 'community' unless ChatwootApp.enterprise?
    InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value || 'enterprise'
  end
end

# Verify
puts "Enterprise?: #{ChatwootApp.enterprise?}"
puts "Extensions: #{ChatwootApp.extensions}"
puts "Pricing Plan: #{ChatwootHub.pricing_plan}"

# Check if Enterprise modules are loaded
puts "Account ancestors include Enterprise::Account: #{Account.ancestors.any? { |a| a.name&.include?('Enterprise::Account') }}"
```

**⚠️ Important:** This Rails console patch is **temporary** and will be lost on restart. You need to apply the code modifications permanently in your custom Docker image.

### Step 4: Verify Enterprise Modules Are Loaded

After applying the fix, verify:

```ruby
# Check if Enterprise modules are in the ancestor chain
Account.ancestors.map(&:name).grep(/Enterprise/)
# Should show: ["Enterprise::Account", "Enterprise::Account::PlanUsageAndLimits", etc.]

# Check extensions
ChatwootApp.extensions
# Should return: ["enterprise"]

# Check if Enterprise methods are available
Account.instance_methods.grep(/enterprise|premium/)
# Should show Enterprise-specific methods
```

## Why This Works

1. **`enterprise?` returns true** when database config is set, even if folder doesn't exist
2. **`extensions` returns `%w[enterprise]`** because `enterprise?` is now true
3. **Injection mechanism iterates** over `['enterprise']` and loads all Enterprise modules
4. **All `prepend_mod_with` calls work** because modules are found and loaded
5. **Enterprise features function** because the code is actually loaded

## Permanent Solution

Apply these modifications when building your custom Docker image:

1. Modify `lib/chatwoot_app.rb` (as shown above)
2. Modify `lib/chatwoot_hub.rb` (as shown above)
3. Build and deploy custom image via Coolify

This ensures Enterprise modules are loaded even if the enterprise folder structure differs in the Docker image.


