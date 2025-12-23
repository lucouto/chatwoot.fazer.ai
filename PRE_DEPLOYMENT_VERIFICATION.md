# Pre-Deployment Verification Checklist

## ✅ Verification Status

### 1. Enterprise Edition Configuration

**Docker Image**: ✅ Configured
- **Current**: `ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.5-ee`
- **Status**: Enterprise Edition (`-ee` suffix)
- **Location**: `docker-compose.coolify.yaml` lines 5 and 59

**Verification in Production** (after deployment):

```ruby
# In Rails console (rails console)
ChatwootApp.enterprise?           # Should return: true
ChatwootApp.extensions            # Should return: ["enterprise"]
ChatwootHub.pricing_plan          # Should return: "enterprise" (if DB config set)

# Check if enterprise folder exists
ChatwootApp.root.join('enterprise').exist?  # Should return: true

# Check Enterprise modules are loaded
Account.ancestors.map(&:name).grep(/Enterprise/)
# Should show: ["Enterprise::Account", ...]
```

**Expected Results:**
- ✅ `ChatwootApp.enterprise?` → `true`
- ✅ `ChatwootApp.extensions` → `["enterprise"]`
- ✅ Enterprise folder exists in image
- ✅ Enterprise modules can be loaded

---

### 2. Custom Attributes Bug Fixes

**Commit**: `77b6b8fac` ✅ Committed and pushed

**Files Modified:**

#### ✅ File 1: `app/javascript/dashboard/routes/dashboard/settings/automation/operators.js`
**Status**: ✅ Fixed
- **Line 115-140**: `OPERATOR_TYPES_7` defined with 6 operators:
  - `equal_to`
  - `not_equal_to`
  - `contains` ✅ (NEW - was missing)
  - `does_not_contain` ✅ (NEW - was missing)
  - `is_present`
  - `is_not_present`

#### ✅ File 2: `app/javascript/dashboard/helper/automationHelper.js`
**Status**: ✅ Fixed
- **Line 3-5**: Imports `OPERATOR_TYPES_7`
- **Line 66**: `text: OPERATOR_TYPES_7` (was `OPERATOR_TYPES_3`)
- **Line 308-317**: `getOperators` function fixed:
  - ✅ Checks for custom attributes in **both** create and edit modes
  - ✅ No longer requires `mode === 'edit'` check

#### ✅ File 3: `app/services/filter_service.rb`
**Status**: ✅ Fixed
- **Line 157-162**: `is_present`/`is_not_present` SQL fix:
  - ✅ Returns proper SQL: `IS NOT NULL` / `IS NULL`
  - ✅ No longer generates malformed SQL

**Verification in Production** (after deployment):

1. **Test in UI:**
   - Go to Automation Rules → Create new rule
   - Add condition → Select a **text** custom attribute
   - Check available operators dropdown
   - **Expected**: Should see 6 operators including "Contains" and "Does not contain"

2. **Test "Is present" operator:**
   - Create automation rule with custom attribute
   - Select "Is present" operator
   - Save and test
   - **Expected**: Should work correctly (no SQL errors)

3. **Test "Contains" operator:**
   - Create automation rule with text custom attribute
   - Select "Contains" operator
   - Enter value (e.g., "sud")
   - **Expected**: Should filter correctly

**Backend Verification** (Rails console):

```ruby
# Test the filter service
rule = AutomationRule.first
service = AutomationRules::ConditionsFilterService.new(rule, Conversation.first)

# Check if custom attributes are detected
account = Account.first
custom_attr = account.custom_attribute_definitions.find_by(attribute_display_type: 'text')
# Should return a custom attribute definition

# Verify operators are available
# (This is frontend, but backend should accept the operators)
```

---

## 📋 Complete Verification Checklist

### Before Deployment

- [x] ✅ Docker image uses `-ee` suffix (`v4.8.0-fazer-ai.5-ee`)
- [x] ✅ Bug fix commit is in repository (`77b6b8fac`)
- [x] ✅ All 3 files modified correctly
- [x] ✅ GitHub Actions workflow set up
- [x] ✅ Changes pushed to fork

### After Deployment (Production Verification)

#### Enterprise Edition Check:
- [ ] `ChatwootApp.enterprise?` returns `true`
- [ ] `ChatwootApp.extensions` returns `["enterprise"]`
- [ ] Enterprise folder exists: `ChatwootApp.root.join('enterprise').exist?` → `true`
- [ ] Enterprise modules loaded (check `Account.ancestors`)

#### Custom Attributes Bug Fix Check:
- [ ] Text custom attributes show 6 operators (not just 4)
- [ ] "Contains" operator is available for text attributes
- [ ] "Does not contain" operator is available for text attributes
- [ ] "Is present" operator works without SQL errors
- [ ] "Is not present" operator works without SQL errors
- [ ] Can create automation rule: Custom Attribute "Événements" contains "sud"

---

## 🔍 Quick Verification Script

Run this in Rails console after deployment:

```ruby
puts "=" * 60
puts "ENTERPRISE EDITION VERIFICATION"
puts "=" * 60
puts "Enterprise?: #{ChatwootApp.enterprise?}"
puts "Extensions: #{ChatwootApp.extensions.inspect}"
puts "Pricing Plan: #{ChatwootHub.pricing_plan}"
puts "Enterprise folder exists: #{ChatwootApp.root.join('enterprise').exist?}"
puts "=" * 60

puts "\n" + "=" * 60
puts "CUSTOM ATTRIBUTES BUG FIX VERIFICATION"
puts "=" * 60

# Check if files have the fixes
require 'fileutils'
automation_helper = File.read('app/javascript/dashboard/helper/automationHelper.js')
operators_file = File.read('app/javascript/dashboard/routes/dashboard/settings/automation/operators.js')
filter_service = File.read('app/services/filter_service.rb')

checks = {
  "OPERATOR_TYPES_7 defined" => operators_file.include?('OPERATOR_TYPES_7'),
  "OPERATOR_TYPES_7 imported" => automation_helper.include?('OPERATOR_TYPES_7'),
  "text uses OPERATOR_TYPES_7" => automation_helper.include?('text: OPERATOR_TYPES_7'),
  "getOperators checks custom attributes" => automation_helper.include?('isACustomAttribute(allCustomAttributes, key)'),
  "is_present SQL fix" => filter_service.include?("IS NOT NULL #{query_operator}"),
  "is_not_present SQL fix" => filter_service.include?("IS NULL #{query_operator}")
}

checks.each do |check, result|
  status = result ? "✅" : "❌"
  puts "#{status} #{check}"
end

puts "=" * 60
```

---

## 🎯 Expected Results Summary

### Enterprise Edition
- ✅ Image tag: `v4.8.0-fazer-ai.5-ee` (Enterprise Edition)
- ✅ Enterprise folder will exist in Docker image
- ✅ `ChatwootApp.enterprise?` → `true`
- ✅ All Enterprise features available

### Custom Attributes Bug Fixes
- ✅ Text attributes: 6 operators (equal_to, not_equal_to, contains, does_not_contain, is_present, is_not_present)
- ✅ "Contains" operator available for text custom attributes
- ✅ "Is present" generates correct SQL: `IS NOT NULL`
- ✅ "Is not present" generates correct SQL: `IS NULL`
- ✅ Works in both create and edit modes

---

## 🚨 If Verification Fails

### Enterprise Edition Not Working:
1. Check Docker image tag has `-ee` suffix
2. Verify `DISABLE_ENTERPRISE` env var is not set
3. Check if `enterprise/` folder exists in container: `docker exec <container> ls -la /app/enterprise`

### Custom Attributes Still Broken:
1. Verify commit `77b6b8fac` is in the image
2. Check browser console for JavaScript errors
3. Verify files are not overridden by volume mounts
4. Check Rails logs for SQL errors

---

## ✅ Ready for Production

Based on code verification:

1. ✅ **Enterprise Edition**: Configured correctly (`v4.8.0-fazer-ai.5-ee`)
2. ✅ **Bug Fixes**: All 3 files modified correctly
3. ✅ **Commit**: Pushed to fork
4. ✅ **Workflow**: Set up for automated builds

**Status**: ✅ **READY TO DEPLOY**

After deployment, run the verification script above to confirm everything works in production.



