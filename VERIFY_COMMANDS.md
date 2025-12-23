# Verification Commands for Your Containers

## Your Container Names:
- Rails: `rails-f8kkkgcsko4sogs88k8c80ok`
- Sidekiq: `sidekiq-f8kkkgcsko4sogs88k8c80ok`

## Step 1: Check if File is Mounted

```bash
# Check Rails container
docker exec rails-f8kkkgcsko4sogs88k8c80ok ls -la /app/enterprise/app/services/llm/base_open_ai_service.rb

# View first few lines to confirm it's the modified file
docker exec rails-f8kkkgcsko4sogs88k8c80ok head -10 /app/enterprise/app/services/llm/base_open_ai_service.rb
```

You should see the file with `DEFAULT_API_VERSION` in the output.

## Step 2: Check Logs for Azure Configuration

```bash
# Check Rails logs for Azure messages
docker logs rails-f8kkkgcsko4sogs88k8c80ok --tail 100 | grep -i "azure"

# Or view all recent logs
docker logs rails-f8kkkgcsko4sogs88k8c80ok --tail 50
```

Look for: `Azure OpenAI configured: endpoint=..., version=...`

## Step 3: Test Captain (Trigger a Request)

1. Go to Captain playground in Chatwoot UI
2. Send a test message
3. Then check logs:

```bash
# Watch logs in real-time
docker logs -f rails-f8kkkgcsko4sogs88k8c80ok | grep -i "azure\|openai"
```

You should see:
- `Azure OpenAI request to: ...`
- `Azure OpenAI response code: 200`

## Step 4: Verify in Rails Console

```bash
# Access Rails console
docker exec -it rails-f8kkkgcsko4sogs88k8c80ok bundle exec rails console

# Then check:
service = Llm::BaseOpenAiService.new
service.is_azure  # Should return: true
```

## Quick All-in-One Check

```bash
# Check file exists
echo "=== File Check ==="
docker exec rails-f8kkkgcsko4sogs88k8c80ok test -f /app/enterprise/app/services/llm/base_open_ai_service.rb && echo "✅ File exists" || echo "❌ File missing"

# Check for Azure in logs
echo "=== Azure Logs ==="
docker logs rails-f8kkkgcsko4sogs88k8c80ok --tail 200 | grep -i "azure" | tail -5

# Check file content
echo "=== File Content (first 5 lines) ==="
docker exec rails-f8kkkgcsko4sogs88k8c80ok head -5 /app/enterprise/app/services/llm/base_open_ai_service.rb
```


