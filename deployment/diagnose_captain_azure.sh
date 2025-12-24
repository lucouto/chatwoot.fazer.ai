#!/bin/bash
# Diagnose Captain Azure OpenAI configuration in staging

echo "=== Captain Azure OpenAI Diagnosis ==="
echo ""

# Find staging Rails container
STAGING_RAILS=$(docker ps --format '{{.Names}}' | grep -i rails | head -1)

if [ -z "$STAGING_RAILS" ]; then
  echo "❌ No Rails container found. Is staging running?"
  exit 1
fi

echo "📦 Staging Rails Container: $STAGING_RAILS"
echo ""

# Check if Azure patch exists
echo "=== 1. Checking Azure Patch ==="
PATCH_PATH="/app/enterprise/app/services/llm/base_open_ai_service.rb"
if docker exec $STAGING_RAILS test -f "$PATCH_PATH"; then
  echo "✅ Azure patch exists: $PATCH_PATH"
  echo ""
  echo "Patch content (first 20 lines):"
  docker exec $STAGING_RAILS head -20 "$PATCH_PATH"
else
  echo "❌ Azure patch NOT found: $PATCH_PATH"
  echo ""
  echo "This is likely why Captain isn't working with Azure."
  echo "The patch is needed because RubyLLM doesn't support Azure OpenAI format."
fi
echo ""

# Check Captain configuration
echo "=== 2. Checking Captain Configuration ==="
echo "OpenAI API Key:"
docker exec $STAGING_RAILS bundle exec rails runner "
  key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
  puts key ? '✅ Set (' + key[0..10] + '...)' : '❌ Not set'
" 2>/dev/null

echo ""
echo "OpenAI Model:"
docker exec $STAGING_RAILS bundle exec rails runner "
  model = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value
  puts model ? '✅ ' + model : '❌ Not set'
" 2>/dev/null

echo ""
echo "OpenAI Endpoint:"
docker exec $STAGING_RAILS bundle exec rails runner "
  endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
  puts endpoint ? '✅ ' + endpoint : '❌ Not set'
  if endpoint&.include?('openai.azure.com')
    if endpoint.include?('/deployments/')
      puts '   ⚠️  Endpoint includes /deployments/ - should be base URL only'
      match = endpoint.match(%r{/deployments/([^/?#]+)})
      if match
        puts '   💡 Deployment name in endpoint: ' + match[1]
      fi
    else
      puts '   ✅ Endpoint is base URL (correct)'
    end
  fi
" 2>/dev/null

echo ""
echo "=== 3. Checking Recent Errors ==="
echo "Last 10 lines with 'azure' or 'openai' or 'captain':"
docker logs $STAGING_RAILS --tail 100 2>&1 | grep -i "azure\|openai\|captain" | tail -10 || echo "No recent logs found"

echo ""
echo "=== 4. Recommendations ==="
if ! docker exec $STAGING_RAILS test -f "$PATCH_PATH"; then
  echo "❌ Azure patch is missing. You need to:"
  echo "   1. Copy it from production, OR"
  echo "   2. Recreate it using the script in the repo"
  echo ""
fi

echo "✅ Configuration should be:"
echo "   - Endpoint: https://openai-cnjeunes.openai.azure.com/ (base URL only)"
echo "   - Model: gpt-4o-r (deployment name from Azure)"
echo ""
echo "See: deployment/CAPTAIN_AZURE_FIX_SUMMARY.md for details"

