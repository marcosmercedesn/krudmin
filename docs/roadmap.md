# Krudmin Roadmap & Improvement Recommendations

Generated: 2026-03-31

## High Impact, Low Effort

### 1. Fix existing deprecations

Quick wins that prevent breakage on upgrades:

- `include Pundit` → `include Pundit::Authorization` in `authorizable.rb` (already warning)
- `factory_girl` reference in `engine.rb` → `factory_bot`
- Poltergeist/PhantomJS in test setup is dead — switch to `cuprite` or `selenium`
- `to_s(:format)` patterns in the codebase (not just specs) will break on Ruby 3.4+

### 2. CSV/Excel export

Every admin panel needs this. A simple `index.csv.erb` response with a download button in the toolbar would add significant value with minimal code.

## High Impact, Medium Effort

### 3. Dashboard / widgets system

Right now there's `CustomController` but no structured way to build a dashboard. A simple widget DSL would be valuable:

```ruby
class AdminDashboard < Krudmin::Dashboard
  widget :count, model: "Product", label: "Total Products"
  widget :count, model: "Order", scope: :today, label: "Orders Today"
  widget :chart, model: "Order", group_by: :created_at, period: :month
end
```

### 4. ResourceManager validation at boot time

Right now, if you misconfigure a ResourceManager (wrong model name, missing association, bad attribute type), you get cryptic errors at request time. Adding a validation step that runs on boot and raises clear error messages would save developers hours of debugging:

```ruby
# Validate on app boot
Krudmin::ResourceManagers::Base.descendants.each(&:validate!)
```

Check: MODEL_CLASSNAME exists, ATTRIBUTE_TYPES reference valid fields, associations have `accepts_nested_attributes_for`, etc.

## Modernization (High Impact, High Effort)

### 5. Complete Hotwire migration (Turbo + Stimulus)

Turbo Streams and turbo-rails are already integrated. Cocoon has been replaced with a custom vanilla JS nested fields controller. The remaining work is:

- Replace remaining jQuery event binding with **Stimulus** controllers
- Remove `sweet-confirm.js`, `belongs-to-one-has-one-controls.js` and other custom jQuery code in favor of Stimulus

## Developer Experience

### 7. Additional generators

The install and resource generators exist. Additional generators would help:

```bash
rails generate krudmin:dashboard          # Generate dashboard controller + view
rails generate krudmin:field Phone         # Scaffold a custom field type
rails generate krudmin:theme my_theme      # Copy core_theme for customization
```

### 8. Configurable per-resource overrides without subclassing

Right now, customizing a controller action requires overriding the method. A hooks/callbacks system would be cleaner:

```ruby
class CarsResourceManager < Krudmin::ResourceManagers::Base
  before_create { |model| model.created_by = current_user }
  after_destroy { |model| AuditLog.record(:destroy, model) }

  # Scope visible records
  scope { |user| user.admin? ? model_class.all : model_class.where(team: user.team) }
end
```

### 9. API mode

The `_form.json.erb` and `index.json.erb` exist but are minimal. A proper API mode with JSON serialization, pagination metadata, and filtering would allow the admin to be used as a backend for custom frontends (React, mobile apps).

## Recommended Priority Order

| Priority | Item | Why |
|----------|------|-----|
| 1 | Fix deprecations (#1) | Prevents breakage, zero risk |
| 2 | ResourceManager validation (#4) | Biggest DX pain point |
| 3 | CSV export (#2) | Small effort, high value |
| 4 | Complete Hotwire migration (#5) | Foundation for everything else |
| 5 | Dashboard system (#3) | Differentiator vs. competitors |
| 6 | Additional generators (#7) | Improve onboarding |
