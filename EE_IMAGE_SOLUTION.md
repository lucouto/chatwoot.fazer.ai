# Solution: Use Enterprise Edition Docker Image

## The Problem

You're currently using `ghcr.io/fazer-ai/chatwoot:latest` which is the **Community Edition (CE)** image.

Looking at the GitHub Actions workflows:

### Community Edition Image (`publish_foss_docker.yml`):
```yaml
- name: Strip enterprise code
  run: |
    rm -rf enterprise          # ← Enterprise folder is REMOVED!
    rm -rf spec/enterprise
```

### Enterprise Edition Image (`publish_ee_github_docker.yml`):
```yaml
- name: Set Chatwoot edition
  run: |
    echo -en '\nENV CW_EDITION="ee"' >> docker/Dockerfile
    # ← Enterprise folder is KEPT!
```

## The Solution

**Simply switch to the Enterprise Edition image tag!**

Instead of:
```yaml
image: 'ghcr.io/fazer-ai/chatwoot:latest'
```

Use:
```yaml
image: 'ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee'
# OR
image: 'ghcr.io/fazer-ai/chatwoot:latest-ee'
```

## Available EE Image Tags

Based on the GitHub Container Registry, fazer-ai publishes EE images with `-ee` suffix:

- `ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee` (specific version)
- `ghcr.io/fazer-ai/chatwoot:latest-ee` (latest EE version)

## Steps to Fix in Coolify

1. **Update docker-compose.coolify.yaml:**

   Change from:
   ```yaml
   rails:
     image: 'ghcr.io/fazer-ai/chatwoot:latest'
     pull_policy: always
   ```

   To:
   ```yaml
   rails:
     image: 'ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee'
     # OR use latest-ee for automatic updates
     # image: 'ghcr.io/fazer-ai/chatwoot:latest-ee'
     pull_policy: always
   ```

   Also update the `sidekiq` service:
   ```yaml
   sidekiq:
     image: 'ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee'
     pull_policy: always
   ```

2. **Redeploy in Coolify**

3. **Verify after deployment:**

   ```ruby
   # In Rails console
   ChatwootApp.enterprise?  # Should return: true
   ChatwootApp.extensions   # Should return: ["enterprise"]
   ChatwootHub.pricing_plan # Should return: "enterprise" (if config is set)
   ```

## Why This Works

The EE image:
- ✅ **Contains the enterprise folder** (not stripped)
- ✅ **Sets `CW_EDITION="ee"`** environment variable
- ✅ **Has all Enterprise code** included
- ✅ **Will pass `ChatwootApp.enterprise?` check** automatically

## Combined Approach

1. **Switch to EE image** (this fixes the enterprise folder issue)
2. **Set database config** (you already did this)
3. **Enable features** (you already did this)

This should work without any code modifications!

## Verification

After switching to the EE image, check:

```ruby
# Should all return true/enterprise
ChatwootApp.enterprise?
ChatwootApp.extensions.include?('enterprise')
ChatwootHub.pricing_plan == 'enterprise'

# Check if Enterprise modules are loaded
Account.ancestors.map(&:name).grep(/Enterprise/)
# Should show Enterprise modules
```

## Benefits

- ✅ No code modifications needed
- ✅ Uses official fazer-ai EE image
- ✅ Gets updates automatically (if using `latest-ee`)
- ✅ Enterprise folder exists, so all checks pass
- ✅ All Enterprise modules will load properly


