# Database Backup Guide for Chatwoot

## Quick Backup Options

### Option 1: Use Coolify's Built-in Backup (Recommended)

Coolify has a built-in backup feature that's the easiest to use:

1. **Access Coolify Dashboard**
   - Go to your Coolify project
   - Navigate to your PostgreSQL database service

2. **Create Backup**
   - Click on the **"Backups"** tab
   - Click **"Create Backup"** button
   - Wait for backup to complete

3. **Before Deployment**
   - Always create a backup before deploying updates
   - Coolify will store backups in your configured backup location

4. **Restore if Needed**
   - Go to Backups tab
   - Select the backup you want to restore
   - Click "Restore"

---

### Option 2: Manual Backup Script

If you prefer manual backups or want to automate them:

#### Using the Backup Script

```bash
# From your local machine (if you have SSH access)
cd /path/to/your/chatwoot/deployment
./backup_database.sh

# Or specify a custom backup directory
./backup_database.sh /path/to/backups
```

#### Prerequisites

The script needs access to PostgreSQL. It will try:
1. Direct `pg_dump` command (if PostgreSQL tools are installed)
2. Docker container (if PostgreSQL is in a container)
3. Fall back to instructions if neither works

#### Environment Variables

Set these if needed:
```bash
export POSTGRES_HOST=postgres
export POSTGRES_PORT=5432
export POSTGRES_USER=your_user
export POSTGRES_PASSWORD=your_password
export POSTGRES_DB=chatwoot_production
```

---

### Option 3: Quick Manual Backup via Docker

If your PostgreSQL is running in Docker/Coolify:

```bash
# Find your PostgreSQL container
docker ps | grep postgres

# Create backup
docker exec <postgres-container-name> \
  pg_dump -U <username> -d chatwoot_production \
  | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

---

## Before Deploying Updates

**Always create a backup first!**

1. ✅ Create backup (using any method above)
2. ✅ Verify backup file exists and has reasonable size
3. ✅ Deploy update
4. ✅ Monitor application after deployment
5. ✅ Keep backup for at least 24-48 hours after successful deployment

---

## Restore from Backup

### Using Coolify
1. Go to Backups tab
2. Select backup
3. Click "Restore"

### Using Manual Backup

```bash
# Decompress and restore
gunzip < backup_file.sql.gz | \
  psql -h <postgres-host> -U <username> -d chatwoot_production
```

Or via Docker:
```bash
gunzip < backup_file.sql.gz | \
  docker exec -i <postgres-container> \
  psql -U <username> -d chatwoot_production
```

---

## Automated Backups (Optional)

### Cron Job Example

Add to crontab for daily backups at 2 AM:

```bash
0 2 * * * /path/to/deployment/backup_database.sh /path/to/backups >> /var/log/chatwoot_backup.log 2>&1
```

### Coolify Scheduled Backups

Coolify can be configured to automatically create backups:
- Go to your database service settings
- Configure backup schedule (daily, weekly, etc.)
- Set retention policy

---

## Backup Best Practices

1. **Regular Backups**: Daily for production, weekly for staging
2. **Pre-Deployment**: Always backup before major updates
3. **Test Restores**: Periodically test that backups can be restored
4. **Off-Site Storage**: Consider storing backups in cloud storage (S3, etc.)
5. **Retention**: Keep backups for at least 30 days, longer for production
6. **Encryption**: Encrypt backups if they contain sensitive data

---

## Troubleshooting

### "Could not find PostgreSQL container"
- Make sure PostgreSQL is running: `docker ps | grep postgres`
- Check container name matches what the script expects

### "Permission denied"
- Make sure backup directory is writable
- Check PostgreSQL user has read permissions

### "Connection refused"
- Verify PostgreSQL is accessible
- Check firewall/network settings
- Verify credentials are correct

---

## Quick Check Before Deployment

Run this checklist:

- [ ] Backup created and verified
- [ ] Backup file size looks reasonable (not 0 bytes)
- [ ] Backup location is accessible
- [ ] You know how to restore if needed
- [ ] Ready to deploy! 🚀

