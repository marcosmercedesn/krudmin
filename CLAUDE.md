# CLAUDE.md - AI Agent Guide for Krudmin

## Project Overview

Krudmin is a **Ruby on Rails Engine** (gem) that generates admin dashboard interfaces. It provides CRUD operations, search/filtering, authorization, and status toggling for ActiveRecord models with minimal configuration. It runs alongside a host Rails application.

- **Version**: 0.1.7.9.5.31
- **Ruby**: 3.4.6
- **License**: MIT
- **Author**: Marcos Mercedes

## Quick Reference

### Running the project

```bash
# Install dependencies
bundle install

# Run the test app (in spec/test_app/)
cd spec/test_app && rails s

# Run tests
bundle exec rspec

# Run a specific test file
bundle exec rspec spec/lib/krudmin/fields/base_spec.rb
```

### Key commands

```bash
bundle exec rspec              # Run all tests
bundle exec rubocop            # Lint code
bundle exec guard              # Auto-run tests on file changes
```

## Architecture

### Directory Layout

```
krudmin/
├── app/
│   ├── assets/                    # JS, CSS, images (Bootstrap + CoreUI theme)
│   ├── controllers/krudmin/       # ApplicationController + concerns
│   ├── helpers/krudmin/           # View helpers
│   ├── models/krudmin/            # User model (Devise-backed)
│   ├── policies/                  # Pundit authorization policies
│   ├── resource_managers/         # Example: UsersResourceManager
│   └── views/krudmin/             # HAML templates (core_theme)
├── config/
│   ├── initializers/              # Devise, SimpleForm Bootstrap config
│   └── locales/                   # I18n translations (en.yml)
├── lib/
│   ├── krudmin.rb                 # Main entry point (requires everything)
│   ├── config.rb                  # Krudmin::Config module
│   └── krudmin/
│       ├── engine.rb              # Rails Engine setup
│       ├── fields/                # 23 field types (String, Number, BelongsTo, HasMany, etc.)
│       ├── presenters/            # 18 field presenters (render logic per field type)
│       ├── resource_managers/     # Base class, AttributeCollection, Routing, Attribute
│       ├── mutation_handlers/     # CreateHandler, UpdateHandler, DestroyHandler, SwitchOn/Off
│       ├── action_buttons/        # 11 button types (save, edit, destroy, active, etc.)
│       ├── search_form/           # SearchFilter, CalendarFilter, predicates
│       ├── navigation_menu/       # Menu builder (Node)
│       ├── toolbar.rb             # Toolbar DSL
│       ├── params_parser.rb       # Strong params parsing with field-aware transformation
│       ├── search_form.rb         # Search form builder
│       └── navigation_menu.rb     # NavigationMenu class
├── spec/
│   ├── test_app/                  # Dummy Rails app showing real usage patterns
│   └── ...                        # RSpec tests
└── docs/                          # Documentation
```

### Core Concepts

1. **Resource Manager** (`lib/krudmin/resource_managers/base.rb`): The central configuration object. Each admin resource (e.g., Cars, Users) has a ResourceManager that defines which fields are editable, listable, searchable, and displayable. Convention: `{Model}sResourceManager` (e.g., `CarsResourceManager`).

2. **Fields** (`lib/krudmin/fields/`): Type system for model attributes. Each field type knows how to parse input, format output, and configure search. Types: String, Text, Number, Decimal, Currency, Boolean, Date, DateTime, Email, Password, Hidden, RichText, EnumType, BelongsTo, BelongsToOne, HasMany, HasManyIds, HasOne.

3. **Presenters** (`lib/krudmin/presenters/`): Handle rendering of fields in different contexts (form, show, list, search, json). Each field type has a corresponding presenter.

4. **Mutation Handlers** (`lib/krudmin/mutation_handlers/`): Service objects that handle CRUD operations and manage response dispatch (HTML redirect vs JS render vs JSON).

5. **Controller Concerns** (`app/controllers/concerns/krudmin/`): Modular behaviors mixed into controllers — Searchable, Authorizable, ModelStatusToggler, CrudMessages, ActionButtonsSupport, etc.

### How Resources Work

The controller name determines the ResourceManager via convention:
- `Admin::CarsController` → looks for `CarsResourceManager`
- ResourceManager defines constants: `MODEL_CLASSNAME`, `EDITABLE_ATTRIBUTES`, `LISTABLE_ATTRIBUTES`, `SEARCHABLE_ATTRIBUTES`, `ATTRIBUTE_TYPES`, etc.
- The controller inherits from `Krudmin::ApplicationController` and gets all CRUD actions automatically.

### Request Flow

```
HTTP Request → Controller (inherits Krudmin::ApplicationController)
  → before_action: set_model, authorize (if Pundit enabled)
  → Action (index/new/create/edit/update/destroy/activate/deactivate)
    → MutationHandler (for create/update/destroy/activate/deactivate)
      → Model operation (save/destroy/activate!/deactivate!)
      → Response dispatch (HTML redirect / JS render / JSON)
  → View renders using ResourceManager metadata + Field Presenters
```

### Key Design Patterns

- **Convention over Configuration**: ResourceManager inferred from controller name; field types inferred from ActiveRecord column types.
- **Constants-to-Methods**: `ConstantsToMethodsExposer` converts class constants like `SEARCHABLE_ATTRIBUTES` into instance/class methods.
- **Presenter Pattern**: Fields delegate rendering to Presenter classes.
- **Service Objects**: MutationHandlers encapsulate CRUD transaction logic.
- **SimpleDelegator**: MutationHandlers wrap controllers for clean response dispatching.
- **DSL**: NavigationMenu and Toolbar use builder patterns.

## Creating a New Resource (Step-by-Step)

When asked to add a new admin resource, follow these steps:

### 1. Create the ResourceManager

```ruby
# app/resource_managers/products_resource_manager.rb
class ProductsResourceManager < Krudmin::ResourceManagers::Base
  MODEL_CLASSNAME = "Product"

  EDITABLE_ATTRIBUTES = [:name, :price, :description, :active]
  LISTABLE_ATTRIBUTES = [:name, :price, :active]
  SEARCHABLE_ATTRIBUTES = [:name, :price, :active]
  DISPLAYABLE_ATTRIBUTES = [:name, :price, :description, :active, :created_at]
  LISTABLE_ACTIONS = [:show, :edit, :active, :destroy]

  RESOURCE_INSTANCE_LABEL_ATTRIBUTE = :name
  RESOURCE_LABEL = "Product"
  RESOURCES_LABEL = "Products"

  ATTRIBUTE_TYPES = {
    price: :Currency,
    active: :Boolean,
    description: :RichText
  }
end
```

### 2. Create the Controller

```ruby
# app/controllers/admin/products_controller.rb
class Admin::ProductsController < Krudmin::ApplicationController
end
```

### 3. Add Routes

```ruby
# config/routes.rb
namespace :admin do
  resources :products do
    member do
      post :activate
      post :deactivate
    end
  end
end
```

### 4. Add to Navigation Menu (in Krudmin initializer)

```ruby
menu.node label: "Products", resource: "product", module_path: :admin, icon: :shopping_cart
```

### 5. (Optional) Add Pundit Policy

```ruby
# app/policies/product_policy.rb
class ProductPolicy < ApplicationPolicy
  def index?; true; end
  def show?; true; end
  def create?; user.admin?; end
  def update?; user.admin?; end
  def destroy?; user.admin?; end
  def activate?; user.admin?; end
  def deactivate?; user.admin?; end
end
```

## ResourceManager Constants Reference

| Constant | Type | Description |
|----------|------|-------------|
| `MODEL_CLASSNAME` | String | ActiveRecord model class name |
| `EDITABLE_ATTRIBUTES` | Array or Hash | Fields in create/edit forms. Hash groups fields into sections |
| `LISTABLE_ATTRIBUTES` | Array | Columns shown in index/list view |
| `SEARCHABLE_ATTRIBUTES` | Array | Fields available as search filters |
| `DISPLAYABLE_ATTRIBUTES` | Array | Fields shown in show/detail view |
| `LOOKUP_ATTRIBUTES` | Array | Fields used for association lookups |
| `LISTABLE_ACTIONS` | Array | Actions per item: `:show`, `:edit`, `:destroy`, `:active` |
| `LISTABLE_INCLUDES` | Array | Eager-loaded associations (prevents N+1) |
| `ORDER_BY` | Array | Default sort (e.g., `[:year]` or `[year: :desc]`) |
| `ATTRIBUTE_TYPES` | Hash | Field type overrides and options per attribute |
| `RESOURCE_INSTANCE_LABEL_ATTRIBUTE` | Symbol | Attribute used as display label (default: `:id`) |
| `RESOURCE_LABEL` | String | Singular label (e.g., "Car") |
| `RESOURCES_LABEL` | String | Plural label (e.g., "Cars") |
| `PRESENTATION_METADATA` | Hash | Layout groups with labels and CSS classes |
| `REMOTE_CRUD` | Boolean | Enable AJAX form submission (default: `false`) |
| `BULK_ACTIONS` | Array | Bulk actions for selected rows: `:destroy`, `:activate`, `:deactivate` |
| `PAGINATOR_POSITION` | Symbol | `:top`, `:bottom`, or `:top_and_bottom` |

## ATTRIBUTE_TYPES Options

```ruby
ATTRIBUTE_TYPES = {
  # Simple type (symbol shorthand)
  year: :Number,

  # Full options hash
  price: { type: :Currency, prefix: "$", decimals: 2 },
  description: { type: :RichText, show_length: 20 },
  active: { type: :Boolean, input: { label: "Is Active" } },
  role: { type: :EnumType, associated_options: -> { User.roles } },

  # BelongsTo with options
  car_brand_id: {
    type: :BelongsTo,
    collection_label_field: :description,  # Which field to show in dropdown
    association_path: :car_brand_path,      # Link in show view
    add_path: :new_car_brand,              # "Add new" link
    edit_path: :edit_car_brand,            # "Edit" link
    remote: true                            # AJAX search for large collections
  },

  # HasMany nested forms
  passengers: :HasMany,

  # HasOne nested form
  car_insurance: { type: :HasOne, required: true },

  # BelongsToOne nested form
  car_owner: :BelongsToOne,

  # Number with formatting
  id: { type: :Number, padding: 10, prefix: :CK },
}
```

## Field Types Quick Reference

| Type | Class | Use Case |
|------|-------|----------|
| `:String` | `Krudmin::Fields::String` | Text input |
| `:Text` | `Krudmin::Fields::Text` | Textarea |
| `:Number` | `Krudmin::Fields::Number` | Integer/numeric input |
| `:Decimal` | `Krudmin::Fields::Decimal` | Decimal with formatting |
| `:Currency` | `Krudmin::Fields::Currency` | Currency display |
| `:Boolean` | `Krudmin::Fields::Boolean` | Checkbox with colored badges |
| `:Date` | `Krudmin::Fields::Date` | Date picker |
| `:DateTime` | `Krudmin::Fields::DateTime` | DateTime picker |
| `:Email` | `Krudmin::Fields::Email` | Email input |
| `:Password` | `Krudmin::Fields::Password` | Password input (masked) |
| `:Hidden` | `Krudmin::Fields::Hidden` | Hidden field |
| `:RichText` | `Krudmin::Fields::RichText` | Trix rich text editor |
| `:EnumType` | `Krudmin::Fields::EnumType` | Select from Rails enum |
| `:BelongsTo` | `Krudmin::Fields::BelongsTo` | Select dropdown for association |
| `:BelongsToOne` | `Krudmin::Fields::BelongsToOne` | Inline nested form for belongs_to |
| `:HasMany` | `Krudmin::Fields::HasMany` | Nested form collection (add/remove rows) |
| `:HasManyIds` | `Krudmin::Fields::HasManyIds` | Multi-select for many-to-many |
| `:HasOne` | `Krudmin::Fields::HasOne` | Inline nested form for has_one |

## Configuration (Krudmin::Config)

```ruby
# config/initializers/krudmin.rb
Krudmin::Config.with do |config|
  config.parent_controller = "ApplicationController"
  config.krudmin_root_path = :admin_root_path
  config.pundit_enabled = true
  config.layout = "krudmin/core_theme"
  config.theme = "krudmin/core_theme"
  config.form_wrapper = :horizontal_form
  config.modal_form_wrapper = :vertical_form
  config.paginator_position = :top
  config.edit_profile_path = "/admin/profile"
  config.logout_path = "/logout"
  config.require_authenticated_user_method = :authenticate_user!
  config.login_screen_intro_message = "Welcome to Admin"

  config.current_user_method { current_user }

  config.navigation_menu = -> {
    Krudmin::NavigationMenu.configure do |menu, user|
      menu.node label: "Cars", resource: "car", module_path: :admin, icon: :car
      menu.link label: "Dashboard", link: :root_path, icon: :dashboard
    end
  }
end
```

## Key Files to Read First

When onboarding to this project, read these files in order:

1. `lib/krudmin/resource_managers/base.rb` - Core concept, all constants
2. `lib/config.rb` - Global configuration
3. `app/controllers/krudmin/application_controller.rb` - Main controller
4. `app/controllers/concerns/krudmin/krudmin_resource_manager_controller_support.rb` - Resource lifecycle
5. `lib/krudmin/fields/base.rb` - Field system base
6. `lib/krudmin/fields/associated.rb` - Association fields base
7. `lib/krudmin/mutation_handlers/create_handler.rb` - CRUD handler pattern
8. `lib/krudmin/presenters/base_field_presenter.rb` - Rendering system
9. `spec/test_app/` - Real usage examples (CarsResourceManager is the most complete)

## Dependencies

- **bootstrap** (4.x) - CSS framework
- **nested-fields.js** - Custom vanilla JS for nested form management (has_many) — replaced Cocoon gem
- **devise** - Authentication
- **font-awesome-rails** - Icons
- **hamlit** - HAML template engine
- **jquery-rails** - jQuery integration
- **kaminari** - Pagination
- **momentjs-rails** - Date/time formatting
- **pundit** - Authorization
- **ransack** - Search/filtering
- **sassc-rails** - SASS compilation
- **simple_form** - Form builder
- **stimulus** - Stimulus controllers (vendored, v3.2.1)
- **trix** - Rich text editor (vendored, v2.1.15)
- **turbo-rails** - Hotwire Turbo integration

## Common Tasks for AI Agents

### Adding a new field type
Use the generator: `rails generate krudmin:field Phone --parent=String`
Then: add `require "krudmin/fields/phone"` in `lib/krudmin.rb` and optionally add mapping in `lib/krudmin/fields/inflector.rb`

### Adding a new action button
Use the generator: `rails generate krudmin:action generate_invoice`
Then: add `require` in `lib/krudmin.rb`, add to `LISTABLE_ACTIONS`, add route and controller method

### Modifying search behavior
- Search predicates: `lib/krudmin/search_form/search_phrases_support.rb`
- Search filters: `lib/krudmin/search_form/search_filter.rb`
- Calendar filters: `lib/krudmin/search_form/calendar_filter.rb`
- Main form: `lib/krudmin/search_form.rb`
- Cookie persistence: `app/controllers/concerns/krudmin/searchable.rb`

### Modifying CRUD behavior
- Handlers: `lib/krudmin/mutation_handlers/`
- Controller actions: `app/controllers/krudmin/application_controller.rb`
- Params parsing: `lib/krudmin/params_parser.rb`

## Test App Reference

The `spec/test_app/` directory contains a complete working example:
- `app/resource_managers/cars_resource_manager.rb` - Most complete ResourceManager example with grouped attributes, all field types, associations, and presentation metadata
- `app/models/car.rb` - Model with associations, enums, nested attributes
- `config/initializers/krudmin.rb` - Full configuration example
- `config/routes.rb` - Route setup with namespacing and member actions

## Generators

Krudmin provides six Rails generators. Full documentation: `docs/generators.md`

### Install Generator

```bash
rails generate krudmin:install
```

Installs into the host project:
- `config/initializers/krudmin.rb` — Configuration
- `CLAUDE.md` — AI agent instructions (tailored for host projects)
- `docs/krudmin/` — Full documentation copied from the gem
- `app/resource_managers/` — Empty directory

Flags: `--no-docs`, `--no-claude`, `--no-initializer`

Generator source: `lib/generators/krudmin/install/`

### Resource Generator

```bash
rails generate krudmin:resource Product name:string price:decimal active:boolean
```

Generates:
- `app/resource_managers/products_resource_manager.rb`
- `app/controllers/admin/products_controller.rb`
- `spec/resource_managers/products_resource_manager_spec.rb`
- `spec/controllers/admin/products_controller_spec.rb`
- Routes injected into `config/routes.rb`

Options:
- `--namespace=admin` (default) — Controller namespace
- `--policy` — Generate a Pundit policy
- `--remote` — Enable AJAX CRUD
- `--skip-routes` — Skip route injection
- `--skip-specs` — Skip spec generation

Generator source: `lib/generators/krudmin/resource/`

### Dashboard Generator

```bash
rails generate krudmin:dashboard Dashboard --namespace=admin
```

Generates a dashboard class and controller.

Generator source: `lib/generators/krudmin/dashboard/`

### Field Generator

```bash
rails generate krudmin:field Phone
rails generate krudmin:field Phone --parent=String
```

Scaffolds a custom field type: field class, presenter, view partials, and spec.

Options:
- `--parent=Base` (default) — Parent field class (e.g., String, Number)
- `--no-specs` — Skip spec generation

Generator source: `lib/generators/krudmin/field/`

### Action Generator

```bash
rails generate krudmin:action generate_invoice
```

Scaffolds a custom action button: button class, view partials, and spec.

Options:
- `--no-model-action` — Inherit from Base instead of ModelActionButton
- `--no-specs` — Skip spec generation

Generator source: `lib/generators/krudmin/action/`

### Theme Generator

```bash
rails generate krudmin:theme my_theme
```

Copies the entire `core_theme` directory for customization.

Generator source: `lib/generators/krudmin/theme/`

## Coding Conventions

- Views use **HAML** (not ERB)
- Forms use **simple_form**
- Templates are theme-aware: partials live under `app/views/krudmin/{theme}/`
- Constants in ResourceManagers follow SCREAMING_SNAKE_CASE
- Field types can be referenced as symbols (`:Number`) or full classes (`Krudmin::Fields::Number`)
- The engine uses `isolate_namespace Krudmin`
- I18n keys are under `krudmin.*` namespace in `config/locales/en.yml`
