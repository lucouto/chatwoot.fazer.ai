# Azure OpenAI Fix Applied to BaseAiService

## Problem

Captain AI was failing with `RubyLLM::Error (Resource not found)` because:
1. `Captain::Llm::AssistantChatService` uses `Llm::BaseAiService` (not `Llm::BaseOpenAiService`)
2. `Llm::BaseAiService` uses RubyLLM, which doesn't support Azure OpenAI's URL format
3. The existing Azure patch (`base_open_ai_service.rb`) wasn't being used

## Solution

I've modified `enterprise/app/services/llm/base_ai_service.rb` to:
1. **Detect Azure endpoints** automatically
2. **Return a custom wrapper** (`AzureChatWrapper`) that uses HTTParty directly for Azure
3. **Maintain RubyLLM compatibility** - the wrapper implements the same interface as RubyLLM::Chat
4. **Extract deployment name** from endpoint if it contains `/deployments/`

## How It Works

When `Llm::BaseAiService` detects an Azure endpoint:
- It creates an `AzureChatWrapper` instead of using RubyLLM
- The wrapper makes HTTP requests directly to Azure OpenAI
- It constructs the correct Azure URL format: `{base}/openai/deployments/{deployment}/chat/completions?api-version={version}`
- It uses `api-key` header (Azure format) instead of `Authorization: Bearer`
- It returns `RubyLLM::Message` objects for compatibility

## Configuration

Your Captain settings should be:

1. **OpenAI API Endpoint**: 
   - Option A: `https://openai-cnjeunes.openai.azure.com/openai/deployments/gpt-4o-r` (full path)
   - Option B: `https://openai-cnjeunes.openai.azure.com/` (base URL only)
   
   If using Option A, the deployment name (`gpt-4o-r`) will be extracted automatically.

2. **OpenAI Model**: 
   - If endpoint has `/deployments/`, this is ignored (deployment name is extracted from endpoint)
   - Otherwise, use your deployment name: `gpt-4o-r`

3. **OpenAI API Key**: Your Azure OpenAI API key

## Testing

After deploying this change:

1. **Restart staging Rails container**
2. **Test Captain in playground**
3. **Check logs**:
   ```bash
   docker logs <staging-rails-container> | grep -i "azure\|openai" | tail -20
   ```

You should see:
```
Azure OpenAI configured: endpoint=..., version=..., model=...
Azure OpenAI request to: ...
Azure OpenAI response code: 200
```

## Code Changes

- Modified `enterprise/app/services/llm/base_ai_service.rb`:
  - Added Azure endpoint detection
  - Added `AzureChatWrapper` class that implements RubyLLM::Chat interface
  - Extracts deployment name from endpoint automatically
  - Uses HTTParty for Azure requests

- Modified `lib/llm/config.rb`:
  - Normalizes Azure endpoints (extracts base URL if needed)

## Next Steps

1. ✅ Code changes committed
2. ⏳ Deploy to staging
3. ⏳ Test Captain playground
4. ⏳ Verify logs show Azure requests
5. ⏳ If working, deploy to production

## Notes

- The wrapper handles tools, system instructions, and message history
- Tool calls are supported (tools are converted to OpenAI format)
- Event handlers (`on_new_message`, `on_end_message`, etc.) are supported
- Temperature and other parameters are passed through correctly

