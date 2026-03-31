# Krudmin Roadmap & Improvement Recommendations

Generated: 2026-03-31

## High Impact, Low Effort

### 1. Fix existing deprecations

Quick wins that prevent breakage on upgrades:

- `include Pundit` → `include Pundit::Authorization` in `authorizable.rb` (already warning)
- `factory_girl` reference in `engine.rb` → `factory_bot`
- Poltergeist/PhantomJS in test setup is dead — switch to `cuprite` or `selenium`
- `to_s(:format)` patterns in the codebase (not just specs) will break on Ruby 3.4+

### 2. Add missing field types

Compared to Administrate and ActiveAdmin, these are missing:

- **File/Image** — File upload field (Active Storage integration). This is the most requested feature in any admin framework.
- **JSON/JSONB** — PostgreSQL JSON fields are very common now. Render as a code editor or key-value pairs.
- **Polymorphic** — `belongs_to :commentable, polymorphic: true` has no support currently.

### 3. CSV/Excel export

Every admin panel needs this. A simple `index.csv.erb` response with a download button in the toolbar would add significant value with minimal code.

### 4. Bulk actions

Select multiple rows → delete, activate, deactivate, export. This is table-stakes for admin panels. Would need checkboxes in `_list_item.html.haml` and a new controller concern.

## High Impact, Medium Effort

### 5. Dashboard / widgets system

Right now there's `CustomController` but no structured way to build a dashboard. A simple widget DSL would be valuable:

```ruby
class AdminDashboard < Krudmin::Dashboard
  widget :count, model: "Product", label: "Total Products"
  widget :count, model: "Order", scope: :today, label: "Orders Today"
  widget :chart, model: "Order", group_by: :created_at, period: :month
end
```

### 6. Inline editing in list view

Click a cell to edit it in-place. This is one of the biggest UX gaps vs. competitors. With Turbo Frames, this becomes much simpler than the current jQuery approach.

### 7. ResourceManager validation at boot time

Right now, if you misconfigure a ResourceManager (wrong model name, missing association, bad attribute type), you get cryptic errors at request time. Adding a validation step that runs on boot and raises clear error messages would save developers hours of debugging:

```ruby
# Validate on app boot
Krudmin::ResourceManagers::Base.descendants.each(&:validate!)
```

Check: MODEL_CLASSNAME exists, ATTRIBUTE_TYPES reference valid fields, associations have `accepts_nested_attributes_for`, etc.

## Modernization (High Impact, High Effort)

### 8. Migrate from jQuery/Turbolinks to Hotwire (Turbo + Stimulus)

This is the biggest modernization opportunity. The current stack (jQuery 3, Turbolinks, Cocoon, UJS) is legacy Rails. Modern Rails uses:

- **Turbo** instead of Turbolinks + `remote: true` + custom JS responses
- **Stimulus** instead of jQuery event binding
- **Turbo Frames** instead of the custom `turbo-forms.js`

This would eliminate most of the custom JavaScript (`turbo-forms.js`, `sweet-confirm.js`, `belongs-to-one-has-one-controls.js`) and make the codebase much more maintainable. The AJAX form handling (`edit.js.erb`, `destroy.js.erb`, etc.) would be replaced by Turbo Streams.

### 9. Bootstrap 4 → Bootstrap 5

Bootstrap 4 is EOL. Bootstrap 5 drops jQuery dependency (aligns with item 8), has improved utilities, and better RTL support. The gem currently pins `bootstrap >= 4.1.3, < 4.5.0`.

### 10. Replace Cocoon with Turbo-based nested forms

Cocoon is unmaintained. Stimulus-based alternatives (or a simple custom Stimulus controller) would handle add/remove of nested `has_many` rows.

### 11. Replace Summernote with ActionText/Trix

Summernote is jQuery-dependent and heavy. Rails ships with ActionText + Trix out of the box. This would simplify the RichText field and drop the `summernote-rails` dependency.

## Developer Experience

### 12. Additional generators

The install and resource generators exist. Additional generators would help:

```bash
rails generate krudmin:dashboard          # Generate dashboard controller + view
rails generate krudmin:field Phone         # Scaffold a custom field type
rails generate krudmin:theme my_theme      # Copy core_theme for customization
```

### 13. Configurable per-resource overrides without subclassing

Right now, customizing a controller action requires overriding the method. A hooks/callbacks system would be cleaner:

```ruby
class CarsResourceManager < Krudmin::ResourceManagers::Base
  before_create { |model| model.created_by = current_user }
  after_destroy { |model| AuditLog.record(:destroy, model) }

  # Scope visible records
  scope { |user| user.admin? ? model_class.all : model_class.where(team: user.team) }
end
```

### 14. API mode

The `_form.json.erb` and `index.json.erb` exist but are minimal. A proper API mode with JSON serialization, pagination metadata, and filtering would allow the admin to be used as a backend for custom frontends (React, mobile apps).

## Recommended Priority Order

| Priority | Item | Why |
|----------|------|-----|
| 1 | Fix deprecations (#1) | Prevents breakage, zero risk |
| 2 | ResourceManager validation (#7) | Biggest DX pain point |
| 3 | File/Image field (#2) | Most requested missing feature |
| 4 | CSV export (#3) | Small effort, high value |
| 5 | Bulk actions (#4) | Table-stakes for admin panels |
| 6 | Hotwire migration (#8) | Foundation for everything else |
| 7 | Bootstrap 5 (#9) | Do alongside Hotwire migration |
| 8 | Dashboard system (#5) | Differentiator vs. competitors |
| 9 | Inline editing (#6) | Easy once Hotwire is in place |
| 10 | ActionText (#11) | Drop jQuery dependency piece |
