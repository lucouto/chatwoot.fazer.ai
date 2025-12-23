# Update Instructions: Switch to Enterprise Edition Image

## Changes Required

You only need to change **2 lines** in your docker-compose file:

### Line 1: Rails Service Image
**Change from:**
```yaml
image: 'ghcr.io/fazer-ai/chatwoot:latest'
```

**To:**
```yaml
image: 'ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee'
```

### Line 2: Sidekiq Service Image
**Change from:**
```yaml
image: 'ghcr.io/fazer-ai/chatwoot:latest'
```

**To:**
```yaml
image: 'ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee'
```

## Option: Use Latest EE Tag

If you want automatic updates to the latest EE version, use:
```yaml
image: 'ghcr.io/fazer-ai/chatwoot:latest-ee'
```

**Note:** `latest-ee` will auto-update when fazer-ai releases new EE versions. The specific version tag (`v4.8.0-fazer-ai.2-ee`) is more stable but requires manual updates.

## Steps in Coolify

1. **Go to your Chatwoot service in Coolify**
2. **Edit the docker-compose configuration**
3. **Update the two image lines** (rails and sidekiq)
4. **Save and redeploy**

## After Deployment

Once redeployed, verify in Rails console:

```ruby
# Should all return true/enterprise
ChatwootApp.enterprise?           # => true
ChatwootApp.extensions            # => ["enterprise"]
ChatwootHub.pricing_plan          # => "enterprise"

# Check if Enterprise modules loaded
Account.ancestors.map(&:name).grep(/Enterprise/)
# Should show Enterprise modules like: ["Enterprise::Account", ...]
```

## What This Fixes

✅ Enterprise folder will exist in the image  
✅ `ChatwootApp.enterprise?` will return `true`  
✅ `ChatwootApp.extensions` will return `["enterprise"]`  
✅ Enterprise modules will load automatically  
✅ Combined with your database config, all features will work  

## No Code Changes Needed!

Since the EE image includes the enterprise folder, you don't need:
- ❌ Code modifications
- ❌ Custom Docker image builds
- ❌ Module patching

Just use the correct image tag and everything should work!


