# Fix: No Matching Manifest Error

## Problem

The error `no matching manifest for linux/amd64 in the manifest list entries` means:
- The `latest-ee` tag doesn't exist, OR
- It wasn't built for your platform (linux/amd64), OR
- It's not published to the registry

## Solution: Use Specific Version Tag

Based on the GitHub Container Registry, fazer-ai publishes EE images with specific version tags. Use:

```yaml
image: 'ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee'
```

Instead of:
```yaml
image: 'ghcr.io/fazer-ai/chatwoot:latest-ee'
```

## Updated docker-compose

Change both services to use the specific version:

```yaml
rails:
  image: 'ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee'
  pull_policy: always
  # ... rest of config

sidekiq:
  image: 'ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee'
  pull_policy: always
  # ... rest of config
```

## Alternative: Check Available Tags

If you want to find other available EE tags, you can:

1. **Check GitHub Container Registry:**
   - Go to: https://github.com/fazer-ai/chatwoot/pkgs/container/chatwoot
   - Look for tags ending in `-ee`

2. **Use Docker command:**
   ```bash
   # This might not work if registry requires auth, but worth trying
   docker manifest inspect ghcr.io/fazer-ai/chatwoot:latest-ee
   ```

## Why This Happens

Looking at the GitHub Actions workflow (`publish_ee_github_docker.yml`), fazer-ai publishes:
- `${{ env.SANITIZED_REF }}-ee` (version-specific tag)
- `latest-ee` (latest tag)

However, `latest-ee` might:
- Not be published yet
- Only be published on releases (not on every build)
- Have platform-specific issues

## Recommended Approach

**Use the specific version tag** (`v4.8.0-fazer-ai.2-ee`) because:
- ✅ It definitely exists (we saw it in the registry)
- ✅ It's stable and won't change
- ✅ It's built for multiple platforms
- ✅ You can control when to update

When fazer-ai releases a new version, you can update to the new tag manually.

## Quick Fix

Just change:
```yaml
image: 'ghcr.io/fazer-ai/chatwoot:latest-ee'
```

To:
```yaml
image: 'ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee'
```

In both `rails` and `sidekiq` services, then redeploy.


