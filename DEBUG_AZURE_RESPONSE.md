# Debug Azure OpenAI Response Issue

## The Problem

Captain is connecting to Azure but giving generic responses. This suggests:
1. Azure is returning responses, but they're not being parsed correctly
2. The response format might be different from what the code expects
3. JSON parsing might be failing

## Step 1: Check What Azure is Actually Returning

Run this in Rails console to see the raw response:

```bash
docker exec -it rails-f8kkkgcsko4sogs88k8c80ok bundle exec rails console
```

Then:

```ruby
# Test Azure directly
require 'httparty'

endpoint = "https://ccn-openai-sweden.openai.azure.com/openai/deployments/gpt-4.1/chat/completions?api-version=2024-12-01-preview"
api_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value

response = HTTParty.post(
  endpoint,
  headers: {
    'Content-Type' => 'application/json',
    'api-key' => api_key
  },
  body: {
    model: 'gpt-4.1',
    messages: [
      { role: 'user', content: 'Test question: what is 2+2?' }
    ],
    response_format: { type: 'json_object' }
  }.to_json
)

puts "Status: #{response.code}"
puts "Full response:"
puts response.parsed_response.inspect
puts "\nContent:"
puts response.parsed_response.dig('choices', 0, 'message', 'content')
```

This will show us what Azure is actually returning.

## Step 2: Check Rails Logs

```bash
# Check for errors or response content
docker logs rails-f8kkkgcsko4sogs88k8c80ok --tail 200 | grep -i "azure\|openai\|json\|parse"
```

Look for:
- JSON parsing errors
- Response content
- Any error messages

## Step 3: Check if response_format is the issue

Azure OpenAI might not support `response_format: { type: 'json_object' }` the same way OpenAI does. We might need to:
1. Remove the response_format requirement
2. Handle plain text responses
3. Adjust the parsing logic


