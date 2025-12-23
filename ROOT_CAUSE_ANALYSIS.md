# Root Cause Analysis: Enterprise Module Injection

## The Problem Chain

1. **`ChatwootApp.enterprise?` returns `false`**
   - Because `/app/enterprise` folder doesn't exist in Docker image
   - Or `DISABLE_ENTERPRISE` env var is set

2. **`ChatwootApp.extensions` returns `[]` (empty array)**
   - Line 32-40 in `lib/chatwoot_app.rb`:
   ```ruby
   def self.extensions
     if custom?
       %w[enterprise custom]
     elsif enterprise?
       %w[enterprise]  # ← Only returns this if enterprise? is true
     else
       %w[]  # ← Returns empty array if enterprise? is false
     end
   end
   ```

3. **Enterprise modules never get loaded**
   - Line 71 in `config/initializers/01_inject_enterprise_edition_module.rb`:
   ```ruby
   def each_extension_for(constant_name, namespace)
     ChatwootApp.extensions.each do |extension_name|  # ← Empty array = no iteration
       # ... load Enterprise modules ...
     end
   end
   ```

4. **All `prepend_mod_with` and `include_mod_with` calls fail silently**
   - Throughout the codebase (Account, User, Conversation, etc.)
   - They call `prepend_mod_with('Account')` which looks for `Enterprise::Account`
   - But if `extensions` is empty, it never finds/loads these modules

## Impact

Even if you:
- ✅ Set database config to 'enterprise'
- ✅ Enable features for accounts
- ✅ Set pricing plan

The Enterprise **code modules** never get loaded because:
- `ChatwootApp.extensions` returns `[]`
- The injection mechanism has nothing to iterate over
- Enterprise modules like `Enterprise::Account`, `Enterprise::User`, etc. are never prepended/included

## The Fix

We need to fix **both**:
1. `ChatwootApp.enterprise?` - to return true when database config is set
2. `ChatwootApp.extensions` - to return `%w[enterprise]` even if folder doesn't exist

This ensures:
- Enterprise modules get loaded
- Features work properly
- All Enterprise functionality is available


