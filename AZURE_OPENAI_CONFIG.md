# Configuring Captain AI with Azure OpenAI

## ✅ Yes, It Works!

Captain AI supports Azure OpenAI deployments through the custom endpoint configuration. The code uses the `CAPTAIN_OPEN_AI_ENDPOINT` setting to connect to Azure OpenAI.

## Azure OpenAI Configuration

### Step 1: Get Your Azure OpenAI Details

You'll need:
1. **Azure OpenAI Resource Name** (e.g., `my-resource`)
2. **Azure OpenAI API Key** (from Azure Portal)
3. **Deployment Name** (the name of your model deployment in Azure)

### Step 2: Configure in Chatwoot

In the Captain Settings page (Settings > Captain), configure:

#### 1. OpenAI API Key
```
Your Azure OpenAI API Key
```
- This is your Azure OpenAI key (not OpenAI key)
- Found in: Azure Portal > Your Resource > Keys and Endpoint

#### 2. OpenAI Model
```
Your Azure Deployment Name
```
- **Important:** This should be your **deployment name** in Azure, not the model name
- Example: If you deployed `gpt-4` as `gpt-4-deployment`, use `gpt-4-deployment`
- Found in: Azure Portal > Your Resource > Deployments

#### 3. OpenAI API Endpoint (optional)
```
https://{your-resource-name}.openai.azure.com/
```
- Replace `{your-resource-name}` with your actual Azure resource name
- **Include the trailing slash** (`/`)
- Example: `https://my-chatwoot-ai.openai.azure.com/`

#### 4. Embedding Model (optional)
```
Your Azure Embedding Deployment Name
```
- If you have embeddings deployed, use the deployment name
- Example: `text-embedding-ada-002-deployment`

## Example Configuration

If your Azure setup is:
- **Resource Name:** `chatwoot-ai`
- **API Key:** `abc123...`
- **GPT-4 Deployment:** `gpt-4-turbo`
- **Embedding Deployment:** `text-embedding-3-small`

Then configure:

```
OpenAI API Key: abc123...
OpenAI Model: gpt-4-turbo
OpenAI API Endpoint: https://chatwoot-ai.openai.azure.com/
Embedding Model: text-embedding-3-small
```

## Important Notes

### 1. Deployment Name vs Model Name
- ❌ **Don't use:** `gpt-4`, `gpt-4o`, `gpt-4o-mini`
- ✅ **Use:** Your actual deployment name from Azure (e.g., `gpt-4-deployment`, `my-gpt4`)

### 2. Endpoint Format
- ✅ **Correct:** `https://resource-name.openai.azure.com/`
- ❌ **Wrong:** `https://resource-name.openai.azure.com` (missing trailing slash)
- ❌ **Wrong:** `https://resource-name.openai.azure.com/v1` (don't include /v1)

The code automatically appends `/v1` to the endpoint.

### 3. API Version
Azure OpenAI may require an API version parameter. If you encounter issues, you might need to check:
- The code uses the standard OpenAI client library
- Azure OpenAI is compatible with OpenAI API format
- Some newer Azure features might require API version headers

## Verification

After configuration:

1. **Test in Captain Settings:**
   - Save the configuration
   - Try creating a test assistant
   - Check if it connects successfully

2. **Check Logs:**
   - If there are connection issues, check Rails logs
   - Look for OpenAI API errors

3. **Test Features:**
   - Create a Captain assistant
   - Test a conversation
   - Verify responses are coming from Azure

## Troubleshooting

### Issue: "Failed to initialize OpenAI client"

**Possible causes:**
- Invalid API key
- Wrong endpoint format
- Network/firewall blocking Azure

**Solution:**
- Verify API key in Azure Portal
- Check endpoint format (must end with `/`)
- Ensure your server can reach Azure OpenAI

### Issue: "Model not found"

**Possible causes:**
- Using model name instead of deployment name
- Deployment doesn't exist in Azure

**Solution:**
- Use the exact deployment name from Azure Portal
- Verify deployment exists and is active

### Issue: "Authentication failed"

**Possible causes:**
- Wrong API key
- Key expired or rotated

**Solution:**
- Regenerate API key in Azure Portal
- Update configuration with new key

## Code Reference

The configuration is used in:
- `enterprise/app/services/llm/base_open_ai_service.rb` - Uses `uri_base` parameter
- `config/initializers/ai_agents.rb` - Configures Agents SDK with `openai_api_base`
- `lib/integrations/openai_base_service.rb` - Uses endpoint for API calls

All these services respect the `CAPTAIN_OPEN_AI_ENDPOINT` configuration.

## Summary

✅ **Azure OpenAI is fully supported!**

Just configure:
1. Azure API Key → `OpenAI API Key`
2. Deployment Name → `OpenAI Model`
3. Azure Endpoint → `OpenAI API Endpoint`

The code handles the rest automatically!


