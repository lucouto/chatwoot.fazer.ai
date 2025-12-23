# Debugging Azure OpenAI Connection

## Issue: No Response (No Errors)

If Captain playground isn't answering but there are no errors, the issue is likely:

1. **Wrong URL format** - Azure needs `/openai/deployments/{deployment}/chat/completions` not `/v1/chat/completions`
2. **Missing API version** - Azure requires `?api-version={version}` query parameter
3. **Client library incompatibility** - OpenAI Ruby gem might not handle Azure format

## Step 1: Check Rails Logs

Check what URL is actually being called:

```bash
# In your VPS or via Coolify logs
docker logs <rails-container> | grep -i "openai\|azure\|captain" | tail -50
```

Or in Rails console:
```ruby
# Check the actual endpoint being used
endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
puts "Endpoint: #{endpoint}"

# Check what the client is configured with
require 'openai'
client = OpenAI::Client.new(
  access_token: InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value,
  uri_base: endpoint
)
puts "Client URI base: #{client.instance_variable_get(:@uri_base)}"
```

## Step 2: Test Direct API Call

Test if Azure OpenAI works directly:

```ruby
# In Rails console
require 'httparty'

endpoint = "https://ccn-openai-sweden.openai.azure.com/openai/deployments/gpt-4.1/chat/completions?api-version=2024-12-01-preview"
api_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value

response = HTTParty.post(
  endpoint,
  headers: {
    'Content-Type' => 'application/json',
    'api-key' => api_key  # Azure uses 'api-key' header, not 'Authorization: Bearer'
  },
  body: {
    messages: [
      { role: 'user', content: 'Hello, test message' }
    ]
  }.to_json
)

puts response.code
puts response.body
```

**Important:** Azure OpenAI uses `api-key` header, not `Authorization: Bearer`!

## Step 3: The Real Issue

The OpenAI Ruby client library likely:
1. Uses `Authorization: Bearer` header (Azure needs `api-key`)
2. Constructs `/v1/chat/completions` path (Azure needs `/openai/deployments/{deployment}/chat/completions`)
3. Doesn't add `api-version` query parameter

## Solution: Code Modification Needed

We need to modify the code to detect Azure endpoints and handle them differently.


