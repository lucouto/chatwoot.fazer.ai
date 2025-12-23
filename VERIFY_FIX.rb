#!/usr/bin/env ruby
# Quick verification script - run in Rails console
# Just copy and paste this entire block

# Fix ChatwootApp.enterprise?
module ChatwootApp
  def self.enterprise?
    return false if ENV.fetch('DISABLE_ENTERPRISE', false) == 'true' || ENV.fetch('DISABLE_ENTERPRISE', false) == '1'
    
    folder_exists = root.join('enterprise').exist?
    
    if !folder_exists
      config = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN') rescue nil
      return config&.value == 'enterprise' if config
    end
    
    folder_exists
  end
  
  @enterprise = nil
end

# Fix ChatwootHub.pricing_plan
module ChatwootHub
  def self.pricing_plan
    config = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN') rescue nil
    return config.value if config&.value.present? && config.value != 'community'
    
    return 'community' unless ChatwootApp.enterprise?
    InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value || 'enterprise'
  end
end

# Verify
puts "=" * 50
puts "VERIFICATION RESULTS:"
puts "=" * 50
puts "Enterprise?: #{ChatwootApp.enterprise?}"
puts "Extensions: #{ChatwootApp.extensions.inspect}"
puts "Pricing Plan: #{ChatwootHub.pricing_plan}"
puts "=" * 50

# Check if Enterprise modules can be loaded
begin
  if ChatwootApp.extensions.include?('enterprise')
    puts "✅ Enterprise extension detected - modules should load"
    
    # Try to access an Enterprise module
    if defined?(Enterprise::Account)
      puts "✅ Enterprise::Account module is loaded"
    else
      puts "⚠️  Enterprise::Account not yet loaded (may need app restart)"
    end
  else
    puts "❌ Enterprise extension NOT in extensions array"
  end
rescue => e
  puts "⚠️  Error checking modules: #{e.message}"
end

puts "=" * 50


