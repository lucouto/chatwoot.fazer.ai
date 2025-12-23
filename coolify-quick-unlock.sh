#!/bin/bash
# Quick Enterprise Unlock Script for Coolify
# Run this inside the Rails container

set -e

echo "🔓 Enterprise Edition Quick Unlock for Coolify"
echo "================================================"
echo ""

# Check if we're in Rails environment
if ! command -v bundle &> /dev/null; then
    echo "❌ Error: This script must be run inside the Rails container"
    echo "Usage: docker exec -it <rails-container> bash -c 'bash <(cat coolify-quick-unlock.sh)'"
    exit 1
fi

echo "Step 1: Setting INSTALLATION_PRICING_PLAN to 'enterprise'..."
bundle exec rails runner "
config = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN')
config.value = 'enterprise'
config.locked = false
if config.save
  puts '   ✅ Pricing plan set to enterprise'
else
  puts '   ❌ Failed: ' + config.errors.full_messages.join(', ')
  exit 1
end
"

echo ""
echo "Step 2: Verifying Enterprise detection..."
bundle exec rails runner "
if ChatwootApp.enterprise?
  puts '   ✅ Enterprise folder detected'
else
  puts '   ⚠️  Enterprise folder not found'
end
puts '   Pricing plan: ' + ChatwootHub.pricing_plan
"

echo ""
echo "Step 3: Enabling Enterprise features for all accounts..."
bundle exec rails runner "
premium_features = %w[disable_branding audit_logs sla captain_integration custom_roles]
count = 0
Account.find_each do |account|
  account.enable_features!(*premium_features)
  count += 1
  puts \"   ✅ Enabled features for: #{account.name} (ID: #{account.id})\"
end
puts \"\\n   Total accounts updated: #{count}\"
"

echo ""
echo "Step 4: Final verification..."
bundle exec rails runner "
puts '   Enterprise detected: ' + (ChatwootApp.enterprise? ? '✅ Yes' : '❌ No')
puts '   Pricing plan: ' + ChatwootHub.pricing_plan
account = Account.first
if account
  puts '   Sample account features:'
  puts '     - audit_logs: ' + (account.feature_enabled?(:audit_logs) ? '✅' : '❌')
  puts '     - sla: ' + (account.feature_enabled?(:sla) ? '✅' : '❌')
  puts '     - captain_integration: ' + (account.feature_enabled?(:captain_integration) ? '✅' : '❌')
end
"

echo ""
echo "================================================"
echo "🎉 Enterprise Edition unlock complete!"
echo ""
echo "⚠️  Note: Features may be disabled again when ReconcilePlanConfigService runs."
echo "    For permanent unlock, build a custom Docker image with code modifications."
echo "    See COOLIFY_DEPLOYMENT_GUIDE.md for details."
echo ""


