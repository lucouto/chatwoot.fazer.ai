# Azure OpenAI Configuration for Captain AI

## Your Azure OpenAI Details

Based on your Azure Portal:
- **Endpoint:** `https://ccn-openai-sweden.openai.azure.com/`
- **Deployment Name:** `gpt-4.1`
- **API Version:** `2024-12-01-preview` (or `2025-01-01-preview`)
- **API Key:** `<your-api-key>`

## ⚠️ Important: Azure OpenAI URL Structure

Azure OpenAI uses a different URL format than OpenAI:
- **OpenAI:** `https://api.openai.com/v1/chat/completions`
- **Azure:** `https://{resource}.openai.azure.com/openai/deployments/{deployment}/chat/completions?api-version={version}`

## Configuration in Chatwoot

### Option 1: Using OpenAI Ruby Client (Recommended)

The OpenAI Ruby client library should handle Azure OpenAI if configured correctly. Configure:

#### 1. OpenAI API Key
```
<your-api-key>
```
Your Azure OpenAI API key

#### 2. OpenAI Model
```
gpt-4.1
```
Your deployment name (this is correct!)

#### 3. OpenAI API Endpoint
```
https://ccn-openai-sweden.openai.azure.com/openai/deployments/gpt-4.1
```
**Important:** Include the full path with `/openai/deployments/{deployment}`

**OR** try:
```
https://ccn-openai-sweden.openai.azure.com/
```
And let the client library handle the path (may require code modification)

### Option 2: Full Endpoint with API Version (If Needed)

If the client library doesn't automatically handle Azure format, you might need:

```
https://ccn-openai-sweden.openai.azure.com/openai/deployments/gpt-4.1/chat/completions?api-version=2024-12-01-preview
```

However, this might not work with the OpenAI client library as it expects to construct the path itself.

## Testing the Configuration

### Step 1: Configure in UI

1. Go to **Settings > Captain**
2. Enter:
   - **OpenAI API Key:** Your Azure API key
   - **OpenAI Model:** `gpt-4.1`
   - **OpenAI API Endpoint:** `https://ccn-openai-sweden.openai.azure.com/openai/deployments/gpt-4.1`

### Step 2: Test Connection

1. Create a test Captain assistant
2. Try a simple conversation
3. Check Rails logs for any errors

### Step 3: Check Logs

If it doesn't work, check the logs:
```bash
# In Rails console or logs
tail -f log/production.log | grep -i "openai\|azure\|captain"
```

Look for:
- Connection errors
- 404 errors (wrong path)
- 401 errors (auth issues)
- 400 errors (bad request format)

## Potential Issues & Solutions

### Issue 1: Client Library Doesn't Support Azure Format

**Problem:** The OpenAI Ruby client might not automatically handle Azure's URL structure.

**Solution:** You may need to modify the endpoint to include the deployment path, or the code might need adjustment.

### Issue 2: API Version Missing

**Problem:** Azure requires `api-version` query parameter.

**Solution:** The OpenAI client library might handle this automatically, or you might need to include it in the endpoint URL.

### Issue 3: Model Parameter

**Problem:** Azure uses deployment name, not model name.

**Solution:** You're already using `gpt-4.1` which is correct!

## Alternative: Direct API Configuration

If the OpenAI client library doesn't work with Azure, you might need to:

1. **Check the OpenAI gem version** - Newer versions might have better Azure support
2. **Modify the code** - Update the endpoint construction to handle Azure format
3. **Use HTTParty directly** - Bypass the OpenAI client for Azure calls

## Recommended Configuration (Try This First)

Based on your Azure details:

```
OpenAI API Key: <your-api-key>
OpenAI Model: gpt-4.1
OpenAI API Endpoint: https://ccn-openai-sweden.openai.azure.com/openai/deployments/gpt-4.1
```

**Note:** The endpoint includes `/openai/deployments/gpt-4.1` because Azure requires the deployment in the path.

## If It Doesn't Work

If the above doesn't work, the code might need modification to properly support Azure OpenAI's URL structure. The current code assumes OpenAI's format (`/v1/chat/completions`), but Azure needs (`/openai/deployments/{deployment}/chat/completions?api-version={version}`).

Let me know what errors you get, and I can help troubleshoot or provide code modifications if needed!


