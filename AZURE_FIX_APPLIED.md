# Azure OpenAI Fix Applied ✅

## What Was Fixed

I've modified `enterprise/app/services/llm/base_open_ai_service.rb` to:

1. ✅ **Detect Azure endpoints** - Automatically detects if endpoint contains `openai.azure.com`
2. ✅ **Use correct header** - Uses `api-key` header for Azure (instead of `Authorization: Bearer`)
3. ✅ **Build correct URL** - Constructs Azure format: `/openai/deployments/{deployment}/chat/completions?api-version={version}`
4. ✅ **Maintain compatibility** - Still works with regular OpenAI endpoints

## Configuration

Make sure your Captain settings are configured as:

1. **OpenAI API Key:** Your Azure OpenAI API key
2. **OpenAI Model:** `gpt-4.1` (your deployment name)
3. **OpenAI API Endpoint:** `https://ccn-openai-sweden.openai.azure.com/` (base URL only)

The code will automatically:
- Detect it's Azure (because of `openai.azure.com` in the endpoint)
- Build the correct URL with deployment path
- Use `api-key` header
- Add API version parameter (defaults to `2024-12-01-preview`)

## Optional: Custom API Version

If you want to use a different API version, you can add it to the database:

```ruby
# In Rails console
config = InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_API_VERSION')
config.value = '2025-01-01-preview'  # or your preferred version
config.locked = false
config.save!
```

## Testing

1. **Restart your Rails application** (or redeploy in Coolify)
2. **Go to Captain playground**
3. **Try a test message**
4. **Check Rails logs** if it doesn't work:
   ```bash
   docker logs <rails-container> | grep -i "azure\|openai" | tail -20
   ```

## What Changed

The service now:
- Checks if endpoint is Azure (`openai.azure.com`)
- If Azure: Uses HTTParty with correct format
- If not Azure: Uses OpenAI client library as before

## Verification

After restart, check logs for:
```
Azure OpenAI configured: endpoint=..., version=...
Azure OpenAI request to: ...
Azure OpenAI response code: 200
```

If you see these logs, Azure is being used correctly!

## Next Steps

1. ✅ Code fix applied
2. ⏳ Restart application (redeploy in Coolify)
3. ⏳ Test Captain playground
4. ⏳ Verify it works

Let me know if you need help with the restart or if you encounter any issues!


