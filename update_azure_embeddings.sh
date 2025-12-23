#!/bin/bash
# Update base_open_ai_service.rb with embeddings support for Azure

cat > /opt/chatwoot-patches/enterprise/app/services/llm/base_open_ai_service.rb << 'ENDOFFILE'
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

  # Method to handle embeddings calls - works for both OpenAI client and Azure
  def embeddings(parameters: {})
    if @is_azure
      azure_embeddings(parameters)
    else
      @client.embeddings(parameters: parameters)
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

  def azure_embeddings(parameters)
    require 'httparty'
    
    # Extract model from parameters or use default
    embedding_model = parameters[:model] || parameters['model'] || 'text-embedding-3-small'
    
    # Build Azure embeddings endpoint: base/openai/deployments/{embedding_model}/embeddings
    base_endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    base = base_endpoint.chomp('/').sub(%r{/openai/deployments/.*}, '') # Remove any existing deployment path
    embeddings_endpoint = "#{base}/openai/deployments/#{embedding_model}"
    url = "#{embeddings_endpoint}/embeddings?api-version=#{@azure_api_version}"
    
    # Prepare request body (Azure expects 'input' not nested in parameters)
    request_body = {
      input: parameters[:input] || parameters['input']
    }
    
    Rails.logger.info "Azure OpenAI embeddings request to: #{url}"
    Rails.logger.debug "Azure OpenAI embeddings parameters: #{request_body.inspect}"
    
    response = HTTParty.post(
      url,
      headers: {
        'Content-Type' => 'application/json',
        'api-key' => @api_key
      },
      body: request_body.to_json,
      timeout: 60
    )
    
    Rails.logger.info "Azure OpenAI embeddings response code: #{response.code}"
    Rails.logger.debug "Azure OpenAI embeddings response: #{response.body[0..500]}" # Limit log size
    
    unless response.success?
      error_msg = "Azure OpenAI embeddings API error: #{response.code} - #{response.body}"
      Rails.logger.error error_msg
      raise error_msg
    end
    
    response.parsed_response
  rescue StandardError => e
    Rails.logger.error "Azure OpenAI embeddings request failed: #{e.message}"
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
ENDOFFILE

echo "File updated successfully!"
echo "Location: /opt/chatwoot-patches/enterprise/app/services/llm/base_open_ai_service.rb"
echo ""
echo "Next step: Restart your Rails container in Coolify to apply the changes."


