# frozen_string_literal: true

# Base service for LLM operations using RubyLLM.
# New features should inherit from this class.
class Llm::BaseAiService
  DEFAULT_MODEL = Llm::Config::DEFAULT_MODEL
  DEFAULT_TEMPERATURE = 1.0
  DEFAULT_API_VERSION = '2024-08-01-preview'.freeze

  attr_reader :model, :temperature, :is_azure

  def initialize
    Llm::Config.initialize!
    setup_model
    setup_temperature
    check_azure_endpoint
  end

  def chat(model: @model, temperature: @temperature)
    # If Azure, return a custom chat wrapper that uses HTTParty
    if @is_azure
      AzureChatWrapper.new(
        endpoint: @azure_endpoint,
        api_version: @azure_api_version,
        api_key: @api_key,
        model: model,
        temperature: temperature
      )
    else
      RubyLLM.chat(model: model).with_temperature(temperature)
    end
  end

  private

  def setup_model
    config_value = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value
    endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    
    # If endpoint contains /deployments/, extract deployment name and use it as model
    if endpoint&.include?('openai.azure.com') && endpoint&.include?('/deployments/')
      deployment_name = extract_deployment_name(endpoint)
      @model = deployment_name if deployment_name.present?
    end
    
    # Fall back to config value or default
    @model ||= (config_value.presence || DEFAULT_MODEL)
  end

  def extract_deployment_name(endpoint)
    # Extract deployment name from: https://resource.openai.azure.com/openai/deployments/gpt-4o-r
    match = endpoint.match(%r{/deployments/([^/?#]+)})
    match ? match[1] : nil
  end

  def setup_temperature
    @temperature = DEFAULT_TEMPERATURE
  end

  def check_azure_endpoint
    endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    @is_azure = endpoint&.include?('openai.azure.com')
    
    if @is_azure
      @api_key = InstallationConfig.find_by!(name: 'CAPTAIN_OPEN_AI_API_KEY').value
      @azure_endpoint = build_azure_endpoint(endpoint)
      @azure_api_version = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_VERSION')&.value || DEFAULT_API_VERSION
      Rails.logger.info "Azure OpenAI configured: endpoint=#{@azure_endpoint}, version=#{@azure_api_version}, model=#{@model}"
    end
  end

  def build_azure_endpoint(endpoint)
    # If endpoint already includes /deployments/, use it as-is
    if endpoint.include?('/deployments/')
      endpoint.split('/chat/completions').first.split('?').first.chomp('/')
    else
      # Build Azure endpoint format: base/openai/deployments/{deployment}
      base = endpoint.chomp('/')
      "#{base}/openai/deployments/#{@model}"
    end
  end

  # Wrapper class to make Azure HTTParty calls compatible with RubyLLM's interface
  class AzureChatWrapper
    require 'httparty'

    attr_reader :messages

    def initialize(endpoint:, api_version:, api_key:, model:, temperature:)
      @endpoint = endpoint
      @api_version = api_version
      @api_key = api_key
      @model = model
      @temperature = temperature
      @params = {}
      @instructions = nil
      @tools = []
      @messages = []
    end

    def with_temperature(temp)
      @temperature = temp
      self
    end

    def with_params(params)
      @params.merge!(params)
      self
    end

    def with_instructions(instructions)
      @instructions = instructions
      self
    end

    def with_tool(tool)
      @tools << tool
      self
    end

    def on_new_message(&block)
      @on_new_message = block
      self
    end

    def on_end_message(&block)
      @on_end_message = block
      self
    end

    def on_tool_call(&block)
      @on_tool_call = block
      self
    end

    def on_tool_result(&block)
      @on_tool_result = block
      self
    end

    def add_message(role:, content:)
      @messages << { role: role.to_s, content: content.to_s }
      self
    end

    def ask(message)
      @on_new_message&.call(self)
      
      # Build messages: system instructions + existing messages + new user message
      api_messages = []
      api_messages << { role: 'system', content: @instructions } if @instructions.present?
      api_messages += @messages.map { |m| { role: m[:role], content: m[:content] } }
      api_messages << { role: 'user', content: message }
      
      parameters = {
        model: @model,
        messages: api_messages,
        temperature: @temperature
      }.merge(@params)

      # Add tools if any
      if @tools.any?
        # Tools are RubyLLM::Tool objects, convert to OpenAI format
        parameters[:tools] = @tools.map do |tool|
          {
            type: 'function',
            function: {
              name: tool.name,
              description: tool.description,
              parameters: tool.parameters
            }
          }
        end
      end

      url = "#{@endpoint}/chat/completions?api-version=#{@api_version}"
      
      Rails.logger.info "Azure OpenAI request to: #{url}"
      Rails.logger.debug "Azure OpenAI parameters: #{parameters.inspect}"

      response = HTTParty.post(
        url,
        headers: {
          'Content-Type' => 'application/json',
          'api-key' => @api_key
        },
        body: parameters.to_json,
        timeout: 60
      )

      Rails.logger.info "Azure OpenAI response code: #{response.code}"
      Rails.logger.debug "Azure OpenAI response: #{response.body[0..500]}"

      unless response.success?
        error_msg = "Azure OpenAI API error: #{response.code} - #{response.body}"
        Rails.logger.error error_msg
        raise RubyLLM::Error.new(nil, error_msg)
      end

      result = response.parsed_response
      message_content = result.dig('choices', 0, 'message', 'content')
      
      # Handle tool calls if present
      tool_calls = result.dig('choices', 0, 'message', 'tool_calls')
      if tool_calls&.any?
        tool_calls.each do |tool_call|
          @on_tool_call&.call(tool_call)
          # Execute tool and get result
          tool_result = execute_tool(tool_call)
          @on_tool_result&.call(tool_result)
        end
      end

      message_obj = RubyLLM::Message.new(content: message_content)
      @on_end_message&.call(message_obj)
      message_obj
    rescue StandardError => e
      Rails.logger.error "Azure OpenAI request failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise RubyLLM::Error.new(nil, e.message)
    end

    private

    def build_messages(user_message)
      messages = []
      messages << { role: 'system', content: @instructions } if @instructions.present?
      messages << { role: 'user', content: user_message }
      messages
    end

    def execute_tool(tool_call)
      # Find the tool and execute it
      tool_name = tool_call.dig('function', 'name')
      tool = @tools.find { |t| t.name == tool_name }
      return nil unless tool

      args = JSON.parse(tool_call.dig('function', 'arguments') || '{}')
      # RubyLLM tools have a call method
      result = tool.call(**args.symbolize_keys)
      {
        tool_call_id: tool_call['id'],
        role: 'tool',
        name: tool_name,
        content: result.to_json
      }
    end
  end
end
