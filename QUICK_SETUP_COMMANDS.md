# Quick Setup Commands for lucouto

## Step 1: Create Fork on GitHub

1. Go to: https://github.com/fazer-ai/chatwoot
2. Click "Fork" button (top right)
3. Your fork will be at: https://github.com/lucouto/chatwoot

## Step 2: Update Local Repository

Run these commands in your terminal:

```bash
cd /Users/lucianocouto/Projets_apps_github/fork_chatwoot_fazer_ai

# Rename origin to upstream
git remote rename origin upstream

# Add your fork as origin
git remote add origin https://github.com/lucouto/chatwoot.fazer.ai.git

# Verify remotes
git remote -v
```

## Step 3: Commit Your Changes

```bash
# Check what files we modified
git status

# Stage the modified files
git add app/javascript/dashboard/helper/automationHelper.js
git add app/javascript/dashboard/routes/dashboard/settings/automation/operators.js
git add app/services/filter_service.rb

# Commit
git commit -m "fix(automation): Custom attributes filter operators and is_present SQL query

- Add OPERATOR_TYPES_7 with contains/does_not_contain for text attributes
- Fix getOperators to detect custom attributes in create mode
- Fix is_present/is_not_present SQL queries for custom attributes
- Resolves issue where custom attributes only showed 4 operators
- Fixes malformed SQL for is_present/is_not_present operators"
```

## Step 4: Push to Your Fork

```bash
# Push to your fork
git push -u origin main
```

If you get authentication error, use Personal Access Token or SSH:
```bash
# Option 1: Use SSH (if you have SSH keys set up)
git remote set-url origin git@github.com:lucouto/chatwoot.git
git push -u origin main

# Option 2: Use Personal Access Token
# When prompted for password, use your GitHub Personal Access Token
# Generate at: https://github.com/settings/tokens
```

## Step 5: Verify on GitHub

Visit: https://github.com/lucouto/chatwoot

You should see your commits and the modified files.

## Next: Set Up GitHub Actions

After your fork is set up, we'll configure GitHub Actions to automatically build Docker images.

Your image will be available at:
- `ghcr.io/lucouto/chatwoot:main-ee`

Then update Coolify to use:
```yaml
image: 'ghcr.io/lucouto/chatwoot:main-ee'
```

---

## Troubleshooting

### "remote origin already exists"
```bash
git remote remove origin
git remote add origin https://github.com/lucouto/chatwoot.git
```

### "Authentication failed"
1. Generate Personal Access Token: https://github.com/settings/tokens
2. Select scope: `repo`
3. Use token as password when pushing

### "Updates were rejected"
```bash
# Only if you're sure you want to overwrite
git push -u origin main --force
```

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `git remote -v` | View all remotes |
| `git fetch upstream` | Get updates from fazer-ai |
| `git merge upstream/main` | Merge fazer-ai updates |
| `git push origin main` | Push to your fork |

