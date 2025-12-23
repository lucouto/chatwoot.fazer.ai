# Next Steps After Fork Setup

## ✅ What We've Done

1. ✅ Created fork: https://github.com/lucouto/chatwoot.fazer.ai
2. ✅ Updated local remotes (origin → your fork, upstream → fazer-ai)
3. ✅ Committed bug fixes for custom attributes

## 📋 Current Status

- **Your fork**: https://github.com/lucouto/chatwoot.fazer.ai
- **Current fazer-ai version**: `v4.8.0-fazer-ai.5-ee` (newer than your `v4.8.0-fazer-ai.2-ee`)
- **Your docker-compose**: Using `latest` (should be `-ee` version)
- **Committed changes**: Custom attributes bug fixes

## 🎯 Next Steps

### Step 1: Push Your Changes to Fork (2 min)

```bash
cd /Users/lucianocouto/Projets_apps_github/fork_chatwoot_fazer_ai

# Check current branch
git branch --show-current

# Push to your fork (replace 'main' if different branch)
git push -u origin main
```

**If you get authentication error:**
- Use Personal Access Token: https://github.com/settings/tokens
- Or use SSH: `git remote set-url origin git@github.com:lucouto/chatwoot.fazer.ai.git`

### Step 2: Set Up GitHub Actions for EE Builds (30 min)

1. **Copy the EE workflow**
   ```bash
   cp .github/workflows/publish_ee_github_docker.yml .github/workflows/publish_my_ee_docker.yml
   ```

2. **Modify the workflow** to push to your registry:
   - Change `GITHUB_REPO` to `ghcr.io/lucouto/chatwoot.fazer.ai`
   - Or keep it as `ghcr.io/${{ github.repository }}` (auto-uses your fork)

3. **Enable the workflow** in GitHub:
   - Go to: https://github.com/lucouto/chatwoot.fazer.ai/actions
   - Enable workflows if needed

4. **Trigger first build**:
   - Push a commit, or
   - Use "Run workflow" button

### Step 3: Update Coolify to Use Your Image

Once GitHub Actions builds your image, update Coolify:

```yaml
# docker-compose.coolify.yaml
services:
  rails:
    image: 'ghcr.io/lucouto/chatwoot.fazer.ai:main-ee'
    # OR use specific tag after first build
    # image: 'ghcr.io/lucouto/chatwoot.fazer.ai:v4.8.0-fazer-ai.2-ee-fixed'
    
  sidekiq:
    image: 'ghcr.io/lucouto/chatwoot.fazer.ai:main-ee'
```

## 🔄 Updating from fazer-ai

When fazer-ai releases updates (like `v4.8.0-fazer-ai.5-ee`):

```bash
# Fetch updates from fazer-ai
git fetch upstream

# Merge into your branch
git merge upstream/main

# Push to your fork (triggers new build)
git push origin main
```

## 📦 Image Tags

Your images will be available at:
- `ghcr.io/lucouto/chatwoot.fazer.ai:main-ee` (latest from main branch)
- `ghcr.io/lucouto/chatwoot.fazer.ai:v4.8.0-fazer-ai.2-ee-fixed` (if you tag it)

## ⚠️ Important Notes

1. **Always use `-ee` suffix** - Your builds will automatically be Enterprise Edition
2. **The workflow sets `CW_EDITION="ee"`** - Enterprise folder is included
3. **Your bug fixes are included** - All your commits are in the image
4. **Can merge fazer-ai updates** - Easy to stay up-to-date

## 🚀 Quick Command Reference

```bash
# View remotes
git remote -v

# Push to your fork
git push origin main

# Pull fazer-ai updates
git fetch upstream
git merge upstream/main
git push origin main

# Check your images
# Visit: https://github.com/lucouto/chatwoot.fazer.ai/pkgs/container/chatwoot.fazer.ai
```

## 📝 Summary

- ✅ Fork created
- ✅ Remotes configured  
- ✅ Changes committed
- ⏳ **Next**: Push to fork
- ⏳ **Then**: Set up GitHub Actions
- ⏳ **Finally**: Update Coolify

Your Enterprise Edition image with bug fixes will be ready! 🎉



