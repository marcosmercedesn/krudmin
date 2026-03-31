# Krudmin - AI Agent Instructions

This project uses [Krudmin](https://github.com/markmercedes/krudmin), a Rails Engine for admin dashboard generation.

## How Krudmin Works

Krudmin generates admin CRUD interfaces from **Resource Managers** — Ruby classes that define how a model appears in the admin panel. Controllers inherit from `Krudmin::ApplicationController` and get all actions for free.

### Core Pattern

```
Controller (empty, inherits CRUD) → Resource Manager (configuration) → Model (ActiveRecord)
```

### Key Files in This Project

- `config/initializers/krudmin.rb` — Global configuration (theme, auth, navigation)
- `app/resource_managers/` — One per admin resource, defines fields, types, actions
- `app/controllers/admin/` — Controllers inheriting from `Krudmin::ApplicationController`
- `app/policies/` — Pundit policies (if authorization is enabled)
- `docs/krudmin/` — Full documentation (if installed)

## Creating a New Admin Resource

### 1. Create the Resource Manager

```ruby
# app/resource_managers/products_resource_manager.rb
class ProductsResourceManager < Krudmin::ResourceManagers::Base
  MODEL_CLASSNAME = "Product"

  EDITABLE_ATTRIBUTES = [:name, :price, :description, :active]
  LISTABLE_ATTRIBUTES = [:name, :price, :active]
  SEARCHABLE_ATTRIBUTES = [:name, :price, :active]
  LISTABLE_ACTIONS = [:show, :edit, :active, :destroy]

  RESOURCE_INSTANCE_LABEL_ATTRIBUTE = :name

  ATTRIBUTE_TYPES = {
    price: :Currency,
    active: :Boolean,
    description: :RichText
  }
end
```

Or use the generator: `rails generate krudmin:resource Product name:string price:decimal active:boolean`

### 2. Create the Controller

```ruby
# app/controllers/admin/products_controller.rb
class Admin::ProductsController < Krudmin::ApplicationController
end
```

### 3. Add Routes

```ruby
namespace :admin do
  resources :products do
    member do
      post :activate
      post :deactivate
    end
  end
end
```

### 4. Add to Navigation Menu (in `config/initializers/krudmin.rb`)

```ruby
menu.node label: "Products", resource: "product", module_path: :admin, icon: :box
```

## Resource Manager Constants

| Constant | Purpose |
|----------|---------|
| `MODEL_CLASSNAME` | ActiveRecord model class (string) |
| `EDITABLE_ATTRIBUTES` | Form fields. Array or Hash (grouped sections) |
| `LISTABLE_ATTRIBUTES` | Index/list columns |
| `SEARCHABLE_ATTRIBUTES` | Search filter fields |
| `DISPLAYABLE_ATTRIBUTES` | Show view fields |
| `LISTABLE_ACTIONS` | Per-row actions: `:show`, `:edit`, `:destroy`, `:active` |
| `ATTRIBUTE_TYPES` | Field type overrides (see below) |
| `ORDER_BY` | Default sort |
| `LISTABLE_INCLUDES` | Eager-load associations |
| `REMOTE_CRUD` | Enable AJAX forms (`true`/`false`) |
| `RESOURCE_INSTANCE_LABEL_ATTRIBUTE` | Display label attribute (default: `:id`) |
| `RESOURCE_LABEL` / `RESOURCES_LABEL` | Singular/plural labels |
| `PRESENTATION_METADATA` | Form group layout (labels + CSS classes) |

## ATTRIBUTE_TYPES

```ruby
ATTRIBUTE_TYPES = {
  year: :Number,                                              # Simple
  price: { type: :Currency, prefix: "$" },                    # With options
  active: { type: :Boolean, input: { label: "Active?" } },    # With SimpleForm options
  role: { type: :EnumType, associated_options: -> { User.roles } },
  category_id: { type: :BelongsTo, collection_label_field: :name, remote: true },
  items: :HasMany,                                            # Nested forms (needs accepts_nested_attributes_for)
  address: { type: :HasOne, required: true },
  car_owner: :BelongsToOne,                                   # Inline belongs_to form
  description: { type: :RichText, show_length: 20 },
  created_at: { type: :DateTime, format: :short },
}
```

## Field Types

| Type | Use Case |
|------|----------|
| `:String` | Text input |
| `:Text` | Textarea |
| `:Number` | Numeric (options: `padding`, `prefix`) |
| `:Decimal` | Decimal with formatting |
| `:Currency` | Currency display |
| `:Boolean` | Checkbox + colored badges |
| `:Date` | Date picker (range search) |
| `:DateTime` | DateTime picker |
| `:Email` | Email input |
| `:Password` | Masked input |
| `:Hidden` | Hidden field |
| `:RichText` | Summernote WYSIWYG |
| `:EnumType` | Select from Rails enum |
| `:BelongsTo` | Dropdown for association |
| `:BelongsToOne` | Inline nested form (belongs_to) |
| `:HasMany` | Nested form collection (cocoon) |
| `:HasManyIds` | Multi-select for many-to-many |
| `:HasOne` | Inline nested form (has_one) |

## Grouped Form Sections

```ruby
EDITABLE_ATTRIBUTES = {
  general: [:name, :description],
  pricing: [:price, :discount]
}

PRESENTATION_METADATA = {
  general: { label: "General Info", class: "col-lg-6 col-md-12" },
  pricing: { label: "Pricing", class: "col-lg-6 col-md-12" }
}
```

## Authorization (Pundit)

When `config.pundit_enabled = true`, create policies:

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

## Full Documentation

See `docs/krudmin/` for detailed guides on architecture, fields, search, themes, and more.
