# Captain Azure OpenAI Fix for Staging

## Problem

Captain AI is failing with `RubyLLM::Error (Resource not found)` because:

1. **RubyLLM doesn't support Azure OpenAI format**: RubyLLM constructs URLs like `{base}/v1/chat/completions`, but Azure needs `{base}/openai/deployments/{deployment}/chat/completions?api-version={version}`
2. **Configuration mismatch**: Your endpoint has `/deployments/gpt-4o-r` but model is `gpt-4o-mini`

## Root Cause

The codebase uses `Llm::BaseAiService` which uses RubyLLM. RubyLLM doesn't natively support Azure OpenAI's URL format, so it fails when trying to make requests.

## Solution

You need the **Azure patch** (`base_open_ai_service.rb`) that handles Azure endpoints correctly. This patch:
- Detects Azure endpoints automatically
- Uses HTTParty directly (bypasses RubyLLM for Azure)
- Constructs correct Azure URLs
- Uses `api-key` header (Azure format) instead of `Authorization: Bearer`

## Quick Fix Steps

### 1. Check if Azure Patch Exists in Staging

```bash
# Find staging Rails container
STAGING_RAILS=$(docker ps --format '{{.Names}}' | grep -i rails | head -1)

# Check if patch exists
docker exec $STAGING_RAILS ls -la /app/enterprise/app/services/llm/base_open_ai_service.rb
```

### 2. If Patch Doesn't Exist, Copy from Production

```bash
# Find production Rails container
PROD_RAILS=$(docker ps --format '{{.Names}}' | grep -i rails | grep -v staging | head -1)

# Check if it exists in production
docker exec $PROD_RAILS ls -la /opt/chatwoot-patches/enterprise/app/services/llm/base_open_ai_service.rb

# If it exists, copy it to staging
# (You'll need to copy it via the host filesystem or recreate it)
```

### 3. Recreate the Azure Patch (If Needed)

The patch file should be at:
```
/opt/chatwoot-patches/enterprise/app/services/llm/base_open_ai_service.rb
```

And mounted in your staging compose file as:
```yaml
volumes:
  - '/opt/chatwoot-patches/enterprise/app/services/llm/base_open_ai_service.rb:/app/enterprise/app/services/llm/base_open_ai_service.rb:ro'
```

### 4. Update Captain Configuration

In Captain Settings UI:
- **OpenAI API Endpoint**: `https://openai-cnjeunes.openai.azure.com/` (base URL only, no `/deployments/`)
- **OpenAI Model**: `gpt-4o-r` (the actual deployment name from Azure)

### 5. Restart Staging

Restart the staging Rails container to load the patch.

### 6. Verify

Check logs:
```bash
docker logs $STAGING_RAILS | grep -i "azure\|openai" | tail -20
```

You should see:
```
Azure OpenAI configured: endpoint=..., version=...
Azure OpenAI request to: ...
Azure OpenAI response code: 200
```

## Code Changes Made

I've updated:
1. `lib/llm/config.rb` - Normalizes Azure endpoints
2. `enterprise/app/services/llm/base_ai_service.rb` - Extracts deployment name from endpoint

However, **these changes alone won't fix the issue** because RubyLLM still doesn't support Azure. You need the Azure patch.

## Why the Patch is Needed

The Azure patch (`base_open_ai_service.rb`) overrides the default RubyLLM behavior for Azure endpoints by:
1. Detecting Azure endpoints (checks for `openai.azure.com`)
2. Using HTTParty directly instead of RubyLLM
3. Building correct Azure URLs: `{base}/openai/deployments/{deployment}/chat/completions?api-version={version}`
4. Using `api-key` header instead of `Authorization: Bearer`

Without this patch, RubyLLM will always fail with Azure because it uses the wrong URL format.

## Next Steps

1. ✅ Verify Azure patch exists in staging (or copy from production)
2. ✅ Update Captain settings (base URL + deployment name)
3. ✅ Restart staging
4. ✅ Test Captain in playground
5. ✅ Check logs for Azure requests

