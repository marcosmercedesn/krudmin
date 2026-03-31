[![CircleCI](https://img.shields.io/circleci/project/markmercedes/krudmin.svg)](https://circleci.com/gh/markmercedes/krudmin/tree/master)
[![Code Climate](https://codeclimate.com/github/markmercedes/krudmin/badges/gpa.svg)](https://codeclimate.com/github/markmercedes/krudmin)
[![Test Coverage](https://d3s6mut3hikguw.cloudfront.net/github/markmercedes/krudmin/badges/coverage.svg)](http://codeclimate.com/github/markmercedes/krudmin/badges/)
[![codebeat badge](https://codebeat.co/badges/e619cc8c-3212-4fa7-b75c-2fe266e1305b)](https://codebeat.co/projects/github-com-markmercedes-krudmin-master)

# Krudmin

A Rails Engine that provides powerful, convention-based admin panel generation with CRUD operations, search/filtering, authorization, and status toggling — all with minimal configuration and no custom DSL.

## What is Krudmin?

Krudmin generates fully-featured admin interfaces for your Rails models. Out of the box you get:

- **CRUD operations** with form validation and error handling
- **Search and filtering** powered by Ransack with persistent filters
- **Authorization** via Pundit policies
- **Status toggling** (activate/deactivate) for soft-delete patterns
- **Nested forms** for has_many, has_one, and belongs_to associations
- **Rich text editing** via Summernote
- **AJAX forms** with Turbolinks for smooth, SPA-like UX
- **Responsive UI** built on Bootstrap 4 with CoreUI theme
- **Configurable navigation** with icon support and visibility controls

### Philosophy

- **No custom DSL** — uses standard Ruby classes, Rails conventions, and familiar gems
- **Convention over configuration** — controller names map to resource managers automatically
- **Decoupled and maintainable** — concerns, presenters, and service objects keep code organized
- **Enhanced UX** — Turbolinks, SweetAlert confirmations, Select2 dropdowns, date pickers

### Similar Projects

- [Administrate](https://github.com/thoughtbot/administrate)
- [Rails Admin](https://github.com/sferik/rails_admin)
- [Active Admin](https://github.com/activeadmin/activeadmin)

## Installation

Add to your Gemfile:

```ruby
gem 'krudmin', github: 'markmercedes/krudmin'
```

Or install a specific version:

```ruby
gem 'krudmin', github: 'markmercedes/krudmin', tag: '0.1.7.9.5.31'
```

Then run:

```bash
bundle install
```

## Quick Start

### 1. Configure Krudmin

Create an initializer at `config/initializers/krudmin.rb`:

```ruby
Krudmin::Config.with do |config|
  config.parent_controller = "ApplicationController"
  config.krudmin_root_path = :admin_root_path
  config.layout = "krudmin/core_theme"
  config.form_wrapper = :horizontal_form
  config.modal_form_wrapper = :vertical_form
  config.require_authenticated_user_method = :authenticate_user!

  config.current_user_method { current_user }

  config.navigation_menu = -> {
    Krudmin::NavigationMenu.configure do |menu, user|
      menu.node label: "Products", resource: "product", module_path: :admin, icon: :box
    end
  }
end
```

### 2. Create a Resource Manager

```ruby
# app/resource_managers/products_resource_manager.rb
class ProductsResourceManager < Krudmin::ResourceManagers::Base
  MODEL_CLASSNAME = "Product"

  EDITABLE_ATTRIBUTES = [:name, :price, :description, :active]
  LISTABLE_ATTRIBUTES = [:name, :price, :active]
  SEARCHABLE_ATTRIBUTES = [:name, :price]
  LISTABLE_ACTIONS = [:show, :edit, :active, :destroy]

  RESOURCE_INSTANCE_LABEL_ATTRIBUTE = :name

  ATTRIBUTE_TYPES = {
    price: :Currency,
    active: :Boolean,
    description: :RichText
  }
end
```

### 3. Create the Controller

```ruby
# app/controllers/admin/products_controller.rb
class Admin::ProductsController < Krudmin::ApplicationController
end
```

That's it. The controller inherits all CRUD actions from Krudmin.

### 4. Add Routes

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

### 5. Add Navigation

In your Krudmin initializer, add a menu entry:

```ruby
config.navigation_menu = -> {
  Krudmin::NavigationMenu.configure do |menu, user|
    menu.node label: "Products", resource: "product", module_path: :admin, icon: :box
  end
}
```

## Resource Manager Configuration

The Resource Manager is the core of Krudmin. It defines how a model is presented in the admin panel.

### Key Constants

| Constant | Description |
|----------|-------------|
| `MODEL_CLASSNAME` | ActiveRecord model class name (string) |
| `EDITABLE_ATTRIBUTES` | Fields in forms. Array or Hash (for grouped sections) |
| `LISTABLE_ATTRIBUTES` | Columns in the list/index view |
| `SEARCHABLE_ATTRIBUTES` | Fields available as search filters |
| `DISPLAYABLE_ATTRIBUTES` | Fields in the show/detail view |
| `LISTABLE_ACTIONS` | Per-row actions: `:show`, `:edit`, `:destroy`, `:active` |
| `ATTRIBUTE_TYPES` | Field type overrides and options |
| `ORDER_BY` | Default sort order |
| `REMOTE_CRUD` | Enable AJAX forms (`true`/`false`) |

### Grouped Form Sections

Use a Hash for `EDITABLE_ATTRIBUTES` to organize fields into collapsible sections:

```ruby
EDITABLE_ATTRIBUTES = {
  general: [:name, :description, :price],
  status: [:active, :featured],
  associations: [:category_id, :tags]
}

PRESENTATION_METADATA = {
  general: { label: "General Info", class: "col-lg-6 col-md-12" },
  status: { label: "Status", class: "col-lg-6 col-md-12" },
  associations: { label: "Relationships", class: "col-md-12" }
}
```

## Field Types

Krudmin includes 18+ field types. Types are auto-detected from ActiveRecord columns, or can be overridden in `ATTRIBUTE_TYPES`:

| Type | Description |
|------|-------------|
| `String` | Text input |
| `Text` | Textarea |
| `Number` | Numeric input with optional formatting (padding, prefix) |
| `Decimal` | Decimal with thousands delimiter |
| `Currency` | Currency-formatted number |
| `Boolean` | Checkbox with colored Active/Inactive badges |
| `Date` | Date picker with range search support |
| `DateTime` | DateTime picker |
| `Email` | Email input |
| `Password` | Masked password input |
| `Hidden` | Hidden field (no display in list/show) |
| `RichText` | Summernote WYSIWYG editor |
| `EnumType` | Select from Rails enum values |
| `BelongsTo` | Dropdown for association (supports remote search) |
| `BelongsToOne` | Inline nested form for belongs_to |
| `HasMany` | Nested form collection with add/remove (via Cocoon) |
| `HasManyIds` | Multi-select for many-to-many |
| `HasOne` | Inline nested form for has_one |

### ATTRIBUTE_TYPES Examples

```ruby
ATTRIBUTE_TYPES = {
  year: :Number,                                    # Simple type
  price: { type: :Currency, prefix: "$" },          # With options
  active: { type: :Boolean, input: { label: "Active?" } },
  role: { type: :EnumType, associated_options: -> { User.roles } },
  category_id: { type: :BelongsTo, collection_label_field: :name, remote: true },
  items: :HasMany,
  address: { type: :HasOne, required: true },
}
```

## Authorization

Enable Pundit-based authorization:

```ruby
Krudmin::Config.with do |config|
  config.pundit_enabled = true
end
```

Create policies per model:

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

## Documentation

- [Getting Started](/docs/getting_started.md) - Step-by-step setup guide
- [Architecture](/docs/architecture.md) - System design and component overview
- [Resource Managers](/docs/resource_managers.md) - Complete resource manager reference
- [Field Types](/docs/fields.md) - All field types with options and examples
- [Configuration](/docs/configuration.md) - Full configuration reference
- [Search & Filtering](/docs/search_and_filtering.md) - Search system documentation
- [Authorization](/docs/authorization.md) - Pundit integration guide
- [Navigation Menu](/docs/navigation_menu.md) - Menu configuration
- [Views & Themes](/docs/views_and_themes.md) - UI customization
- [Contributing](/docs/contributing.md) - Development setup and contribution guide

## Contributing

See [contributing.md](/docs/contributing.md).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
