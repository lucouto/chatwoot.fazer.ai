# Setting Up PostgreSQL Backups in Coolify

## Quick Setup (Before Deployment)

### Step 1: Access Your PostgreSQL Database in Coolify

1. **Log in to Coolify Dashboard**
   - Open your Coolify instance URL
   - Log in with your credentials

2. **Navigate to Your Project**
   - Click on **"Projects"** in the left sidebar
   - Select the project that contains your Chatwoot application

3. **Find Your PostgreSQL Database**
   - Look for your PostgreSQL database service/resource
   - It might be named something like:
     - `postgres`
     - `chatwoot-postgres`
     - Or the name you gave it during setup
   - Click on it to open the database details

---

### Step 2: Configure Backups

1. **Open Backups Tab**
   - In the database resource view, click on the **"Backups"** tab
   - You should see backup configuration options

2. **Add Backup Schedule**
   - Click the **"Add"** or **"Configure"** button
   - You'll see options for:
     - **Backup Schedule** (cron expression)
     - **Databases to backup**
     - **Storage location**

3. **Set Backup Frequency**
   
   **Recommended for Production:**
   - **Daily at midnight**: `0 0 * * *`
   - **Every 6 hours**: `0 */6 * * *`
   - **Every 12 hours**: `0 */12 * * *`
   
   **For now (before deployment):**
   - You can set it to run immediately or use a simple schedule
   - The important thing is to create at least ONE backup before deploying

4. **Specify Database**
   - In the "Databases" field, enter: `chatwoot_production`
   - Or leave it empty to backup all databases
   - (Check your `POSTGRES_DB` environment variable to confirm the exact name)

5. **Storage Location**
   - **Local storage** (default): Backups stored on the Coolify server
   - **S3-compatible storage** (optional): For off-site backups
     - If you want S3, you'll need to configure it first (see below)

6. **Save Configuration**
   - Click **"Save"** to apply the backup settings

---

### Step 3: Create Your First Backup (Before Deployment)

1. **Manual Backup**
   - In the Backups tab, click **"Backup Now"** or **"Create Backup"**
   - Wait for the backup to complete
   - You should see a new backup entry with timestamp

2. **Verify Backup**
   - Check that the backup file size is reasonable (not 0 bytes)
   - Note the backup timestamp - you'll need this if you need to restore

---

## Optional: Configure S3 Storage (Recommended for Production)

If you want to store backups in cloud storage (S3, DigitalOcean Spaces, etc.):

### Step 1: Add S3 Storage in Coolify

1. **Navigate to S3 Storages**
   - In Coolify sidebar, go to **"S3 Storages"** (or "Storage" section)
   - Click **"Add"** to create a new storage

2. **Configure S3 Connection**
   - **Name**: Give it a name (e.g., "Backup Storage")
   - **Endpoint**: Your S3-compatible endpoint
     - AWS S3: `https://s3.amazonaws.com` or region-specific
     - DigitalOcean Spaces: `https://<region>.digitaloceanspaces.com`
     - Other S3-compatible: Your provider's endpoint
   - **Bucket**: Your bucket name
   - **Access Key**: Your S3 access key
   - **Secret Key**: Your S3 secret key
   - **Region**: (if applicable)

3. **Validate Connection**
   - Click **"Validate"** or **"Test Connection"**
   - Make sure it succeeds before proceeding

4. **Save Storage Configuration**
   - Click **"Save"**

### Step 2: Enable S3 in Backup Settings

1. **Return to Database Backups**
   - Go back to your PostgreSQL database → Backups tab

2. **Enable S3 Storage**
   - Find **"Save to S3"** option
   - Toggle it ON
   - Select your configured S3 storage from the dropdown

3. **Save Settings**
   - Click **"Save"** to apply

---

## Recommended Backup Schedule

### Production Environment:
- **Frequency**: Daily at 2 AM: `0 2 * * *`
- **Retention**: Keep last 30 days
- **Storage**: S3-compatible (off-site)

### Staging/Development:
- **Frequency**: Weekly: `0 0 * * 0` (Sunday midnight)
- **Retention**: Keep last 7 days
- **Storage**: Local is fine

---

## Before Deploying Your Update

### ✅ Pre-Deployment Checklist:

1. [ ] Backups are configured in Coolify
2. [ ] At least one backup has been created successfully
3. [ ] Backup file size is reasonable (verify it's not empty)
4. [ ] You know where backups are stored
5. [ ] You've tested restore process (optional but recommended)

### Quick Pre-Deployment Backup:

1. Go to PostgreSQL database → Backups tab
2. Click **"Backup Now"**
3. Wait for completion
4. Verify backup exists and has size > 0
5. **Now you're safe to deploy!** 🚀

---

## Restore from Backup

If you need to restore after deployment:

1. **Go to Backups Tab**
   - Navigate to your PostgreSQL database → Backups tab

2. **Select Backup**
   - Find the backup you want to restore
   - Check the timestamp to ensure it's from before the deployment

3. **Restore**
   - Click **"Restore"** button
   - Confirm the restore action
   - Wait for restore to complete

4. **Verify**
   - Check that your application is working
   - Verify data is correct

---

## Troubleshooting

### "Backups tab not visible"
- Make sure you're looking at a PostgreSQL database resource, not a regular service
- PostgreSQL databases in Coolify should have a Backups tab

### "Backup failed"
- Check PostgreSQL container is running
- Verify database credentials are correct
- Check Coolify logs for error messages
- Ensure there's enough disk space

### "Can't find my PostgreSQL database"
- It might be part of your docker-compose stack
- Check if it's listed as a separate resource or as part of your application
- In Coolify, databases can be:
  - Standalone database resources
  - Part of a docker-compose stack (like in your case)

### If PostgreSQL is in docker-compose (your case):

If your PostgreSQL is defined in `docker-compose.coolify.yaml` as part of your stack:

1. **Option 1**: Coolify might still show it as a database resource
   - Check if it appears in your project resources

2. **Option 2**: Use manual backup script
   - Use the `deployment/backup_database.sh` script
   - Or use Coolify's terminal/SSH access to run pg_dump

3. **Option 3**: Add PostgreSQL as separate resource
   - You could migrate PostgreSQL to a separate database resource in Coolify
   - This would give you the full backup UI
   - (More complex, but better long-term)

---

## Quick Reference

### Common Cron Expressions:
- `0 0 * * *` - Daily at midnight
- `0 2 * * *` - Daily at 2 AM
- `0 */6 * * *` - Every 6 hours
- `0 */12 * * *` - Every 12 hours
- `0 0 * * 0` - Weekly on Sunday

### Database Name:
Check your environment variables or docker-compose:
- `POSTGRES_DB` or `POSTGRES_DATABASE`
- Default in your setup: `chatwoot_production`

---

## Next Steps

1. ✅ Set up backups in Coolify (follow steps above)
2. ✅ Create a manual backup before deploying
3. ✅ Deploy your update
4. ✅ Monitor application after deployment
5. ✅ Keep backup for 24-48 hours after successful deployment

**You're ready to deploy safely!** 🎉

