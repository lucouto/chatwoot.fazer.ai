# Check Logs to Debug Response Issue

## Step 1: Check Recent Logs

```bash
# Check for Azure responses
docker logs rails-f8kkkgcsko4sogs88k8c80ok --tail 100 | grep -i "azure\|openai"

# Check for JSON parsing errors
docker logs rails-f8kkkgcsko4sogs88k8c80ok --tail 200 | grep -i "json\|parse\|error"

# Check full recent logs
docker logs rails-f8kkkgcsko4sogs88k8c80ok --tail 50
```

## Step 2: Test in Rails Console

```bash
docker exec -it rails-f8kkkgcsko4sogs88k8c80ok bundle exec rails console
```

Then test what Azure returns:

```ruby
# Get the service
service = Llm::BaseOpenAiService.new

# Test a simple call
response = service.chat(parameters: {
  model: 'gpt-4.1',
  messages: [
    { role: 'user', content: 'What is 2+2? Answer briefly.' }
  ],
  response_format: { type: 'json_object' }
})

# Check the response structure
puts "Response keys: #{response.keys.inspect}"
puts "Choices: #{response['choices'].inspect}"
puts "Message content: #{response.dig('choices', 0, 'message', 'content')}"
```

This will show us what Azure is actually returning.


