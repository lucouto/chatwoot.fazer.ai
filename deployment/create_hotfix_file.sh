#!/bin/bash
# Script to create the fixed file on the server for volume mounting

ssh coolify-vm "cat > /tmp/legacy_base_open_ai_service_fixed.rb << 'ENDOFFILE'
# frozen_string_literal: true

# DEPRECATED: This class uses the legacy OpenAI Ruby gem directly.
# Only used for PDF/file operations that require OpenAI's files API:
# - Captain::Llm::PdfProcessingService (files.upload for assistants)
# - Captain::Llm::PaginatedFaqGeneratorService (uses file_id from uploaded files)
#
# For all other LLM operations, use Llm::BaseAiService with RubyLLM instead.
class Llm::LegacyBaseOpenAiService
  DEFAULT_MODEL = 'gpt-4o-mini'

  attr_reader :client, :model

  def initialize
    @client = OpenAI::Client.new(
      access_token: InstallationConfig.find_by!(name: 'CAPTAIN_OPEN_AI_API_KEY').value,
      uri_base: uri_base,
      log_errors: Rails.env.development?
    )
    setup_model
  rescue StandardError => e
    raise \"Failed to initialize OpenAI client: #{e.message}\"
  end

  private

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
"

echo "✅ Fixed file created at /tmp/legacy_base_open_ai_service_fixed.rb"
echo ""
echo "Next steps:"
echo "1. The docker-compose already has the volume mount configured"
echo "2. Restart the services in Coolify"
echo "3. The volume mount will override the broken file in the container"

