# Next Steps: Mount the Azure Fix File

## ✅ Step 1: File Created (Done!)

You've created the file at:
```
/opt/chatwoot-patches/enterprise/app/services/llm/base_open_ai_service.rb
```

## Step 2: Update Coolify docker-compose

In Coolify, edit your docker-compose configuration and add the volume mount to **both** `rails` and `sidekiq` services.

### For Rails Service:

Add this volume mount to the existing volumes:

```yaml
rails:
  image: 'ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee'
  volumes:
    - 'storage:/app/storage'
    - 'assets:/app/public/assets'
    # ADD THIS LINE:
    - '/opt/chatwoot-patches/enterprise/app/services/llm/base_open_ai_service.rb:/app/enterprise/app/services/llm/base_open_ai_service.rb:ro'
  # ... rest of config
```

### For Sidekiq Service:

Add this volume mount:

```yaml
sidekiq:
  image: 'ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee'
  volumes:
    - 'storage:/app/storage'
    # ADD THIS LINE:
    - '/opt/chatwoot-patches/enterprise/app/services/llm/base_open_ai_service.rb:/app/enterprise/app/services/llm/base_open_ai_service.rb:ro'
  # ... rest of config
```

**Important:** The `:ro` at the end means "read-only" - the container can read the file but not modify it.

## Step 3: Save and Redeploy

1. **Save** the docker-compose changes in Coolify
2. **Redeploy** the service
3. Wait for deployment to complete

## Step 4: Verify the Fix is Loaded

After redeploy, check the logs to confirm Azure OpenAI is being used:

```bash
# In Coolify logs or via SSH
docker logs <rails-container> | grep -i "azure" | tail -10
```

You should see:
```
Azure OpenAI configured: endpoint=..., version=...
```

## Step 5: Test Captain Playground

1. Go to Captain playground in Chatwoot
2. Try sending a test message
3. It should now work with Azure OpenAI!

## Troubleshooting

### If it still doesn't work:

1. **Check logs:**
   ```bash
   docker logs <rails-container> | grep -i "azure\|openai\|captain" | tail -20
   ```

2. **Verify file is mounted:**
   ```bash
   docker exec <rails-container> ls -la /app/enterprise/app/services/llm/base_open_ai_service.rb
   ```

3. **Check file content in container:**
   ```bash
   docker exec <rails-container> head -20 /app/enterprise/app/services/llm/base_open_ai_service.rb
   ```

4. **Restart Rails:**
   - Sometimes Rails needs a full restart to reload the file
   - Try redeploying again

## Configuration Reminder

Make sure your Captain settings are:
- **OpenAI API Key:** Your Azure API key
- **OpenAI Model:** `gpt-4.1` (deployment name)
- **OpenAI API Endpoint:** `https://ccn-openai-sweden.openai.azure.com/` (base URL)

The code will automatically detect it's Azure and use the correct format!


