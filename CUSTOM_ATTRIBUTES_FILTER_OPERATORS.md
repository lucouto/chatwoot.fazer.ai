# Custom Attributes Filter Operators in Automation Rules

## Overview

Custom Attributes in Chatwoot Automation Rules support different filter operators based on their **attribute display type**. The available operators are determined by the data type of the custom attribute.

## Available Filter Operators by Custom Attribute Type

### 1. **Text** (`text`)
**Available Operators:**
- ✅ `equal_to` - Equal to
- ✅ `not_equal_to` - Not equal to
- ✅ `is_present` - Is present
- ✅ `is_not_present` - Is not present

**Code Reference:**
```23:28:app/javascript/shared/composables/useFilter.js
const getOperatorTypes = key => {
  switch (key) {
    case 'list':
      return OPERATORS.OPERATOR_TYPES_1;
    case 'text':
      return OPERATORS.OPERATOR_TYPES_3;
```

**Note:** Text attributes use `OPERATOR_TYPES_3` which includes presence checks, unlike `OPERATOR_TYPES_1`.

---

### 2. **Number** (`number`)
**Available Operators:**
- ✅ `equal_to` - Equal to
- ✅ `not_equal_to` - Not equal to

**Code Reference:**
```29:30:app/javascript/shared/composables/useFilter.js
    case 'number':
      return OPERATORS.OPERATOR_TYPES_1;
```

---

### 3. **List** (`list`)
**Available Operators:**
- ✅ `equal_to` - Equal to
- ✅ `not_equal_to` - Not equal to

**Code Reference:**
```25:26:app/javascript/shared/composables/useFilter.js
    case 'list':
      return OPERATORS.OPERATOR_TYPES_1;
```

---

### 4. **Checkbox** (`checkbox`)
**Available Operators:**
- ✅ `equal_to` - Equal to
- ✅ `not_equal_to` - Not equal to

**Code Reference:**
```35:36:app/javascript/shared/composables/useFilter.js
    case 'checkbox':
      return OPERATORS.OPERATOR_TYPES_1;
```

---

### 5. **Date** (`date`)
**Available Operators:**
- ✅ `equal_to` - Equal to
- ✅ `not_equal_to` - Not equal to
- ✅ `is_present` - Is present
- ✅ `is_not_present` - Is not present
- ✅ `is_greater_than` - Is greater than
- ✅ `is_less_than` - Is less than

**Code Reference:**
```33:34:app/javascript/shared/composables/useFilter.js
    case 'date':
      return OPERATORS.OPERATOR_TYPES_4;
```

---

### 6. **Link** (`link`)
**Available Operators:**
- ✅ `equal_to` - Equal to
- ✅ `not_equal_to` - Not equal to

**Code Reference:**
```31:32:app/javascript/shared/composables/useFilter.js
    case 'link':
      return OPERATORS.OPERATOR_TYPES_1;
```

---

### 7. **Currency** (`currency`)
**Available Operators:**
- ✅ `equal_to` - Equal to
- ✅ `not_equal_to` - Not equal to

**Note:** Currency uses the same operators as `number` (defaults to `OPERATOR_TYPES_1`).

---

### 8. **Percent** (`percent`)
**Available Operators:**
- ✅ `equal_to` - Equal to
- ✅ `not_equal_to` - Not equal to

**Note:** Percent uses the same operators as `number` (defaults to `OPERATOR_TYPES_1`).

---

## Complete Operator Definitions

### OPERATOR_TYPES_1
```1:10:app/javascript/dashboard/components/widgets/FilterInput/FilterOperatorTypes.js
export const OPERATOR_TYPES_1 = [
  {
    value: 'equal_to',
    label: 'Equal to',
  },
  {
    value: 'not_equal_to',
    label: 'Not equal to',
  },
];
```

### OPERATOR_TYPES_3
```31:48:app/javascript/dashboard/components/widgets/FilterInput/FilterOperatorTypes.js
export const OPERATOR_TYPES_3 = [
  {
    value: 'equal_to',
    label: 'Equal to',
  },
  {
    value: 'not_equal_to',
    label: 'Not equal to',
  },
  {
    value: 'contains',
    label: 'Contains',
  },
  {
    value: 'does_not_contain',
    label: 'Does not contain',
  },
];
```

**Note:** While `OPERATOR_TYPES_3` includes `contains` and `does_not_contain`, these are **NOT available for text custom attributes** in automation rules. Text attributes only get `equal_to`, `not_equal_to`, `is_present`, and `is_not_present`.

### OPERATOR_TYPES_4
```50:75:app/javascript/dashboard/components/widgets/FilterInput/FilterOperatorTypes.js
export const OPERATOR_TYPES_4 = [
  {
    value: 'equal_to',
    label: 'Equal to',
  },
  {
    value: 'not_equal_to',
    label: 'Not equal to',
  },
  {
    value: 'is_present',
    label: 'Is present',
  },
  {
    value: 'is_not_present',
    label: 'Is not present',
  },
  {
    value: 'is_greater_than',
    label: 'Is greater than',
  },
  {
    value: 'is_less_than',
    label: 'Is less than',
  },
];
```

## Summary Table

| Custom Attribute Type | Equal To | Not Equal To | Contains | Does Not Contain | Is Present | Is Not Present | Is Greater Than | Is Less Than |
|----------------------|----------|--------------|----------|------------------|------------|----------------|-----------------|--------------|
| **Text** (`text`) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ |
| **Number** (`number`) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **List** (`list`) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Checkbox** (`checkbox`) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Date** (`date`) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Link** (`link`) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Currency** (`currency`) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Percent** (`percent`) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

## Implementation Details

### Backend Validation
The backend validates custom attribute operators in:
```35:46:app/services/automation_rules/condition_validation_service.rb
  def valid_condition?(condition)
    key = condition['attribute_key']

    conversation_filter = @conversation_filters[key]
    contact_filter = @contact_filters[key]
    message_filter = @message_filters[key]

    if conversation_filter || contact_filter || message_filter
      operation_valid?(condition, conversation_filter || contact_filter || message_filter)
    else
      custom_attribute_present?(key, condition['custom_attribute_type'])
    end
  end
```

### Filter Processing
Custom attributes are processed in:
```132:139:app/services/filter_service.rb
  def custom_attribute_query(query_hash, custom_attribute_type, current_index)
    @attribute_key = query_hash[:attribute_key]
    @custom_attribute_type = custom_attribute_type
    attribute_data_type
    return '' if @custom_attribute.blank?

    build_custom_attr_query(query_hash, current_index)
  end
```

### Supported Attribute Display Types
```43:43:app/models/custom_attribute_definition.rb
  enum attribute_display_type: { text: 0, number: 1, currency: 2, percent: 3, link: 4, date: 5, list: 6, checkbox: 7 }
```

## ⚠️ Current Behavior in Automation Rules

**Important:** Based on user feedback, when creating or editing automation rules with Custom Attributes, you may see only **4 operators** for all custom attribute types:

1. `equal_to` - Equal to
2. `not_equal_to` - Not equal to  
3. `is_present` - Is present
4. `is_not_present` - Is not present

This appears to be a limitation in the current implementation where custom attributes default to `OPERATOR_TYPES_3` regardless of their display type when not in edit mode.

### Expected vs. Actual Behavior

| Custom Attribute Type | Expected Operators | Currently Showing |
|----------------------|-------------------|-------------------|
| **Text** (`text`) | equal_to, not_equal_to, is_present, is_not_present | ✅ All 4 (correct) |
| **Number** (`number`) | equal_to, not_equal_to | ❌ All 4 (should be 2) |
| **Date** (`date`) | equal_to, not_equal_to, is_present, is_not_present, is_greater_than, is_less_than | ❌ Only 4 (should be 6) |
| **List** (`list`) | equal_to, not_equal_to | ❌ All 4 (should be 2) |
| **Checkbox** (`checkbox`) | equal_to, not_equal_to | ❌ All 4 (should be 2) |
| **Link** (`link`) | equal_to, not_equal_to | ❌ All 4 (should be 2) |

### Root Cause

The issue is in the `getOperators` function in `app/javascript/dashboard/helper/automationHelper.js`:

```300:315:app/javascript/dashboard/helper/automationHelper.js
export const getOperators = (
  allCustomAttributes,
  automationTypes,
  automation,
  mode,
  key
) => {
  if (mode === 'edit') {
    const customAttribute = isACustomAttribute(allCustomAttributes, key);
    if (customAttribute) {
      return getOperatorTypes(customAttribute.attribute_display_type);
    }
  }
  const type = getAutomationType(automationTypes, automation, key);
  return type.filterOperators;
};
```

The function only checks for custom attributes when `mode === 'edit'`. When creating a new automation rule, it tries to get operators from `automationTypes` (the predefined AUTOMATIONS constant), which doesn't include custom attributes, causing it to fall back to a default that shows `OPERATOR_TYPES_3` for all custom attributes.

## Important Notes

1. **Text attributes** correctly show all 4 operators (`equal_to`, `not_equal_to`, `is_present`, `is_not_present`).

2. **Date attributes** should support 6 operators including comparison operators (`is_greater_than`, `is_less_than`), but currently only show 4.

3. **Number, List, Checkbox, Link, Currency, and Percent** should only show 2 operators (`equal_to`, `not_equal_to`), but currently show all 4.

4. **Contains/Does Not Contain** operators are **NOT available** for custom attributes in automation rules, even though they exist in the operator types. This is by design based on the `getOperatorTypes` function mapping.

5. Custom attributes can be used for both **conversation attributes** (`conversation_attribute`) and **contact attributes** (`contact_attribute`), and the same operator rules apply to both.

6. **Workaround:** The operators may work correctly when editing an existing automation rule that already has a custom attribute condition set.

## Usage Example

When creating an automation rule condition with a custom attribute:

1. Select the custom attribute from the dropdown
2. The available operators will automatically be filtered based on the attribute's display type
3. Enter the appropriate value(s) based on the selected operator
4. Use `AND` or `OR` to combine multiple conditions

Example: A date custom attribute "Last Purchase Date" would show:
- Equal to
- Not equal to
- Is present
- Is not present
- Is greater than
- Is less than

