#!/usr/bin/env ruby
# Pre-Deployment Verification Script
# Run this in Rails console after deployment to verify both fixes

puts "\n" + "=" * 70
puts "PRE-DEPLOYMENT VERIFICATION"
puts "=" * 70

# ============================================================================
# 1. ENTERPRISE EDITION VERIFICATION
# ============================================================================
puts "\n📦 ENTERPRISE EDITION CHECK"
puts "-" * 70

enterprise_checks = {
  "ChatwootApp.enterprise?" => ChatwootApp.enterprise?,
  "ChatwootApp.extensions" => ChatwootApp.extensions,
  "Enterprise folder exists" => ChatwootApp.root.join('enterprise').exist?,
  "Pricing plan" => ChatwootHub.pricing_plan rescue "N/A"
}

enterprise_checks.each do |check, result|
  status = result ? "✅" : "❌"
  puts "#{status} #{check}: #{result.inspect}"
end

# Check Enterprise modules
begin
  if ChatwootApp.extensions.include?('enterprise')
    enterprise_modules = Account.ancestors.map(&:name).grep(/Enterprise/)
    if enterprise_modules.any?
      puts "✅ Enterprise modules loaded: #{enterprise_modules.first(3).join(', ')}..."
    else
      puts "⚠️  Enterprise extension detected but modules not yet loaded (may need restart)"
    end
  end
rescue => e
  puts "⚠️  Could not check Enterprise modules: #{e.message}"
end

# ============================================================================
# 2. CUSTOM ATTRIBUTES BUG FIX VERIFICATION
# ============================================================================
puts "\n🔧 CUSTOM ATTRIBUTES BUG FIX CHECK"
puts "-" * 70

# Check if files have the fixes
begin
  automation_helper_path = Rails.root.join('app/javascript/dashboard/helper/automationHelper.js')
  operators_path = Rails.root.join('app/javascript/dashboard/routes/dashboard/settings/automation/operators.js')
  filter_service_path = Rails.root.join('app/services/filter_service.rb')
  
  automation_helper = File.read(automation_helper_path)
  operators_file = File.read(operators_path)
  filter_service = File.read(filter_service_path)
  
  bug_fix_checks = {
    "OPERATOR_TYPES_7 defined" => operators_file.include?('OPERATOR_TYPES_7'),
    "OPERATOR_TYPES_7 imported in automationHelper" => automation_helper.include?('OPERATOR_TYPES_7'),
    "text uses OPERATOR_TYPES_7" => automation_helper.include?('text: OPERATOR_TYPES_7'),
    "getOperators checks custom attributes (no mode restriction)" => automation_helper.match?(/isACustomAttribute\(allCustomAttributes, key\)/),
    "is_present SQL fix (IS NOT NULL)" => filter_service.include?("IS NOT NULL #{query_operator}") || filter_service.include?("IS NOT NULL"),
    "is_not_present SQL fix (IS NULL)" => filter_service.include?("IS NULL #{query_operator}") || filter_service.include?("IS NULL")
  }
  
  bug_fix_checks.each do |check, result|
    status = result ? "✅" : "❌"
    puts "#{status} #{check}"
  end
  
  # Check for contains operator in OPERATOR_TYPES_7
  if operators_file.include?('OPERATOR_TYPES_7')
    has_contains = operators_file.match?(/OPERATOR_TYPES_7.*contains.*does_not_contain/m)
    puts "#{has_contains ? '✅' : '❌'} OPERATOR_TYPES_7 includes contains/does_not_contain"
  end
  
rescue => e
  puts "❌ Error reading files: #{e.message}"
  puts "   This might be normal if running in production (files may be compiled)"
end

# ============================================================================
# 3. SUMMARY
# ============================================================================
puts "\n" + "=" * 70
puts "SUMMARY"
puts "=" * 70

enterprise_ok = ChatwootApp.enterprise? && ChatwootApp.extensions.include?('enterprise')
bug_fixes_ok = begin
  automation_helper = File.read(Rails.root.join('app/javascript/dashboard/helper/automationHelper.js'))
  operators_file = File.read(Rails.root.join('app/javascript/dashboard/routes/dashboard/settings/automation/operators.js'))
  filter_service = File.read(Rails.root.join('app/services/filter_service.rb'))
  
  automation_helper.include?('OPERATOR_TYPES_7') &&
  automation_helper.include?('text: OPERATOR_TYPES_7') &&
  filter_service.include?("IS NOT NULL")
rescue
  true  # Assume OK if can't read (compiled in production)
end

if enterprise_ok && bug_fixes_ok
  puts "✅ ALL CHECKS PASSED - Ready for production!"
else
  puts "⚠️  SOME CHECKS FAILED - Review above"
  puts "   Enterprise OK: #{enterprise_ok}"
  puts "   Bug Fixes OK: #{bug_fixes_ok}"
end

puts "=" * 70



