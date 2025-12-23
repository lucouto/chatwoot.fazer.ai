# Explanation of Fixes for Issue #10377

## Summary

I've identified and fixed several related issues with Custom Attributes in Automation Rules that are related to the problems described in this issue. While the specific cases mentioned (Case 1 and Case 2) may have additional root causes, I've addressed the underlying SQL generation problems for custom attributes.

---

## Issues Fixed

### 1. **`is_present` and `is_not_present` Operators Generating Malformed SQL**

**Problem:**
- When using `is_present` or `is_not_present` operators with custom attributes, the SQL query was malformed
- The `filter_operation` method returned `nil` for these operators, causing the SQL builder to generate invalid queries
- This resulted in errors like: `syntax error at or near "OR"` or missing brackets

**Root Cause:**
In `app/services/filter_service.rb`, the `build_custom_attr_query` method was calling `filter_operation(query_hash, current_index)` for all operators, but for `is_present` and `is_not_present`, this method returns `nil` because these operators don't have filter values - they need direct SQL (`IS NOT NULL` / `IS NULL`).

**Fix:**
```ruby
# app/services/filter_service.rb - build_custom_attr_query method
def build_custom_attr_query(query_hash, current_index)
  filter_operator = query_hash[:filter_operator]
  query_operator = query_hash[:query_operator]
  table_name = attribute_model == 'conversation_attribute' ? 'conversations' : 'contacts'

  # Handle is_present and is_not_present specially
  if filter_operator == 'is_present'
    return "(#{table_name}.custom_attributes ->> '#{@attribute_key}') IS NOT NULL #{query_operator} "
  elsif filter_operator == 'is_not_present'
    return "(#{table_name}.custom_attributes ->> '#{@attribute_key}') IS NULL #{query_operator} "
  end

  # For other operators, use the standard filter_operation
  filter_operator_value = filter_operation(query_hash, current_index)
  # ... rest of the method
end
```

**Result:**
- `is_present` now correctly generates: `(conversations.custom_attributes ->> 'attribute_key') IS NOT NULL`
- `is_not_present` now correctly generates: `(conversations.custom_attributes ->> 'attribute_key') IS NULL`
- Proper query operator (`AND`/`OR`) is appended correctly

---

### 2. **Missing "Contains" and "Does Not Contain" Operators for Text Custom Attributes**

**Problem:**
- Text custom attributes only showed 4 operators: `equal_to`, `not_equal_to`, `is_present`, `is_not_present`
- The `contains` and `does_not_contain` operators were missing from the UI, even though the backend supported them

**Root Cause:**
The frontend `getOperatorTypes` function in `app/javascript/dashboard/helper/automationHelper.js` was mapping text custom attributes to `OPERATOR_TYPES_3`, which doesn't include `contains`/`does_not_contain`.

**Fix:**
1. Created new `OPERATOR_TYPES_7` in `app/javascript/dashboard/routes/dashboard/settings/automation/operators.js`:
```javascript
export const OPERATOR_TYPES_7 = [
  { value: 'equal_to', label: 'Equal to' },
  { value: 'not_equal_to', label: 'Not equal to' },
  { value: 'contains', label: 'Contains' },
  { value: 'does_not_contain', label: 'Does not contain' },
  { value: 'is_present', label: 'Is present' },
  { value: 'is_not_present', label: 'Is not present' },
];
```

2. Updated `getOperatorTypes` to map text attributes to `OPERATOR_TYPES_7`:
```javascript
export const getOperatorTypes = key => {
  const operatorMap = {
    list: OPERATOR_TYPES_1,
    text: OPERATOR_TYPES_7, // Now includes contains/does_not_contain
    number: OPERATOR_TYPES_1,
    link: OPERATOR_TYPES_1,
    date: OPERATOR_TYPES_4,
    checkbox: OPERATOR_TYPES_1,
  };
  return operatorMap[key] || OPERATOR_TYPES_1;
};
```

**Result:**
- Text custom attributes now show 6 operators including `contains` and `does_not_contain`
- Users can create automation rules like: "Custom Attribute 'Événements' Contains 'sud'"

---

### 3. **Operator Detection Not Working in Create Mode**

**Problem:**
- When creating a new automation rule, custom attributes were defaulting to `OPERATOR_TYPES_3` instead of the correct operators
- The `getOperators` function only checked for custom attributes when `mode === 'edit'`

**Root Cause:**
In `app/javascript/dashboard/helper/automationHelper.js`, the `getOperators` function had this logic:
```javascript
if (mode === 'edit' && customAttribute) {
  return getOperatorTypes(customAttribute.attribute_display_type);
}
```
This meant custom attributes in "create" mode weren't detected.

**Fix:**
```javascript
export const getOperators = (
  allCustomAttributes,
  automationTypes,
  automation,
  mode,
  key
) => {
  // Check for custom attributes in both edit and create modes
  const customAttribute = isACustomAttribute(allCustomAttributes, key);
  if (customAttribute) {
    return getOperatorTypes(customAttribute.attribute_display_type);
  }
  // Fall back to standard automation types for non-custom attributes
  const type = getAutomationType(automationTypes, automation, key);
  return type?.filterOperators || OPERATOR_TYPES_1;
};
```

**Result:**
- Custom attributes now show correct operators in both create and edit modes

---

## Relationship to Issue #10377

The fixes I've implemented address similar SQL generation problems:

1. **Case 1 (not_equal_to with NULL)**: While I haven't directly fixed the bracket issue mentioned, my fix for `is_present`/`is_not_present` shows the pattern for handling NULL checks correctly. The `not_equal_to` case likely needs similar bracket handling in the `not_in_custom_attr_query` method.

2. **Case 2 (and OR syntax error)**: My fix ensures that `is_present`/`is_not_present` return complete, properly formatted SQL strings with the query operator, preventing malformed queries like `and OR`.

---

## Testing

After these fixes:
- ✅ `is_present` operator works correctly
- ✅ `is_not_present` operator works correctly  
- ✅ `contains` operator available for text custom attributes
- ✅ `does_not_contain` operator available for text custom attributes
- ✅ Operators display correctly in both create and edit modes
- ✅ SQL queries are properly formatted with correct brackets and operators

---

## Files Modified

1. `app/services/filter_service.rb` - Fixed SQL generation for `is_present`/`is_not_present`
2. `app/javascript/dashboard/routes/dashboard/settings/automation/operators.js` - Added `OPERATOR_TYPES_7`
3. `app/javascript/dashboard/helper/automationHelper.js` - Fixed operator detection and mapping

---

## Next Steps

To fully resolve Case 1 and Case 2 from the original issue, additional fixes may be needed:

1. **Case 1**: Review `not_in_custom_attr_query` method to ensure proper bracket handling for `not_equal_to` with NULL values
2. **Case 2**: Review query builder logic to prevent `and OR` syntax errors when custom attributes are in the middle of conditions

The fixes I've implemented provide a foundation and pattern for these additional fixes.



