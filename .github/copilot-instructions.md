# Krudmin – Copilot Instructions

Krudmin is a **Ruby on Rails Engine gem** that generates admin dashboard interfaces (CRUD, search, authorization, status toggling) for host applications with minimal configuration.

## Commands

```bash
bundle exec rspec                                          # Run all tests
bundle exec rspec spec/lib/krudmin/fields/base_spec.rb    # Run a single spec file
bundle exec rspec spec/lib/krudmin/fields/base_spec.rb:42 # Run a single test by line number
bundle exec rubocop                                        # Lint (excludes spec/, bin/, config/initializers/)
bundle exec guard                                          # Auto-run tests on file changes

# Run the test app
cd spec/test_app && rails s
```

## Architecture

### The Resource Manager Pattern

Everything revolves around a **ResourceManager** — a plain Ruby class that configures an admin resource via class constants. Each controller in the host app maps to one ResourceManager by convention:

```
Admin::CarsController  →  CarsResourceManager
Admin::ProductsController  →  ProductsResourceManager
```

The resolution happens in `KrudminResourceManagerControllerSupport#inferred_resource_manager`:
```ruby
"#{self.class.name.demodulize.gsub('Controller', '')}ResourceManager".constantize
```

A minimal resource requires:
1. A ResourceManager (`app/resource_managers/products_resource_manager.rb`)
2. An empty controller inheriting `Krudmin::ApplicationController`
3. Routes with `activate`/`deactivate` member actions

### Request Flow

```
Controller (inherits Krudmin::ApplicationController)
  → before_action: set_model, authorize (Pundit, if enabled)
  → Action (index/new/create/edit/update/destroy/activate/deactivate)
    → MutationHandler (lib/krudmin/mutation_handlers/) wraps controller via SimpleDelegator
      → Model operation → Response dispatch (HTML redirect / JS render / JSON)
  → View (app/views/krudmin/core_theme/) renders via ResourceManager + Field Presenters
```

### Field Type System

Field classes live in `lib/krudmin/fields/`. The inflector (`lib/krudmin/fields/inflector.rb`) auto-maps ActiveRecord column types to field classes at runtime — you only need `ATTRIBUTE_TYPES` overrides when the default is wrong or you need extra options.

Auto-inference rules:
- `:string` → `Fields::String`, `:text` → `Fields::Text`
- `:integer/:bigint/:float/:decimal/:numeric` → `Fields::Number`
- `:datetime/:time` → `Fields::DateTime`, `:date` → `Fields::Date`
- `:boolean` → `Fields::Boolean`, `:json/:jsonb` → `Fields::Json`
- anything else → `Fields::String`

Each field has a matching **Presenter** in `lib/krudmin/presenters/` and view partials in `app/views/krudmin/core_theme/fields/{type}/`.

### Constants-to-Methods

`ConstantsToMethodsExposer` converts ResourceManager constants into instance/class methods automatically. `SEARCHABLE_ATTRIBUTES` becomes `#searchable_attributes`, `LISTABLE_ACTIONS` becomes `#listable_actions`, etc.

## Key Conventions

### ATTRIBUTE_TYPES: Symbol vs Hash

```ruby
ATTRIBUTE_TYPES = {
  year:        :Number,                          # Symbol shorthand — just change the type
  active:      { type: :Boolean, input: { label: "Is Active" } },  # Hash — type + options
  car_brand_id: {
    type: :BelongsTo,
    collection_label_field: :description,        # Dropdown display field
    association_path: :car_brand_path,           # Link in show view
    add_path: :new_car_brand,                    # "Add new" helper
    edit_path: :edit_car_brand,                  # "Edit" helper
    remote: true                                 # AJAX search for large collections
  },
  transmission: { type: :EnumType, associated_options: -> { Car.transmissions } },
  description:  { type: :RichText, show_length: 20 },
  id:           { type: :Number, padding: 10, prefix: :CK },
}
```

### EDITABLE_ATTRIBUTES: Array vs Hash (sections)

```ruby
# Flat — single-section form
EDITABLE_ATTRIBUTES = [:name, :price, :active]

# Grouped — multi-section form; keys must match PRESENTATION_METADATA keys
EDITABLE_ATTRIBUTES = {
  general:    [:active, :description],
  pricing:    [:price, :cost],
  passengers: [:passengers],    # HasMany nested form
  insurance:  [:car_insurance], # HasOne nested form
}

PRESENTATION_METADATA = {
  general:  { label: "General Info", class: "col-lg-6 col-md-12" },
  pricing:  { label: "Pricing",      class: "col-lg-6 col-md-12" },
}
```

### Nested Forms Require Model Setup

`HasMany`, `HasOne`, and `BelongsToOne` fields require `accepts_nested_attributes_for` on the model:

```ruby
class Car < ApplicationRecord
  has_many :passengers
  accepts_nested_attributes_for :passengers, allow_destroy: true

  has_one :car_insurance
  accepts_nested_attributes_for :car_insurance, allow_destroy: true
end
```

The nested ResourceManager is auto-inferred from the association class name — `Car` has_many `Passenger` → looks for `PassengersResourceManager`.

### Inline Editing

`INLINE_EDITABLE_ATTRIBUTES` only supports these field types: `String`, `Text`, `Number`, `Decimal`, `Currency`, `Boolean`, `Date`, `DateTime`, `Email`, `EnumType`, `BelongsTo`.

### Search Cookie Persistence

Search state persists per-resource in a cookie (`krudmin_search_results`). Reset with `?reset_search=1` in the URL.

### Adding a New Resource (Checklist)

1. **ResourceManager** — `app/resource_managers/products_resource_manager.rb`
   - Set `MODEL_CLASSNAME`, attribute arrays, `RESOURCE_LABEL`/`RESOURCES_LABEL`, `RESOURCE_INSTANCE_LABEL_ATTRIBUTE`
2. **Controller** — `app/controllers/admin/products_controller.rb` inheriting `Krudmin::ApplicationController` (empty body is fine)
3. **Routes** — `resources :products` with `member { post :activate; post :deactivate }` inside `namespace :admin`
4. **Navigation** — `menu.node label: "Products", resource: "product", module_path: :admin, icon: :tag` in the initializer
5. **Policy** (optional) — Pundit policy with `index?`, `show?`, `create?`, `update?`, `destroy?`, `activate?`, `deactivate?`

### Adding a New Field Type

1. Create field class in `lib/krudmin/fields/` (inherit from `Krudmin::Fields::Base` or `Krudmin::Fields::Associated`)
2. Create presenter in `lib/krudmin/presenters/`
3. Create HAML partials in `app/views/krudmin/core_theme/fields/{type}/`
4. Add `require` in `lib/krudmin.rb`
5. Add AR column type mapping in `lib/krudmin/fields/inflector.rb` if applicable

### Views

- All templates use **HAML** (not ERB)
- Forms use **simple_form**
- Theme-namespaced: partials live under `app/views/krudmin/{theme}/` (default theme: `core_theme`)
- `REMOTE_CRUD = true` enables AJAX form submission (JS responses via mutation handlers)

### ResourceManager Constants Reference

| Constant | Default | Purpose |
|---|---|---|
| `MODEL_CLASSNAME` | `nil` | AR model class name (string) |
| `EDITABLE_ATTRIBUTES` | `[]` | Form fields (array or grouped hash) |
| `LISTABLE_ATTRIBUTES` | `[]` | Index table columns |
| `SEARCHABLE_ATTRIBUTES` | `[]` | Search filter fields |
| `DISPLAYABLE_ATTRIBUTES` | `[]` | Show page fields |
| `LISTABLE_ACTIONS` | `[:show, :edit, :destroy]` | Per-row action buttons |
| `LISTABLE_INCLUDES` | `[]` | Eager-loaded associations |
| `ORDER_BY` | `[]` | Default sort (e.g., `[:year]` or `[year: :desc]`) |
| `BULK_ACTIONS` | `[]` | `:destroy`, `:activate`, `:deactivate` |
| `INLINE_EDITABLE_ATTRIBUTES` | `[]` | Fields editable inline in the list view |
| `REMOTE_CRUD` | `false` | AJAX form submission |
| `PAGINATOR_POSITION` | `nil` (uses global config) | `:top`, `:bottom`, `:top_and_bottom` |
| `PRESENTATION_METADATA` | `{}` | Section labels and CSS classes for grouped forms |
| `DASHBOARD_SCOPES` | `{}` | Named relation scopes for dashboard widgets |
| `DASHBOARD_COLUMNS` | `{}` | Named column sets for dashboard widgets |

### Reference Implementation

`spec/test_app/app/resource_managers/cars_resource_manager.rb` is the most complete example — it demonstrates grouped `EDITABLE_ATTRIBUTES`, all field types including `HasMany`/`HasOne`/`BelongsTo`/`EnumType`, `PRESENTATION_METADATA`, `DASHBOARD_SCOPES`, `DASHBOARD_COLUMNS`, `BULK_ACTIONS`, `INLINE_EDITABLE_ATTRIBUTES`, and `REMOTE_CRUD`.
