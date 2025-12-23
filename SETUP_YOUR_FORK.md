# Setup Guide: Create Your GitHub Fork

## Current Situation

Your local repository is currently connected to:
- **Origin**: `https://github.com/fazer-ai/chatwoot.git` (fazer-ai's repository)

You need to:
1. Create your own fork on GitHub
2. Update your local repository to point to your fork
3. Push your changes

---

## Step-by-Step Instructions

### Step 1: Create Fork on GitHub (5 minutes)

1. **Go to fazer-ai's repository**
   - Visit: https://github.com/fazer-ai/chatwoot

2. **Click the "Fork" button**
   - Located in the top-right corner of the page
   - Next to "Star" and "Watch"

3. **Choose where to fork**
   - Select your personal GitHub account
   - Or select an organization if you have one

4. **Wait for fork to complete**
   - GitHub will create your fork
   - URL will be: `https://github.com/lucouto/chatwoot`

---

### Step 2: Update Local Repository Remotes (2 minutes)

Run these commands in your local repository:

```bash
cd /Users/lucianocouto/Projets_apps_github/fork_chatwoot_fazer_ai

# Rename current origin to upstream (to track fazer-ai's repo)
git remote rename origin upstream

# Add your fork as the new origin
git remote add origin https://github.com/lucouto/chatwoot.git

# Verify both remotes are set correctly
git remote -v
```

**Expected output:**
```
origin    https://github.com/lucouto/chatwoot.git (fetch)
origin    https://github.com/lucouto/chatwoot.git (push)
upstream  https://github.com/fazer-ai/chatwoot.git (fetch)
upstream  https://github.com/fazer-ai/chatwoot.git (push)
```

---

### Step 3: Check Current Branch and Status (1 minute)

```bash
# Check what branch you're on
git branch

# Check if you have uncommitted changes
git status
```

**If you have uncommitted changes** (our bug fixes), proceed to Step 4.
**If everything is committed**, proceed to Step 5.

---

### Step 4: Commit Your Bug Fixes (5 minutes)

If you haven't committed the changes we made:

```bash
# Stage the modified files
git add app/javascript/dashboard/helper/automationHelper.js
git add app/javascript/dashboard/routes/dashboard/settings/automation/operators.js
git add app/services/filter_service.rb

# Commit with a descriptive message
git commit -m "fix(automation): Custom attributes filter operators and is_present SQL query

- Add OPERATOR_TYPES_7 with contains/does_not_contain for text attributes
- Fix getOperators to detect custom attributes in create mode
- Fix is_present/is_not_present SQL queries for custom attributes
- Resolves issue where custom attributes only showed 4 operators
- Fixes malformed SQL for is_present/is_not_present operators"

# Verify commit
git log --oneline -1
```

---

### Step 5: Push to Your Fork (2 minutes)

```bash
# Push your current branch to your fork
# Replace 'main' with your branch name if different
git push -u origin main
```

**If you get an error about upstream branch:**
```bash
# Set upstream tracking
git push -u origin main --set-upstream
```

**If you get authentication error:**
- Use GitHub Personal Access Token instead of password
- Or use SSH: `git remote set-url origin git@github.com:YOUR-USERNAME/chatwoot.git`

---

### Step 6: Verify on GitHub (1 minute)

1. **Visit your fork**: `https://github.com/lucouto/chatwoot`
2. **Check that your commits are there**
3. **Verify the files we modified are updated**

---

## Quick Reference: Remote Commands

### View remotes
```bash
git remote -v
```

### Update upstream (when fazer-ai releases updates)
```bash
git fetch upstream
git merge upstream/main
git push origin main
```

### Push to your fork
```bash
git push origin main
```

### Pull from your fork
```bash
git pull origin main
```

---

## Troubleshooting

### Error: "remote origin already exists"
```bash
# Remove existing origin
git remote remove origin

# Add your fork
git remote add origin https://github.com/lucouto/chatwoot.git
```

### Error: "Authentication failed"
**Option 1: Use Personal Access Token**
1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate new token with `repo` scope
3. Use token as password when pushing

**Option 2: Use SSH**
```bash
git remote set-url origin git@github.com:lucouto/chatwoot.git
```

### Error: "Updates were rejected"
```bash
# If your fork has different history, force push (use carefully!)
git push -u origin main --force
```

**⚠️ Warning**: Only use `--force` if you're sure you want to overwrite remote history.

---

## Next Steps After Fork Setup

Once your fork is set up:

1. ✅ **Set up GitHub Actions** (see `DEPLOYMENT_STRATEGY_ANALYSIS.md`)
2. ✅ **Build Docker images automatically**
3. ✅ **Deploy to Coolify**

---

## Alternative: Use GitHub CLI

If you have `gh` CLI installed:

```bash
# Fork the repository
gh repo fork fazer-ai/chatwoot --clone=false

# Update your local remote
git remote rename origin upstream
git remote add origin https://github.com/lucouto/chatwoot.git
```

---

## Summary

**Total time**: ~15 minutes
- Fork on GitHub: 5 min
- Update remotes: 2 min
- Commit changes: 5 min
- Push to fork: 2 min
- Verify: 1 min

**Result**: Your own GitHub fork ready for CI/CD setup! 🎉

