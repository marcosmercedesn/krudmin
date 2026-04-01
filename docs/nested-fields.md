# Nested Fields (HasMany Forms)

## Overview

Krudmin uses a custom vanilla JavaScript controller (`nested-fields.js`) to manage
add/remove behavior for HasMany nested forms. This replaced the unmaintained
[Cocoon](https://github.com/nathanvda/cocoon) gem.

The system is ~120 lines of vanilla JS with no external dependencies. It works
with Rails' standard `accepts_nested_attributes_for` — no model changes needed.

## How It Works

### The Big Picture

When you have a HasMany association (e.g., a Car has many Passengers), the edit
form needs to:

1. Show a row for each existing Passenger
2. Let the user **add** new blank rows
3. Let the user **remove** rows (marking them for deletion)

Rails handles the backend via `accepts_nested_attributes_for`. The JavaScript
handles the frontend (cloning/hiding DOM rows).

### The Template Pattern

The key technique is using an HTML `<template>` element:

```
┌─────────────────────────────────────────────────┐
│ <table>                                         │
│   <tbody data-nested-target="body">             │
│     <tr>  ← existing row (index 0)              │
│     <tr>  ← existing row (index 1)              │
│   </tbody>                                      │
│                                                 │
│   <template data-nested-target="template">      │
│     <tr>  ← blank row with NEW_RECORD placeholder│
│   </template>                                   │
│                                                 │
│   <button data-nested-action="add">Add</button> │
│ </table>                                        │
└─────────────────────────────────────────────────┘
```

The `<template>` tag is special: browsers don't render its contents. It's just
a holding area for HTML that JavaScript can clone.

### Adding a Row

When the user clicks "Add":

1. JS reads the `<template>` innerHTML
2. Replaces every `NEW_RECORD` string with a unique timestamp (e.g., `1711929600000`)
3. Appends the resulting HTML to the `<tbody>`
4. Fires `krudmin:updateControls` so Select2/datepickers/Trix reinitialize

**Why a timestamp?** Rails nested attributes need each record to have a unique
index key. It doesn't need to be sequential — just unique. `Date.now()` gives
us millisecond precision, which is unique enough for form submissions.

### Removing a Row

When the user clicks the trash icon on a row:

- **Persisted records** (already saved to DB): JS sets the hidden `_destroy`
  field to `"1"` and hides the row. When the form submits, Rails sees `_destroy=1`
  and deletes the record.

- **New records** (just added, never saved): JS removes the `<tr>` entirely from
  the DOM. Nothing to tell Rails — the record never existed.

## Data Attributes Reference

| Attribute | Element | Purpose |
|-----------|---------|---------|
| `data-nested-fields="container"` | Wrapper `<div>` | Scopes the JS to this nested fields group |
| `data-nested-target="body"` | `<tbody>` | Where rows live and get appended |
| `data-nested-target="template"` | `<template>` | Holds the blank row HTML |
| `data-nested-action="add"` | Button | Triggers adding a new row |
| `data-nested-action="remove"` | Button (per row) | Triggers removing that row |

## File Locations

| File | Purpose |
|------|---------|
| `app/assets/javascripts/krudmin/nested-fields.js` | The JS controller (add/remove logic) |
| `app/views/krudmin/core_theme/fields/has_many/_form_field.html.haml` | Table layout + template + add button |
| `app/views/krudmin/core_theme/fields/has_many/_form_fields.html.haml` | Single row partial (used for existing + template) |
| `lib/krudmin/fields/has_many.rb` | Field class (association metadata) |
| `lib/krudmin/presenters/has_many_field_presenter.rb` | Presenter (wires field → partials) |

## The _destroy Convention

Rails' `accepts_nested_attributes_for` with `allow_destroy: true` expects a
`_destroy` field in the nested params:

```ruby
# Model setup
class Car < ApplicationRecord
  has_many :passengers
  accepts_nested_attributes_for :passengers, allow_destroy: true
end
```

```html
<!-- What the form submits for a "removed" row -->
<input type="hidden" name="car[passengers_attributes][0][id]" value="42">
<input type="hidden" name="car[passengers_attributes][0][_destroy]" value="1">
```

When Rails processes these params, it sees `_destroy=1` for passenger 42 and
deletes it. The hidden field has class `destroy-flag` so JS can find it easily.

## Integration with Rich Controls

After adding a new row, the JS dispatches a `krudmin:updateControls` event.
The rest of krudmin listens for this event to reinitialize:

- Select2 dropdowns
- Date/time pickers (daterangepicker)
- Trix rich text editors
- Bootstrap tooltips

This is defined in `app/assets/javascripts/krudmin/core_theme/app.js`:

```javascript
document.addEventListener("krudmin:updateControls", function(e) {
  initKrudminScriptsForControls();
});
```

## Comparison with Cocoon

| Aspect | Cocoon (old) | nested-fields.js (current) |
|--------|-------------|---------------------------|
| Dependency | External gem | Zero — built-in |
| Size | Gem + jQuery plugin | ~120 lines vanilla JS |
| Template mechanism | Server-rendered `data-association-insertion-template` | Standard `<template>` HTML element |
| Index generation | Ruby `Time.now.to_i * 1000` in partial | JS `Date.now()` on click |
| Event system | `cocoon:after-insert`, `cocoon:after-remove` | `krudmin:updateControls` |
| jQuery required | Yes | No |

## Customization

### Custom Row Partial

You can override the row partial per field via the `child_partial_form` option:

```ruby
ATTRIBUTE_TYPES = {
  passengers: { type: :HasMany, child_partial_form: :custom_form_fields }
}
```

This looks for `app/views/krudmin/core_theme/fields/has_many/_custom_form_fields.html.haml`.

### Custom Association Options

```ruby
ATTRIBUTE_TYPES = {
  passengers: {
    type: :HasMany,
    association_name: :passengers,          # defaults to attribute name
    class_name: "Passenger",               # defaults to singularized association
    resource_manager: "PassengersResourceManager"  # defaults to inferred
  }
}
```
