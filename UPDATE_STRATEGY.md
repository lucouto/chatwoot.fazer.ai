# Update Strategy for Enterprise Edition

## Current Situation

You're using a **specific version tag**:
```yaml
image: 'ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee'
```

## Update Options

### Option 1: Manual Updates (Current - Recommended)

**Pros:**
- ✅ **Stable** - You control exactly when to update
- ✅ **Predictable** - No surprise changes
- ✅ **Testable** - You can test new versions before deploying
- ✅ **Rollback-friendly** - Easy to revert to previous version

**Cons:**
- ❌ **Manual work** - Need to check for new versions
- ❌ **Delayed updates** - Won't get updates automatically

**How to Update:**
1. Check for new releases: https://github.com/fazer-ai/chatwoot/pkgs/container/chatwoot
2. Look for tags ending in `-ee` (e.g., `v4.9.0-fazer-ai.3-ee`)
3. Update docker-compose:
   ```yaml
   image: 'ghcr.io/fazer-ai/chatwoot:v4.9.0-fazer-ai.3-ee'
   ```
4. Redeploy in Coolify

### Option 2: Try `latest-ee` Tag (If Available)

**Pros:**
- ✅ **Automatic updates** - Gets latest EE version automatically
- ✅ **No manual work** - Updates happen on redeploy

**Cons:**
- ❌ **Unpredictable** - Could break with unexpected changes
- ❌ **Harder to rollback** - Can't easily go back to previous version
- ❌ **May not exist** - The tag might not be published consistently

**How to Try:**
```yaml
image: 'ghcr.io/fazer-ai/chatwoot:latest-ee'
```

**Note:** You got an error earlier with `latest-ee`, which suggests it might not be consistently published. You could try it again, but specific version tags are more reliable.

### Option 3: Hybrid Approach (Best of Both)

Use specific version, but check for updates periodically:

1. **Set a reminder** to check for updates monthly/quarterly
2. **Monitor fazer-ai releases** on GitHub
3. **Test new versions** in a staging environment first
4. **Update production** when ready

## Recommended Workflow

### Monthly Check (5 minutes)

1. Visit: https://github.com/fazer-ai/chatwoot/pkgs/container/chatwoot
2. Look for new `-ee` tags
3. If new version available:
   - Read release notes
   - Update docker-compose
   - Redeploy

### Before Major Updates

1. **Backup your database** (Coolify should do this, but verify)
2. **Check release notes** for breaking changes
3. **Update during low-traffic period**
4. **Monitor logs** after deployment
5. **Test critical features** after update

## Finding New Versions

### Method 1: GitHub Container Registry
- Go to: https://github.com/fazer-ai/chatwoot/pkgs/container/chatwoot
- Filter tags by `-ee` suffix
- Sort by date to see newest first

### Method 2: GitHub Releases
- Go to: https://github.com/fazer-ai/chatwoot/releases
- Look for releases with EE versions
- Check if Docker image was published

### Method 3: Watch Repository
- Star/watch the fazer-ai/chatwoot repository
- Get notifications for new releases
- Check if EE image was published

## Version Tag Format

fazer-ai uses this format:
```
v{MAJOR}.{MINOR}.{PATCH}-fazer-ai.{BUILD}-ee
```

Example:
- `v4.8.0-fazer-ai.2-ee` (current)
- `v4.9.0-fazer-ai.1-ee` (hypothetical next version)

## Quick Update Script

You could create a simple script to check for updates:

```bash
#!/bin/bash
# check-ee-updates.sh

CURRENT_VERSION="v4.8.0-fazer-ai.2-ee"
REGISTRY="ghcr.io/fazer-ai/chatwoot"

echo "Checking for new EE versions..."
echo "Current: $CURRENT_VERSION"

# This would require GitHub API or web scraping
# For now, manual check is simpler
```

## Recommendation

**Stick with specific version tags** (`v4.8.0-fazer-ai.2-ee`) because:

1. ✅ **More reliable** - You know exactly what you're running
2. ✅ **Better for production** - No surprise updates
3. ✅ **Easier troubleshooting** - Can reference exact version
4. ✅ **Safer** - You control the update timing

**Update frequency:**
- Check monthly or quarterly
- Update when you need new features or security patches
- Don't feel pressured to update immediately

## Summary

Yes, you'll need to manually update the version tag, but this is actually **better for production** because:
- You maintain control
- You can test before deploying
- You can rollback easily if needed
- You avoid surprise breaking changes

The small manual effort is worth the stability and control you get!


