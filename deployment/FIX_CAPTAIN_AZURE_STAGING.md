# Fix Captain Azure Configuration in Staging

## Problem

Captain AI is failing with "Resource not found" error when using Azure OpenAI. The issue is:

1. **Endpoint mismatch**: Your endpoint includes `/deployments/gpt-4o-r` but the model is set to `gpt-4o-mini`
2. **RubyLLM limitation**: RubyLLM doesn't natively support Azure OpenAI's URL format

## Current Configuration

From your screenshot:
- **OpenAI API Endpoint**: `https://openai-cnjeunes.openai.azure.com/openai/deployments/gpt-4o-r`
- **OpenAI Model**: `gpt-4o-mini`

## Solution

### Option 1: Fix Configuration (Recommended)

Update your Captain settings in the UI:

1. **OpenAI API Endpoint**: Change to base URL only
   ```
   https://openai-cnjeunes.openai.azure.com/
   ```

2. **OpenAI Model**: Change to match the deployment name from your endpoint
   ```
   gpt-4o-r
   ```

**Note**: RubyLLM may still not work with Azure because it constructs URLs in OpenAI format (`/v1/chat/completions`) instead of Azure format (`/openai/deployments/{deployment}/chat/completions?api-version={version}`).

### Option 2: Use the Azure Patch (If Available)

If you have the Azure patch file mounted in staging (from production), it should handle Azure endpoints correctly. Check if this file exists:

```bash
# On your server
ls -la /opt/chatwoot-patches/enterprise/app/services/llm/base_open_ai_service.rb
```

If it exists, the patch should work. If not, you may need to copy it from production or recreate it.

### Option 3: Verify Deployment Name

Check what deployment names exist in your Azure OpenAI resource:

1. Go to Azure Portal
2. Navigate to your OpenAI resource: `openai-cnjeunes`
3. Check **Deployments** section
4. Verify the actual deployment name (might be `gpt-4o-r` or something else)

Then configure:
- **Endpoint**: `https://openai-cnjeunes.openai.azure.com/`
- **Model**: `<actual-deployment-name>`

## Code Changes Made

I've updated the code to:
1. Extract deployment name from endpoint if it contains `/deployments/`
2. Use that deployment name as the model automatically
3. Normalize Azure endpoints to base URL

However, **RubyLLM still won't work with Azure** because it uses the wrong URL format.

## Recommended Fix

The best solution is to ensure the Azure patch is available in staging. The patch (`base_open_ai_service.rb`) handles Azure endpoints correctly by:
- Detecting Azure endpoints
- Using HTTParty directly instead of RubyLLM
- Constructing correct Azure URLs
- Using `api-key` header instead of `Authorization: Bearer`

## Next Steps

1. **Check if Azure patch exists in staging**:
   ```bash
   docker exec <staging-rails-container> ls -la /app/enterprise/app/services/llm/base_open_ai_service.rb
   ```

2. **If patch doesn't exist**, copy from production or recreate it using the script in the repo

3. **Update Captain settings** to use base URL and correct deployment name

4. **Restart staging Rails container** to load changes

5. **Test Captain** in the playground

## Verification

After fixing, check Rails logs:
```bash
docker logs <staging-rails-container> | grep -i "azure\|openai" | tail -20
```

You should see:
- `Azure OpenAI configured: endpoint=..., version=...`
- `Azure OpenAI request to: ...`
- `Azure OpenAI response code: 200`

