# Immediate Fix for Enterprise Detection Issue

## Problem

Even though you set the database config, `ChatwootApp.enterprise?` returns `false` because:
- The `enterprise` folder might not exist in the Docker image, OR
- `DISABLE_ENTERPRISE` environment variable is set

## Quick Diagnosis

Run these in Rails console:

```ruby
# 1. Check environment variable
ENV['DISABLE_ENTERPRISE']
# If this returns "true" or "1", that's the problem

# 2. Check app root
ChatwootApp.root
# Should show something like: #<Pathname:/app>

# 3. Check if enterprise folder exists
ChatwootApp.root.join('enterprise').exist?
# This is what enterprise? checks

# 4. List app directory
Dir.entries(ChatwootApp.root.to_s).select { |f| File.directory?(File.join(ChatwootApp.root.to_s, f)) }
# Check if 'enterprise' is in the list
```

## Immediate Workaround (Rails Console)

Run this to patch the method temporarily:

```ruby
# Override enterprise? to check database config as fallback
module ChatwootApp
  def self.enterprise?
    return false if ENV.fetch('DISABLE_ENTERPRISE', false) == 'true' || ENV.fetch('DISABLE_ENTERPRISE', false) == '1'
    
    # Check folder first
    folder_exists = root.join('enterprise').exist?
    
    # Fallback: check database config
    if !folder_exists
      config = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')
      return config&.value == 'enterprise' if config
    end
    
    folder_exists
  end
end

# Clear the cached value
ChatwootApp.instance_variable_set(:@enterprise, nil)

# Now test
ChatwootApp.enterprise?  # Should return true
ChatwootHub.pricing_plan  # Should return "enterprise"
```

## Permanent Fix (For Custom Docker Image)

When building your custom image, modify `lib/chatwoot_app.rb`:

```ruby
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
```

And modify `lib/chatwoot_hub.rb`:

```ruby
def self.pricing_plan
  # Check database config first (doesn't require enterprise folder check)
  config = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN') rescue nil
  return config.value if config&.value.present? && config.value != 'community'
  
  # Fallback to enterprise check
  return 'community' unless ChatwootApp.enterprise?
  'enterprise'
end
```


