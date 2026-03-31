# Resource Managers

Resource Managers are the core configuration objects in Krudmin. Each admin resource has a Resource Manager that defines how the model is presented, edited, searched, and displayed.

## Overview

A Resource Manager is a Ruby class that extends `Krudmin::ResourceManagers::Base`. It declares class constants that configure every aspect of the admin interface for a model.

```ruby
class ProductsResourceManager < Krudmin::ResourceManagers::Base
  MODEL_CLASSNAME = "Product"
  EDITABLE_ATTRIBUTES = [:name, :price, :description]
  LISTABLE_ATTRIBUTES = [:name, :price]
  # ... more constants
end
```

## Naming Convention

Krudmin infers the Resource Manager from the controller name:

| Controller | Resource Manager |
|------------|-----------------|
| `Admin::CarsController` | `CarsResourceManager` |
| `Admin::ProductsController` | `ProductsResourceManager` |
| `CarBrandsController` | `CarBrandsResourceManager` |

The inference is handled in `KrudminResourceManagerControllerSupport`. The controller path is analyzed to extract the resource name and look up the corresponding Resource Manager class.

## Constants Reference

### MODEL_CLASSNAME

**Type:** String
**Required:** Yes

The fully-qualified ActiveRecord model class name.

```ruby
MODEL_CLASSNAME = "Product"
MODEL_CLASSNAME = "Admin::Product"  # namespaced model
```

### EDITABLE_ATTRIBUTES

**Type:** Array or Hash
**Default:** `[]`

Fields available in create/edit forms. Can be a flat array or a hash for grouped sections.

```ruby
# Flat list
EDITABLE_ATTRIBUTES = [:name, :price, :description, :active]

# Grouped sections (renders as collapsible cards)
EDITABLE_ATTRIBUTES = {
  general: [:name, :description, :price],
  status: [:active, :featured],
  associations: [:category_id, :tags]
}
```

When using grouped attributes, combine with `PRESENTATION_METADATA` for labels and layout.

### LISTABLE_ATTRIBUTES

**Type:** Array
**Default:** `[]`

Columns shown in the index/list view table. These can include delegated attributes:

```ruby
LISTABLE_ATTRIBUTES = [:name, :price, :active, :car_brand_description, :created_at]
```

### SEARCHABLE_ATTRIBUTES

**Type:** Array
**Default:** `[]`

Fields that appear as search/filter inputs in the search form. Each field's type determines the search input and available operators.

```ruby
SEARCHABLE_ATTRIBUTES = [:name, :price, :active, :category_id, :created_at]
```

### DISPLAYABLE_ATTRIBUTES

**Type:** Array
**Default:** `[]` (falls back to `LISTABLE_ATTRIBUTES`)

Fields shown in the show/detail view.

```ruby
DISPLAYABLE_ATTRIBUTES = [:id, :name, :price, :description, :active, :created_at, :updated_at]
```

### LOOKUP_ATTRIBUTES

**Type:** Array
**Default:** `[]`

Fields used for lookup operations (e.g., when this resource is used as an association target).

### LISTABLE_ACTIONS

**Type:** Array
**Default:** `[:show, :edit, :destroy]`

Actions available per row in the list view. Each action renders a button.

```ruby
# Available actions:
LISTABLE_ACTIONS = [:show, :edit, :active, :destroy]
```

| Action | Button | Description |
|--------|--------|-------------|
| `:show` | Eye icon | View detail page |
| `:edit` | Pencil icon | Edit form |
| `:destroy` | Trash icon | Delete with confirmation |
| `:active` | Toggle icon | Activate/deactivate |

### ORDER_BY

**Type:** Array
**Default:** `[]`

Default sort order for the list view.

```ruby
ORDER_BY = [:year]                    # ASC by year
ORDER_BY = [created_at: :desc]        # DESC by created_at
ORDER_BY = [:name, created_at: :desc] # Multiple columns
```

### LISTABLE_INCLUDES

**Type:** Array
**Default:** `[]`

ActiveRecord `includes` to prevent N+1 queries in the list view.

```ruby
LISTABLE_INCLUDES = [:category, :brand]
```

### ATTRIBUTE_TYPES

**Type:** Hash
**Default:** `{}`

Override or configure field types for specific attributes. If an attribute is not listed here, its type is auto-detected from the ActiveRecord column type.

```ruby
ATTRIBUTE_TYPES = {
  # Symbol shorthand
  year: :Number,
  active: :Boolean,
  passengers: :HasMany,
  car_owner: :BelongsToOne,

  # Full options hash
  price: { type: :Currency, prefix: "$", decimals: 2 },
  description: { type: :RichText, show_length: 20 },
  model: { type: :Text, input: { rows: 2 } },
  id: { type: :Number, padding: 10, prefix: :CK },

  # Enum field
  transmission: { type: :EnumType, associated_options: -> { Car.transmissions } },

  # BelongsTo with full options
  car_brand_id: {
    type: :BelongsTo,
    collection_label_field: :description,
    association_path: :car_brand_path,
    add_path: :new_car_brand,
    edit_path: :edit_car_brand,
    remote: true
  },

  # HasOne (required nested form)
  car_insurance: { type: :HasOne, required: true },

  # DateTime with format
  created_at: { type: :DateTime, format: :short },
  release_date: { type: :Date, format: :short },
}
```

See [Field Types](/docs/fields.md) for all type options.

### RESOURCE_INSTANCE_LABEL_ATTRIBUTE

**Type:** Symbol
**Default:** `:id`

Which attribute to use as the display label for individual records. Used in dropdown options, confirmation dialogs, and breadcrumbs.

```ruby
RESOURCE_INSTANCE_LABEL_ATTRIBUTE = :name
```

### RESOURCE_LABEL / RESOURCES_LABEL

**Type:** String
**Default:** `""`

Human-readable singular and plural labels for the resource.

```ruby
RESOURCE_LABEL = "Car"
RESOURCES_LABEL = "Cars"
```

### PRESENTATION_METADATA

**Type:** Hash
**Default:** `{}`

Layout configuration for grouped `EDITABLE_ATTRIBUTES`. Each key matches a group name and specifies a label and CSS class.

```ruby
PRESENTATION_METADATA = {
  general: { label: "General Info", class: "col-lg-6 col-md-12" },
  activation: { label: "Activation", class: "col-lg-6 col-md-12" },
  passengers: { label: "Passengers", class: "col-md-12" },
  insurance: { label: "Insurance", class: "col-md-6" },
  owner: { label: "Owner", class: "col-md-6" }
}
```

CSS classes use Bootstrap grid system (col-lg-*, col-md-*, etc.).

### REMOTE_CRUD

**Type:** Boolean
**Default:** `false`

When `true`, form submissions use AJAX instead of full page reloads. Responses are rendered as JS templates.

### PAGINATOR_POSITION

**Type:** Symbol or nil
**Default:** `nil` (falls back to `Krudmin::Config.paginator_position`)

Where to show pagination controls. Options: `:top`, `:bottom`, `:top_and_bottom`.

## Overriding Methods

You can override any method in the Resource Manager:

### Custom Scope

```ruby
class ProductsResourceManager < Krudmin::ResourceManagers::Base
  # Only show published products
  def scope
    model_class.where(published: true)
  end
end
```

### Custom Items Query

```ruby
class ProductsResourceManager < Krudmin::ResourceManagers::Base
  private

  def list_scope
    scope.includes(:category).order(created_at: :desc).where(archived: false)
  end
end
```

### Custom Label

```ruby
class ProductsResourceManager < Krudmin::ResourceManagers::Base
  def model_label(given_model)
    "#{given_model.name} (#{given_model.sku})"
  end
end
```

## Complete Example

From the test app (`spec/test_app/app/resource_managers/cars_resource_manager.rb`):

```ruby
class CarsResourceManager < Krudmin::ResourceManagers::Base
  MODEL_CLASSNAME = "Car"

  EDITABLE_ATTRIBUTES = {
    general: [:active, :description, :created_at, :release_date],
    activation: [:model, :year, :car_brand_id, :transmission],
    passengers: [:passengers],
    insurance: [:car_insurance],
    owner: [:car_owner]
  }

  DISPLAYABLE_ATTRIBUTES = [:id, :model, :year, :description, :transmission,
                             :car_brand_id, :passengers, :created_at]
  SEARCHABLE_ATTRIBUTES = [:model, :year, :active, :car_brand_id, :transmission, :created_at]
  LISTABLE_ACTIONS = [:show, :edit, :active, :destroy]
  LISTABLE_ATTRIBUTES = [:model, :id, :car_brand_description, :year, :active,
                          :description, :created_at]
  LISTABLE_INCLUDES = [:car_brand]
  PAGINATOR_POSITION = :bottom
  REMOTE_CRUD = true
  ORDER_BY = [:year]

  RESOURCE_INSTANCE_LABEL_ATTRIBUTE = :model
  RESOURCE_LABEL = "Car"
  RESOURCES_LABEL = "Cars"

  PRESENTATION_METADATA = {
    general: { label: "General Info", class: "col-lg-6 col-md-12" },
    activation: { label: "Activation", class: "col-lg-6 col-md-12" },
    passengers: { label: "Passengers", class: "col-md-12" },
    insurance: { label: "Insurance", class: "col-md-6" },
    owner: { label: "Owner", class: "col-md-6" }
  }

  ATTRIBUTE_TYPES = {
    id: { type: :Number, padding: 10, prefix: :CK },
    model: { type: :Text, input: { rows: 2 } },
    description: { type: :RichText, show_length: 20 },
    year: :Number,
    active: { type: :Boolean, input: { label: 'Is Active' } },
    passengers: :HasMany,
    car_brand_id: {
      type: :BelongsTo,
      collection_label_field: :description,
      association_path: :car_brand_path,
      add_path: :new_car_brand,
      edit_path: :edit_car_brand,
      remote: true
    },
    created_at: { type: :DateTime, format: :short },
    release_date: { type: :Date, format: :short },
    transmission: { type: :EnumType, associated_options: -> { Car.transmissions } },
    car_insurance: { type: :HasOne, required: true },
    car_owner: :BelongsToOne
  }
end
```

## Internal Architecture

### AttributeCollection

The `AttributeCollection` class (at `lib/krudmin/resource_managers/attribute_collection.rb`) manages the full collection of field attributes. It:

- Processes `ATTRIBUTE_TYPES` into `Attribute` instances
- Flattens grouped `EDITABLE_ATTRIBUTES`
- Resolves field types from ActiveRecord schema for non-configured attributes
- Generates `permitted_attributes` for strong params (including nested)

### Attribute

The `Attribute` class (at `lib/krudmin/resource_managers/attribute.rb`) wraps a single field:

- `new_field(model)` — Creates a Field instance
- `parse_with_field(value)` — Transforms a param value through the field's parser
- `permitted_attribute` — Returns the attribute name(s) for strong params
- `from_inferred_type` — Auto-detects type from AR column info
- `from` — Builds from an ATTRIBUTE_TYPES metadata hash

### Routing

The `Routing` class (at `lib/krudmin/resource_managers/routing.rb`) generates URL helpers by introspecting Rails routes:

- `resource_root` — Index path
- `new_resource_path` — New form path
- `resource_path(model)` — Show path
- `edit_resource_path(model)` — Edit form path
- `activate_path(model)` / `deactivate_path(model)` — Status toggle paths
- `index_route?`, `edit_route?`, etc. — Check if route exists
