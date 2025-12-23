# Troubleshooting: Enterprise Detection Failing

## Issue

After running unlock commands:
- ✅ Database config set to 'enterprise'
- ✅ Features enabled for accounts
- ❌ `ChatwootApp.enterprise?` returns `false`
- ❌ `ChatwootHub.pricing_plan` returns `"community"`

## Root Cause

The `ChatwootApp.enterprise?` method checks if the `/app/enterprise` folder exists. If it returns `false`, it means:
1. The enterprise folder doesn't exist in the Docker image, OR
2. The path detection is wrong, OR
3. `DISABLE_ENTERPRISE` environment variable is set

## Diagnosis Steps

Run these in Rails console to diagnose:

```ruby
# Check if DISABLE_ENTERPRISE is set
ENV['DISABLE_ENTERPRISE']
# Should return: nil or false (if it returns "true", that's the problem)

# Check the root path
ChatwootApp.root
# Should show the app root path

# Check if enterprise folder exists
ChatwootApp.root.join('enterprise').exist?
# Should return: true

# Check what the enterprise? method sees
ChatwootApp.root.join('enterprise')
# Should show the full path to enterprise folder

# List directory contents
Dir.entries(ChatwootApp.root.to_s).select { |f| File.directory?(File.join(ChatwootApp.root.to_s, f)) }
# Should show 'enterprise' in the list
```

## Solutions

### Solution 1: Check Docker Image

The fazer-ai Docker image might not include the enterprise folder. Check:

```bash
# In your VPS/Coolify, check the container
docker exec -it <rails-container> ls -la /app/ | grep enterprise

# Or check if enterprise folder exists
docker exec -it <rails-container> test -d /app/enterprise && echo "EXISTS" || echo "MISSING"
```

### Solution 2: Override Enterprise Detection (Workaround)

Since the database config is set, we can work around the detection issue by modifying the code to always return true when the config is set:

**Temporary workaround in Rails console:**
```ruby
# Monkey patch to force enterprise mode when config is set
module ChatwootApp
  def self.enterprise?
    return false if ENV.fetch('DISABLE_ENTERPRISE', false) == 'true'
    
    # Check if enterprise folder exists
    folder_exists = root.join('enterprise').exist?
    
    # OR check if pricing plan is set to enterprise
    config_plan = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value
    
    # Return true if either condition is met
    folder_exists || config_plan == 'enterprise'
  end
end

# Reload the module
load 'lib/chatwoot_app.rb'

# Now test
ChatwootApp.enterprise?  # Should return true
ChatwootHub.pricing_plan  # Should return "enterprise"
```

**Note:** This is a temporary workaround. For permanent fix, see Solution 3.

### Solution 3: Fix in Custom Docker Image (Permanent)

When building your custom Docker image, ensure:
1. The enterprise folder is included
2. Or modify `lib/chatwoot_app.rb` to check the database config as fallback

Modified `lib/chatwoot_app.rb`:
```ruby
def self.enterprise?
  return false if ENV.fetch('DISABLE_ENTERPRISE', false) == 'true'
  
  # Primary check: folder exists
  folder_exists = root.join('enterprise').exist?
  
  # Fallback: check database config
  config_plan = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value rescue nil
  
  folder_exists || config_plan == 'enterprise'
end
```

### Solution 4: Use Environment Variable (Quick Fix)

If the fazer-ai image doesn't include enterprise folder, you can't fix it without rebuilding. But you can work around the pricing plan check:

Modify `lib/chatwoot_hub.rb` in your custom image to not depend on `enterprise?`:

```ruby
def self.pricing_plan
  # Check database config first (doesn't require enterprise folder)
  db_plan = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value
  return db_plan if db_plan.present? && db_plan != 'community'
  
  # Fallback to enterprise check
  return 'community' unless ChatwootApp.enterprise?
  'enterprise'
end
```

## Immediate Action

Run the diagnosis commands above first to understand what's happening, then choose the appropriate solution.


