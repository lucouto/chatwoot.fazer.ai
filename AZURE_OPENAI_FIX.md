# Azure OpenAI Fix for Captain AI

## The Problem

Azure OpenAI has two key differences from OpenAI:
1. **Header:** Uses `api-key` instead of `Authorization: Bearer`
2. **URL:** Needs `/openai/deployments/{deployment}/chat/completions?api-version={version}`

The OpenAI Ruby client library doesn't handle this automatically.

## Quick Test First

Let's verify Azure works with a direct call. Run this in Rails console:

```ruby
require 'httparty'

endpoint = "https://ccn-openai-sweden.openai.azure.com/openai/deployments/gpt-4.1/chat/completions?api-version=2024-12-01-preview"
api_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value

response = HTTParty.post(
  endpoint,
  headers: {
    'Content-Type' => 'application/json',
    'api-key' => api_key  # Azure uses 'api-key' header!
  },
  body: {
    messages: [
      { role: 'user', content: 'Hello, this is a test' }
    ]
  }.to_json
)

puts "Status: #{response.code}"
puts "Response: #{response.body}"
```

If this works, then we know Azure is accessible and the issue is the client library configuration.

## Solution: Modify BaseOpenAiService

We need to modify `enterprise/app/services/llm/base_open_ai_service.rb` to detect Azure endpoints and handle them differently.

### Modified Code

```ruby
class Llm::BaseOpenAiService
  DEFAULT_MODEL = 'gpt-4o-mini'.freeze
  DEFAULT_API_VERSION = '2024-12-01-preview'.freeze
  attr_reader :client, :model, :is_azure

  def initialize
    @is_azure = azure_endpoint?
    @api_key = InstallationConfig.find_by!(name: 'CAPTAIN_OPEN_AI_API_KEY').value
    
    if @is_azure
      # For Azure, we'll use HTTParty directly instead of OpenAI client
      @azure_endpoint = build_azure_endpoint
      @azure_api_version = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_VERSION')&.value || DEFAULT_API_VERSION
    else
      @client = OpenAI::Client.new(
        access_token: @api_key,
        uri_base: uri_base,
        log_errors: Rails.env.development?
      )
    end
    
    setup_model
  rescue StandardError => e
    raise "Failed to initialize OpenAI client: #{e.message}"
  end

  def chat(parameters: {})
    if @is_azure
      azure_chat(parameters)
    else
      @client.chat(parameters: parameters)
    end
  end

  private

  def azure_endpoint?
    endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    endpoint&.include?('openai.azure.com')
  end

  def build_azure_endpoint
    base_endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    deployment = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value || DEFAULT_MODEL
    
    # If endpoint already includes deployment path, use it
    if base_endpoint&.include?('/deployments/')
      base_endpoint.chomp('/')
    else
      # Build Azure endpoint format
      base = base_endpoint.chomp('/')
      "#{base}/openai/deployments/#{deployment}"
    end
  end

  def azure_chat(parameters)
    require 'httparty'
    
    url = "#{@azure_endpoint}/chat/completions?api-version=#{@azure_api_version}"
    
    response = HTTParty.post(
      url,
      headers: {
        'Content-Type' => 'application/json',
        'api-key' => @api_key  # Azure uses api-key header
      },
      body: parameters.to_json
    )
    
    unless response.success?
      raise "Azure OpenAI API error: #{response.code} - #{response.body}"
    end
    
    response.parsed_response
  end

  def uri_base
    endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    endpoint.presence || 'https://api.openai.com/'
  end

  def setup_model
    config_value = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value
    @model = (config_value.presence || DEFAULT_MODEL)
  end
end
```

## Configuration

After applying the fix, configure:

1. **OpenAI API Key:** Your Azure API key
2. **OpenAI Model:** `gpt-4.1` (deployment name)
3. **OpenAI API Endpoint:** `https://ccn-openai-sweden.openai.azure.com/` (base URL only)
4. **New: API Version** (optional, defaults to `2024-12-01-preview`)

## Alternative: Simpler Fix

If the above is too complex, we can modify just the `chat_helper.rb` to detect Azure and use HTTParty directly for Azure endpoints.

Let me know if you want me to create the actual code file modifications!


