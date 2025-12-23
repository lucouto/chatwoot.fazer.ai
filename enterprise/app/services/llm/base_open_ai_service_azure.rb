# Modified version of base_open_ai_service.rb with Azure OpenAI support
# 
# To use: Replace the original file or apply these changes to base_open_ai_service.rb

class Llm::BaseOpenAiService
  DEFAULT_MODEL = 'gpt-4o-mini'.freeze
  DEFAULT_API_VERSION = '2024-12-01-preview'.freeze
  attr_reader :client, :model, :is_azure

  def initialize
    @is_azure = azure_endpoint?
    @api_key = InstallationConfig.find_by!(name: 'CAPTAIN_OPEN_AI_API_KEY').value
    
    if @is_azure
      # For Azure, we'll use HTTParty directly
      @azure_endpoint = build_azure_endpoint
      @azure_api_version = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_VERSION')&.value || DEFAULT_API_VERSION
      Rails.logger.info "Azure OpenAI configured: #{@azure_endpoint}, version: #{@azure_api_version}"
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

  # Override chat method to handle Azure
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
    Rails.logger.debug "Azure OpenAI response: #{response.body}"
    
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


