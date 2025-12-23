# Quick Azure OpenAI Fix for Pre-built Docker Image

## The Problem

You're using `ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee` which doesn't have the Azure fix. You need to either:
1. Build a custom image (best)
2. Use volume mount (quick but fragile)

## Option 1: Volume Mount (Quick Fix - 5 minutes)

### Step 1: Create the Modified File on Your VPS

SSH into your VPS and create the file:

```bash
# Create directory
mkdir -p /path/to/chatwoot-patches/enterprise/app/services/llm

# Create the modified file
cat > /path/to/chatwoot-patches/enterprise/app/services/llm/base_open_ai_service.rb << 'EOF'
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
      Rails.logger.info "Azure OpenAI configured: endpoint=#{@azure_endpoint}, version=#{@azure_api_version}"
      # Create a mock client object that responds to .chat method
      @client = self
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

  # Method to handle chat calls - works for both OpenAI client and Azure
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
      # Build Azure endpoint format: base/openai/deployments/{deployment}
      base = base_endpoint.chomp('/')
      "#{base}/openai/deployments/#{deployment}"
    end
  end

  def azure_chat(parameters)
    require 'httparty'
    
    url = "#{@azure_endpoint}/chat/completions?api-version=#{@azure_api_version}"
    
    Rails.logger.info "Azure OpenAI request to: #{url}"
    Rails.logger.debug "Azure OpenAI parameters: #{parameters.inspect}"
    
    response = HTTParty.post(
      url,
      headers: {
        'Content-Type' => 'application/json',
        'api-key' => @api_key  # Azure uses api-key header, not Authorization: Bearer
      },
      body: parameters.to_json,
      timeout: 60
    )
    
    Rails.logger.info "Azure OpenAI response code: #{response.code}"
    Rails.logger.debug "Azure OpenAI response: #{response.body[0..500]}" # Limit log size
    
    unless response.success?
      error_msg = "Azure OpenAI API error: #{response.code} - #{response.body}"
      Rails.logger.error error_msg
      raise error_msg
    end
    
    response.parsed_response
  rescue StandardError => e
    Rails.logger.error "Azure OpenAI request failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
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
EOF
```

### Step 2: Update Coolify docker-compose

In Coolify, edit your docker-compose and add volume mount to `rails` service:

```yaml
rails:
  image: 'ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee'
  volumes:
    - 'storage:/app/storage'
    - 'assets:/app/public/assets'
    - '/path/to/chatwoot-patches/enterprise/app/services/llm/base_open_ai_service.rb:/app/enterprise/app/services/llm/base_open_ai_service.rb:ro'
  # ... rest of config
```

Also add to `sidekiq` service:

```yaml
sidekiq:
  image: 'ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee'
  volumes:
    - 'storage:/app/storage'
    - '/path/to/chatwoot-patches/enterprise/app/services/llm/base_open_ai_service.rb:/app/enterprise/app/services/llm/base_open_ai_service.rb:ro'
  # ... rest of config
```

### Step 3: Redeploy

Redeploy in Coolify and test!

**⚠️ Note:** This is a temporary fix. If you update the image, you'll need to reapply.

---

## Option 2: Build Custom Image (Permanent)

See `BUILD_CUSTOM_IMAGE.md` for full instructions.

Quick version:
1. Fork fazer-ai/chatwoot on GitHub
2. Apply the fix (copy the file above)
3. Build Docker image
4. Push to your registry
5. Update Coolify to use your image

---

## Which Option?

- **Volume Mount (Option 1):** Quick, works immediately, but fragile
- **Custom Image (Option 2):** Permanent, cleaner, but requires build setup

For now, try Option 1 to get it working, then consider Option 2 for long-term.


