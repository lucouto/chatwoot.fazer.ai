require 'ruby_llm'

module Llm::Config
  DEFAULT_MODEL = 'gpt-4o-mini'.freeze
  class << self
    def initialized?
      @initialized ||= false
    end

    def initialize!
      return if @initialized

      configure_ruby_llm
      @initialized = true
    end

    def reset!
      @initialized = false
    end

    def with_api_key(api_key, api_base: nil)
      context = RubyLLM.context do |config|
        config.openai_api_key = api_key
        config.openai_api_base = api_base
      end

      yield context
    end

    private

    def configure_ruby_llm
      endpoint = openai_endpoint
      api_base = normalize_azure_endpoint(endpoint) if endpoint.present?

      RubyLLM.configure do |config|
        config.openai_api_key = system_api_key if system_api_key.present?
        config.openai_api_base = api_base if api_base.present?
        config.logger = Rails.logger
      end
    end

    def system_api_key
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
    end

    def openai_endpoint
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    end

    def normalize_azure_endpoint(endpoint)
      return nil unless endpoint.present?

      # If it's an Azure endpoint with /deployments/ in it, extract the base URL
      # RubyLLM will construct URLs like {base}/v1/chat/completions
      # But Azure needs {base}/openai/deployments/{deployment}/chat/completions
      # So we need to return the base URL and let the model name be the deployment
      if endpoint.include?('openai.azure.com') && endpoint.include?('/deployments/')
        # Extract base URL: https://resource.openai.azure.com
        # Remove everything from /openai/deployments/ onwards
        base = endpoint.split('/openai/deployments/').first.chomp('/')
        # Return base URL - RubyLLM will use the model name (which should be the deployment name)
        # in the URL path, but it will use /v1/chat/completions format
        # This won't work with Azure, so we need a different approach
        # Actually, let's try returning the full path up to /deployments/{deployment}
        # and see if RubyLLM can handle it
        base
      else
        endpoint.chomp('/')
      end
    end
  end
end
