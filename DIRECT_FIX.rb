# Direct Fix - Run this entire block in Rails console
# This forces the redefinition and clears all caches

# First, verify database config is set
puts "Step 1: Checking database config..."
config = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')
if config
  puts "  Config found: value = '#{config.value}', locked = #{config.locked}"
else
  puts "  ❌ Config not found! Setting it now..."
  config = InstallationConfig.create!(name: 'INSTALLATION_PRICING_PLAN', value: 'enterprise', locked: false)
  puts "  ✅ Config created"
end

# Force clear the module cache
puts "\nStep 2: Clearing module cache..."
ChatwootApp.instance_variable_set(:@enterprise, nil)
ChatwootApp.instance_variable_set(:@custom, nil)

# Redefine the methods with proper syntax
puts "\nStep 3: Redefining ChatwootApp.enterprise?..."
module ChatwootApp
  # Remove the old method
  remove_method :enterprise? if respond_to?(:enterprise?, true)
  
  # Define new method
  def self.enterprise?
    return false if ENV.fetch('DISABLE_ENTERPRISE', false) == 'true' || ENV.fetch('DISABLE_ENTERPRISE', false) == '1'
    
    folder_exists = root.join('enterprise').exist?
    
    # Fallback: check database config
    if !folder_exists
      db_config = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN') rescue nil
      if db_config && db_config.value == 'enterprise'
        return true
      end
    end
    
    folder_exists
  end
  
  # Also redefine extensions to ensure it uses the new enterprise? method
  remove_method :extensions if respond_to?(:extensions, true)
  
  def self.extensions
    is_enterprise = enterprise?
    
    if custom?
      %w[enterprise custom]
    elsif is_enterprise
      %w[enterprise]
    else
      %w[]
    end
  end
end

# Fix ChatwootHub
puts "\nStep 4: Redefining ChatwootHub.pricing_plan..."
module ChatwootHub
  remove_method :pricing_plan if respond_to?(:pricing_plan, true)
  
  def self.pricing_plan
    db_config = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN') rescue nil
    if db_config && db_config.value.present? && db_config.value != 'community'
      return db_config.value
    end
    
    return 'community' unless ChatwootApp.enterprise?
    InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value || 'enterprise'
  end
end

# Force clear cache again
ChatwootApp.instance_variable_set(:@enterprise, nil)

# Verify
puts "\n" + "=" * 50
puts "VERIFICATION:"
puts "=" * 50
puts "Database config value: #{config.value}"
puts "ChatwootApp.enterprise?: #{ChatwootApp.enterprise?}"
puts "ChatwootApp.extensions: #{ChatwootApp.extensions.inspect}"
puts "ChatwootHub.pricing_plan: #{ChatwootHub.pricing_plan}"
puts "=" * 50

if ChatwootApp.enterprise? && ChatwootApp.extensions.include?('enterprise')
  puts "\n✅ SUCCESS! Enterprise is now detected!"
else
  puts "\n❌ Still not working. Let's debug..."
  puts "Folder exists: #{ChatwootApp.root.join('enterprise').exist?}"
  puts "DISABLE_ENTERPRISE env: #{ENV['DISABLE_ENTERPRISE']}"
end


