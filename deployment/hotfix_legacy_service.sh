#!/bin/bash
# Hotfix script to create the corrected file on the server for volume mounting

FIX_FILE="/tmp/legacy_base_open_ai_service_fixed.rb"

cat > "${FIX_FILE}" << 'EOF'
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
    raise "Failed to initialize OpenAI client: #{e.message}"
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
EOF

echo "✅ Fixed file created at: ${FIX_FILE}"
echo ""
echo "Next: Update docker-compose.coolify.yaml to mount this file:"
echo "  volumes:"
echo "    - 'storage:/app/storage'"
echo "    - '${FIX_FILE}:/app/enterprise/app/services/llm/legacy_base_open_ai_service.rb:ro'"

