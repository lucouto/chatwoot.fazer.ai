# Deployment Strategy Analysis: Custom Attributes Bug Fix

## Current Situation

- **Current Image**: `ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee`
- **Changes Made**: 
  - Fixed custom attributes filter operators in automation rules (frontend)
  - Fixed `is_present`/`is_not_present` SQL query for custom attributes (backend)
  - Added "Contains" operator support for text custom attributes
- **Deployment**: Coolify
- **Repository**: Already a fork of `fazer-ai/chatwoot`

## Changes Summary

### Files Modified:
1. `app/javascript/dashboard/routes/dashboard/settings/automation/operators.js` - Added OPERATOR_TYPES_7
2. `app/javascript/dashboard/helper/automationHelper.js` - Fixed operator detection and mapping
3. `app/services/filter_service.rb` - Fixed `is_present`/`is_not_present` SQL queries

### Impact:
- **Critical Bug Fix**: `is_present`/`is_not_present` were generating malformed SQL
- **Feature Enhancement**: Added "Contains" operator for text custom attributes
- **User-Facing**: Users can now properly filter by custom attributes containing text

---

## Option 1: Continue Using fazer-ai Image (Manual Patching)

### Approach
Keep using `ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee` and manually apply patches via volume mounts or init scripts.

### Pros ✅
- **No fork maintenance** - Continue using fazer-ai's maintained image
- **Simple setup** - No CI/CD needed
- **Quick to implement** - Can patch via Coolify volumes
- **Low overhead** - Minimal ongoing work

### Cons ❌
- **Patches lost on updates** - Every image pull/update removes your changes
- **Manual process** - Must reapply patches after each update
- **Not version controlled** - Patches exist only in your deployment
- **Fragile** - Volume mounts can break if file paths change
- **No testing** - Can't test patches before deployment
- **Maintenance burden** - Must track which patches are applied

### Implementation
```yaml
# docker-compose.coolify.yaml
services:
  rails:
    image: 'ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee'
    volumes:
      - 'storage:/app/storage'
      - './patches/automationHelper.js:/app/app/javascript/dashboard/helper/automationHelper.js:ro'
      - './patches/operators.js:/app/app/javascript/dashboard/routes/dashboard/settings/automation/operators.js:ro'
      - './patches/filter_service.rb:/app/app/services/filter_service.rb:ro'
```

### When to Use
- Temporary fixes
- Testing changes before committing
- One-off patches
- **Not recommended for production long-term**

---

## Option 2: Create Your Own Fork & Build Images

### Approach
Fork `fazer-ai/chatwoot` (or use your existing fork), commit your changes, set up GitHub Actions to build and push Docker images to your registry.

### Pros ✅
- **Full control** - Complete ownership of your codebase
- **Version control** - All changes tracked in Git
- **Automated builds** - CI/CD handles image building
- **Easy updates** - Can merge upstream changes from fazer-ai
- **Reproducible** - Same code = same image, every time
- **Testing** - Can test changes before deploying
- **Professional** - Industry-standard approach
- **Scalable** - Easy to add more customizations later

### Cons ❌
- **More setup** - Need to configure GitHub Actions
- **Maintenance** - Must keep fork updated with upstream
- **CI/CD costs** - GitHub Actions minutes (free tier: 2000/month)
- **Registry management** - Need to manage Docker registry
- **Learning curve** - If not familiar with CI/CD

### Implementation Steps

1. **Fork fazer-ai/chatwoot** (or use existing fork)
   ```bash
   # If you haven't already
   gh repo fork fazer-ai/chatwoot --clone
   ```

2. **Commit your changes**
   ```bash
   git add app/javascript/dashboard/helper/automationHelper.js
   git add app/javascript/dashboard/routes/dashboard/settings/automation/operators.js
   git add app/services/filter_service.rb
   git commit -m "fix: Custom attributes filter operators in automation rules"
   git push origin main
   ```

3. **Set up GitHub Actions** (modify existing workflow)
   - Copy `.github/workflows/publish_ee_docker.yml`
   - Update `DOCKER_REPO` to your registry
   - Add GitHub Container Registry secrets
   - Enable workflow

4. **Configure GitHub Secrets**
   - `GITHUB_TOKEN` (auto-provided)
   - Or `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` if using Docker Hub

5. **Update Coolify**
   ```yaml
   image: 'ghcr.io/YOUR-USERNAME/chatwoot:v4.8.0-fazer-ai.2-ee-fixed'
   ```

### Estimated Setup Time
- **Initial setup**: 2-4 hours
- **Ongoing maintenance**: 30 min/month (merging upstream updates)

### When to Use
- **Recommended for production**
- Multiple customizations planned
- Long-term deployment
- Team collaboration needed

---

## Option 3: Build Custom Image Locally/Manually

### Approach
Build Docker image locally with your changes, push to your registry, use in Coolify.

### Pros ✅
- **No fork needed** - Can work from local changes
- **Full control** - Build exactly what you need
- **Quick** - No CI/CD setup required
- **Flexible** - Can build on-demand

### Cons ❌
- **Manual process** - Must build and push manually each time
- **Local dependency** - Need Docker/build environment
- **No automation** - Easy to forget to rebuild after changes
- **Time consuming** - Docker builds take 10-30 minutes
- **Not scalable** - Doesn't work well for frequent updates

### Implementation
```bash
# Build image
docker build -t ghcr.io/YOUR-USERNAME/chatwoot:v4.8.0-fazer-ai.2-ee-fixed \
  -f docker/Dockerfile .

# Push to registry
docker push ghcr.io/YOUR-USERNAME/chatwoot:v4.8.0-fazer-ai.2-ee-fixed

# Update Coolify to use new image
```

### When to Use
- One-time fixes
- Testing before setting up CI/CD
- **Not recommended for ongoing maintenance**

---

## Option 4: Contribute Back to fazer-ai

### Approach
Submit a pull request to `fazer-ai/chatwoot` with your bug fixes. If accepted, your changes become part of their official image.

### Pros ✅
- **No maintenance** - fazer-ai maintains the fix
- **Community benefit** - Others get the fix too
- **Upstream integration** - Changes become official
- **Best practice** - Open source contribution

### Cons ❌
- **Uncertainty** - Depends on fazer-ai accepting PR
- **Time** - PR review process can take time
- **May be rejected** - If they have different plans
- **Still need fork** - Until PR is merged and released

### Implementation
1. Fork fazer-ai/chatwoot
2. Create feature branch
3. Commit your fixes
4. Submit PR with clear description
5. Wait for review/merge
6. Use their updated image once released

### When to Use
- Bug fixes (not custom features)
- Want to contribute to community
- Can wait for review process
- **Recommended if fix is generic enough**

---

## Option 5: Hybrid Approach (Recommended)

### Approach
1. **Short-term**: Build custom image manually for immediate deployment
2. **Medium-term**: Set up fork with GitHub Actions for automated builds
3. **Long-term**: Submit PR to fazer-ai, use their image once merged

### Benefits
- **Immediate deployment** - Fix deployed today
- **Automated future** - CI/CD handles updates
- **Community contribution** - Eventually upstream

### Timeline
- **Week 1**: Manual build and deploy
- **Week 2-3**: Set up fork + GitHub Actions
- **Month 2**: Submit PR to fazer-ai
- **Month 3+**: Use fazer-ai image if PR merged

---

## Comparison Matrix

| Factor | Option 1<br/>Manual Patch | Option 2<br/>Fork + CI/CD | Option 3<br/>Local Build | Option 4<br/>Contribute | Option 5<br/>Hybrid |
|--------|---------------------------|---------------------------|---------------------------|-------------------------|---------------------|
| **Setup Time** | 30 min | 2-4 hours | 1 hour | 1-2 hours | 2-4 hours |
| **Maintenance** | High (manual) | Low (automated) | High (manual) | None (if merged) | Low |
| **Control** | Low | High | High | Low | High |
| **Scalability** | Poor | Excellent | Poor | Excellent | Excellent |
| **Cost** | Free | Free (GitHub Actions) | Free | Free | Free |
| **Risk** | High (fragile) | Low | Medium | Low | Low |
| **Best For** | Testing | Production | Quick fix | Community | Production |

---

## Recommendation

### For Your Situation: **Option 2 (Fork + CI/CD)**

**Reasons:**
1. ✅ You have a local clone (ready to fork)
2. ✅ Changes are production-critical (bug fixes)
3. ✅ You're using Coolify (supports custom images easily)
4. ✅ Long-term deployment (needs sustainable solution)
5. ✅ GitHub Actions workflows already exist (just need to modify)
6. ✅ Free GitHub Container Registry available

**Note**: Your current repository points to `fazer-ai/chatwoot`. You'll need to create your own GitHub fork first.

### Quick Start Plan

**Step 0: Create Your GitHub Fork (5 min)**
1. Go to https://github.com/fazer-ai/chatwoot
2. Click "Fork" button (top right)
3. Choose your GitHub account/organization
4. Wait for fork to complete

**Step 1: Update Local Remote (2 min)**
```bash
# Add your fork as a new remote
git remote rename origin upstream
git remote add origin https://github.com/lucouto/chatwoot.git
git remote -v  # Verify both remotes exist
```

**Step 2: Commit Your Changes (5 min)**
```bash
git add app/javascript/dashboard/helper/automationHelper.js
git add app/javascript/dashboard/routes/dashboard/settings/automation/operators.js
git add app/services/filter_service.rb
git commit -m "fix(automation): Custom attributes filter operators and is_present SQL query"
```

**Step 3: Push to Your Fork (2 min)**
```bash
git push -u origin main
```

**Step 4: Set up GitHub Actions (2 hours)**
   - Copy `.github/workflows/publish_ee_docker.yml`
   - Modify to push to `ghcr.io/lucouto/chatwoot`
   - Update `DOCKER_REPO` in workflow
   - Enable workflow in GitHub
   - First build will create your image

**Step 5: Update Coolify** (5 min)
   ```yaml
   image: 'ghcr.io/lucouto/chatwoot:main-ee'
   ```

**Step 6: Future Updates** - Merge upstream from fazer-ai
   ```bash
   git fetch upstream
   git merge upstream/main
   git push origin main
   ```

---

## Cost Analysis

### Option 2 (Fork + CI/CD) Costs:
- **GitHub Actions**: 
  - Free tier: 2,000 minutes/month
  - Docker build: ~15-20 minutes per build
  - Can build ~100-130 times/month for free
  - **Your usage**: ~2-4 builds/month = **$0**
- **GitHub Container Registry**: 
  - Free for public repos
  - Private: $0.25/GB storage, $0.50/GB transfer
  - **Your usage**: ~500MB storage = **$0.13/month** (if private)

**Total: ~$0-0.13/month**

---

## Risk Assessment

### Option 1 (Manual Patch)
- **Risk Level**: 🔴 High
- **Failure Points**: 
  - Volume mounts break on updates
  - File paths change
  - Easy to forget to reapply
- **Impact**: Production downtime if patch fails

### Option 2 (Fork + CI/CD)
- **Risk Level**: 🟢 Low
- **Failure Points**: 
  - GitHub Actions outage (rare)
  - Merge conflicts with upstream (manageable)
- **Impact**: Minimal, can fall back to manual build

---

## Final Recommendation

**Go with Option 2 (Fork + CI/CD)** because:

1. ✅ You're already set up for it (have fork, workflows exist)
2. ✅ Changes are critical bug fixes (need reliability)
3. ✅ Low ongoing maintenance
4. ✅ Professional, scalable solution
5. ✅ Can still contribute back to fazer-ai later (Option 4)

**Next Steps:**
1. Commit your current changes
2. Set up GitHub Actions workflow (modify existing)
3. Build and deploy first image
4. Update Coolify configuration
5. Document the process for future updates

---

## Questions to Consider

1. **How often does fazer-ai release updates?**
   - If frequent → Fork is better (easier to merge)
   - If rare → Manual patch might be acceptable

2. **Do you plan more customizations?**
   - If yes → Fork is essential
   - If no → Manual patch might suffice

3. **Team size?**
   - Solo → Any option works
   - Team → Fork is better (version control, collaboration)

4. **Production criticality?**
   - High → Fork (reliability)
   - Low → Manual patch acceptable

Based on your situation (production deployment, bug fixes, existing fork), **Option 2 is the clear winner**.

