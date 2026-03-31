# Field Types

Krudmin includes 18+ field types for rendering, parsing, and searching model attributes. Field types are either auto-detected from ActiveRecord column types or explicitly configured in `ATTRIBUTE_TYPES`.

## Type Detection

When a field is not listed in `ATTRIBUTE_TYPES`, Krudmin auto-detects the type from the ActiveRecord column via `Krudmin::Fields::Inflector`:

| ActiveRecord Type | Field Class |
|-------------------|-------------|
| `:string` | `Krudmin::Fields::String` |
| `:text` | `Krudmin::Fields::Text` |
| `:integer`, `:bigint`, `:float`, `:decimal`, `:numeric` | `Krudmin::Fields::Number` |
| `:datetime`, `:time` | `Krudmin::Fields::DateTime` |
| `:date` | `Krudmin::Fields::Date` |
| `:boolean` | `Krudmin::Fields::Boolean` |

## Configuring Field Types

In `ATTRIBUTE_TYPES`, use symbol shorthand or a full options hash:

```ruby
ATTRIBUTE_TYPES = {
  # Symbol shorthand (type only)
  year: :Number,

  # Full options hash
  price: { type: :Currency, prefix: "$", decimals: 2 },

  # With input options (passed to SimpleForm)
  model: { type: :Text, input: { rows: 2 } },
}
```

## Field Types Reference

### String

**Class:** `Krudmin::Fields::String`
**Renders:** Text input
**Search Operators:** contains, equals, matches, less_than, greater_than, starts_with, ends_with

```ruby
name: :String
name: { type: :String, input: { placeholder: "Enter name" } }
```

### Text

**Class:** `Krudmin::Fields::Text`
**Inherits:** String
**Renders:** Textarea

```ruby
description: :Text
description: { type: :Text, input: { rows: 5 } }
```

### Number

**Class:** `Krudmin::Fields::Number`
**Renders:** Numeric input (right-aligned in list/show)

**Options:**
- `padding` — Zero-pad to N digits (e.g., `padding: 10` → `0000000042`)
- `prefix` — Prefix string (e.g., `prefix: :CK` → `CK0000000042`)

```ruby
year: :Number
id: { type: :Number, padding: 10, prefix: :CK }
```

### Decimal

**Class:** `Krudmin::Fields::Decimal`
**Inherits:** Number
**Renders:** Numeric input with thousands delimiter

Formats with `number_with_delimiter` in display.

```ruby
weight: :Decimal
```

### Currency

**Class:** `Krudmin::Fields::Currency`
**Inherits:** Number
**Renders:** Currency-formatted display

Uses Rails `number_to_currency` for display.

```ruby
price: :Currency
price: { type: :Currency, prefix: "$" }
```

### Boolean

**Class:** `Krudmin::Fields::Boolean`
**Renders:** Checkbox in forms, colored badges in list/show
**Search:** Yes/No dropdown

Includes `ActivableLabeler` for rendering green (Active/Yes) and red (Inactive/No) badges.

```ruby
active: :Boolean
active: { type: :Boolean, input: { label: "Is Active" } }
```

### Date

**Class:** `Krudmin::Fields::Date`
**Renders:** Date picker input (uses daterangepicker JS)
**Search:** From/To date range inputs

**Options:**
- `format` — Ruby date format (e.g., `:short`)

The search generates two fields: `{attribute}__from` and `{attribute}__to` for range filtering.

```ruby
release_date: :Date
release_date: { type: :Date, format: :short }
```

### DateTime

**Class:** `Krudmin::Fields::DateTime`
**Inherits:** Date
**Renders:** DateTime picker input
**Search:** From/To datetime range inputs

```ruby
created_at: :DateTime
created_at: { type: :DateTime, format: :short }
```

### Email

**Class:** `Krudmin::Fields::Email`
**Inherits:** String
**Renders:** Email input

```ruby
email: :Email
```

### Password

**Class:** `Krudmin::Fields::Password`
**Inherits:** String
**Renders:** Password input (masked)

```ruby
password: :Password
```

### Hidden

**Class:** `Krudmin::Fields::Hidden`
**Renders:** Hidden input field
**Note:** Not rendered in list, show, or search views

```ruby
token: :Hidden
```

### RichText

**Class:** `Krudmin::Fields::RichText`
**Inherits:** String
**Renders:** Summernote WYSIWYG editor
**Display:** Renders HTML (marked as html_safe)

**Options:**
- `show_length` — Truncate display to N characters

```ruby
content: :RichText
description: { type: :RichText, show_length: 20 }
```

### EnumType

**Class:** `Krudmin::Fields::EnumType`
**Inherits:** BelongsTo
**Renders:** Select dropdown populated from Rails enum

**Required Options:**
- `associated_options` — Proc/lambda returning the enum hash

```ruby
# Model: enum role: { admin: 1, user: 2 }
role: { type: :EnumType, associated_options: -> { User.roles } }

# Model: enum transmission: { automatic: 0, manual: 1 }
transmission: { type: :EnumType, associated_options: -> { Car.transmissions } }
```

### BelongsTo

**Class:** `Krudmin::Fields::BelongsTo`
**Renders:** Select dropdown for choosing an associated record

**Options:**
- `collection_label_field` — Which attribute to display in dropdown (default: `:label`)
- `remote` — Enable AJAX search for large collections (`true`/`false`)
- `association_path` — Route helper for linking in show view
- `add_path` — Route helper for "Add New" link
- `edit_path` — Route helper for "Edit" link
- `grouped` — Enable grouped select (`true`/`false`)
- `association_predicate` — Lambda to filter available options

**Requirements:** The model must have a `belongs_to` association.

```ruby
category_id: { type: :BelongsTo, collection_label_field: :name }

car_brand_id: {
  type: :BelongsTo,
  collection_label_field: :description,
  association_path: :car_brand_path,
  add_path: :new_car_brand,
  edit_path: :edit_car_brand,
  remote: true
}
```

**Remote search:** When `remote: true`, the dropdown uses Select2 with AJAX. The associated model should have a `search_by_term` scope:

```ruby
class CarBrand < ApplicationRecord
  scope :search_by_term, ->(term) { where("description ILIKE ?", "%#{term}%") }
end
```

### BelongsToOne

**Class:** `Krudmin::Fields::BelongsToOne`
**Inherits:** HasOne
**Renders:** Inline nested form for a belongs_to association

Use this when you want to edit the parent association inline rather than via a dropdown.

**Requirements:**
- Model must have `belongs_to` association
- Model must have `accepts_nested_attributes_for`
- A Resource Manager must exist for the associated model

```ruby
car_owner: :BelongsToOne
```

### HasMany

**Class:** `Krudmin::Fields::HasMany`
**Renders:** Nested form collection using Cocoon (add/remove rows)

**Requirements:**
- Model must have `has_many` association
- Model must have `accepts_nested_attributes_for` with `allow_destroy: true`
- A Resource Manager must exist for the associated model

```ruby
passengers: :HasMany
```

The associated Resource Manager defines which fields appear in each nested row.

### HasManyIds

**Class:** `Krudmin::Fields::HasManyIds`
**Renders:** Multi-select dropdown for many-to-many associations

Use this for associations where you only need to select IDs, not edit nested attributes.

```ruby
tag_ids: :HasManyIds
```

### HasOne

**Class:** `Krudmin::Fields::HasOne`
**Renders:** Inline nested form for a single associated record

**Options:**
- `required` — Whether the nested record is mandatory (`true`/`false`)

**Requirements:**
- Model must have `has_one` association
- Model must have `accepts_nested_attributes_for`
- A Resource Manager must exist for the associated model

```ruby
car_insurance: { type: :HasOne, required: true }
address: :HasOne
```

## Common Options

These options are available on all field types:

| Option | Description |
|--------|-------------|
| `type` | Field type class (symbol or full class) |
| `input` | Hash of options passed to SimpleForm input |
| `json` | Options for JSON rendering |
| `partial_form` | Override the form partial name |
| `present_with` | Custom presenter class |

## Field Class Hierarchy

```
Krudmin::Fields::Base
├── String
│   ├── Text
│   ├── Email
│   ├── Password
│   ├── Hidden
│   └── RichText
├── Number
│   ├── Decimal
│   └── Currency
├── Boolean
├── Date
│   └── DateTime
└── Associated
    ├── BelongsTo
    │   └── EnumType
    ├── HasMany
    │   ├── HasManyIds
    │   └── HasOne
    │       └── BelongsToOne
    └── (abstract base)
```

## Creating Custom Field Types

To create a new field type:

1. **Create the field class** in `lib/krudmin/fields/`:

```ruby
# lib/krudmin/fields/phone.rb
module Krudmin
  module Fields
    class Phone < String
      def parse(value)
        value.to_s.gsub(/[^0-9+]/, '')  # Strip non-numeric
      end
    end
  end
end
```

2. **Create the presenter** in `lib/krudmin/presenters/`:

```ruby
# lib/krudmin/presenters/phone_field_presenter.rb
module Krudmin
  module Presenters
    class PhoneFieldPresenter < BaseFieldPresenter
      def render_list
        # Format for display
        value = field.data.to_s
        "(#{value[0..2]}) #{value[3..5]}-#{value[6..]}"
      end
    end
  end
end
```

3. **Create view partials** in `app/views/krudmin/core_theme/fields/phone/`:
   - `_form_field.html.haml` — Form input
   - `_search.html.haml` — Search filter (optional)

4. **Require in `lib/krudmin.rb`**:

```ruby
require_relative "krudmin/fields/phone"
require_relative "krudmin/presenters/phone_field_presenter"
```

5. **Add to Inflector** (if mapping to an AR column type) in `lib/krudmin/fields/inflector.rb`.
