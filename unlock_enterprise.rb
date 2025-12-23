#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to unlock Enterprise Edition features
# Run this in Rails console: rails runner unlock_enterprise.rb
# Or: bundle exec rails runner unlock_enterprise.rb

puts "🔓 Unlocking Enterprise Edition Features..."
puts "=" * 50

# Step 1: Set pricing plan to enterprise
puts "\n1. Setting INSTALLATION_PRICING_PLAN to 'enterprise'..."
config = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN')
config.value = 'enterprise'
config.locked = false
if config.save
  puts "   ✅ Pricing plan set to 'enterprise'"
else
  puts "   ❌ Failed to save: #{config.errors.full_messages.join(', ')}"
end

# Step 2: Verify Enterprise detection
puts "\n2. Verifying Enterprise detection..."
if ChatwootApp.enterprise?
  puts "   ✅ Enterprise folder detected"
else
  puts "   ⚠️  Enterprise folder not found - ensure /enterprise directory exists"
end

# Step 3: Check pricing plan
puts "\n3. Checking pricing plan..."
plan = ChatwootHub.pricing_plan
puts "   Current plan: #{plan}"
if plan != 'community'
  puts "   ✅ Non-community plan detected - features should be enabled"
else
  puts "   ⚠️  Still on community plan - check configuration"
end

# Step 4: Enable features for all accounts
puts "\n4. Enabling Enterprise features for all accounts..."
premium_features = %w[
  disable_branding
  audit_logs
  sla
  captain_integration
  custom_roles
]

Account.find_each do |account|
  account.enable_features!(*premium_features)
  puts "   ✅ Enabled features for account: #{account.name} (ID: #{account.id})"
end

puts "\n5. Summary:"
puts "   Enterprise detected: #{ChatwootApp.enterprise? ? '✅ Yes' : '❌ No'}"
puts "   Pricing plan: #{ChatwootHub.pricing_plan}"
puts "   Accounts updated: #{Account.count}"

puts "\n" + "=" * 50
puts "🎉 Enterprise Edition unlock complete!"
puts "\nNote: You may need to restart the application for changes to take full effect."
puts "Some features may require additional configuration (e.g., Captain AI needs OpenAI API keys)."


