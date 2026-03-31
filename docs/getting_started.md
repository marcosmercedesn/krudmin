# Getting Started with Krudmin

This guide walks you through setting up Krudmin in an existing Rails application.

## Prerequisites

- Ruby 3.x+
- Rails 5.1+
- A Rails application with at least one ActiveRecord model

## Installation

### 1. Add the Gem

Add Krudmin to your `Gemfile`:

```ruby
gem 'krudmin', github: 'markmercedes/krudmin'
```

Run:

```bash
bundle install
```

### 2. Add Asset Dependencies

Krudmin uses Bootstrap 4, jQuery, and several JavaScript libraries. Ensure your application's asset pipeline includes them.

In your `app/assets/javascripts/application.js`:

```javascript
//= require krudmin/core_theme/application
```

In your `app/assets/stylesheets/application.scss`:

```scss
@import "krudmin/core_theme/application";
```

### 3. Configure SimpleForm for Bootstrap

Krudmin uses SimpleForm with Bootstrap wrappers. If you don't already have SimpleForm configured, the engine includes a Bootstrap 4 configuration at `config/initializers/simple_form_bootstrap.rb`. You may need to run:

```bash
rails generate simple_form:install --bootstrap
```

### 4. Create the Initializer

Create `config/initializers/krudmin.rb`:

```ruby
Krudmin::Config.with do |config|
  # The parent controller class for all Krudmin controllers
  config.parent_controller = "ApplicationController"

  # Root path for the admin panel
  config.krudmin_root_path = :admin_root_path

  # Theme and layout
  config.layout = "krudmin/core_theme"
  config.theme = "krudmin/core_theme"

  # Form wrappers (from SimpleForm Bootstrap config)
  config.form_wrapper = :horizontal_form
  config.modal_form_wrapper = :vertical_form

  # Authentication (uses Devise or any before_action method)
  config.require_authenticated_user_method = :authenticate_user!

  # Current user accessor
  config.current_user_method { current_user }

  # Profile/logout paths
  config.edit_profile_path = "/admin/profile"
  config.logout_path = "/users/sign_out"

  # Pagination position: :top, :bottom, or :top_and_bottom
  config.paginator_position = :top

  # Navigation menu
  config.navigation_menu = -> {
    Krudmin::NavigationMenu.configure do |menu, user|
      # Add menu items here (see Navigation Menu docs)
    end
  }
end
```

## Adding Your First Resource

Let's say you have a `Product` model:

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  validates :name, presence: true
  validates :price, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  def activate!
    update(active: true)
  end

  def deactivate!
    update(active: false)
  end
end
```

### Step 1: Create the Resource Manager

Resource Managers are the core configuration objects. Create one in `app/resource_managers/`:

```ruby
# app/resource_managers/products_resource_manager.rb
class ProductsResourceManager < Krudmin::ResourceManagers::Base
  MODEL_CLASSNAME = "Product"

  # Fields shown in the list/index view
  LISTABLE_ATTRIBUTES = [:name, :price, :active, :created_at]

  # Fields available in the create/edit form
  EDITABLE_ATTRIBUTES = [:name, :price, :description, :active]

  # Fields available as search/filter inputs
  SEARCHABLE_ATTRIBUTES = [:name, :price, :active]

  # Fields shown in the show/detail view
  DISPLAYABLE_ATTRIBUTES = [:name, :price, :description, :active, :created_at, :updated_at]

  # Actions available per row in the list view
  LISTABLE_ACTIONS = [:show, :edit, :active, :destroy]

  # Which attribute to use as the display label
  RESOURCE_INSTANCE_LABEL_ATTRIBUTE = :name

  # Human-readable labels
  RESOURCE_LABEL = "Product"
  RESOURCES_LABEL = "Products"

  # Default sort order
  ORDER_BY = [created_at: :desc]

  # Enable AJAX-based CRUD (optional)
  REMOTE_CRUD = true

  # Override field types (auto-detected from DB columns by default)
  ATTRIBUTE_TYPES = {
    price: :Currency,
    active: :Boolean,
    description: :RichText
  }
end
```

### Step 2: Create the Controller

The controller can be completely empty — it inherits everything from `Krudmin::ApplicationController`:

```ruby
# app/controllers/admin/products_controller.rb
class Admin::ProductsController < Krudmin::ApplicationController
end
```

### Step 3: Add Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :admin do
    root to: "products#index"

    resources :products do
      member do
        post :activate
        post :deactivate
      end
    end
  end
end
```

### Step 4: Add to Navigation Menu

Update your initializer's navigation menu:

```ruby
config.navigation_menu = -> {
  Krudmin::NavigationMenu.configure do |menu, user|
    menu.node label: "Products", resource: "product", module_path: :admin, icon: :box
  end
}
```

### Step 5: Visit Your Admin Panel

Start your Rails server and navigate to `/admin/products`. You should see a fully functional admin interface with:

- A list of products with sortable columns
- Search/filter form
- Create, edit, show, and delete actions
- Activate/deactivate toggle

## Adding Associations

### BelongsTo (Dropdown Select)

If `Product` belongs to `Category`:

```ruby
# In your model
class Product < ApplicationRecord
  belongs_to :category
end

# In your resource manager
EDITABLE_ATTRIBUTES = [:name, :price, :category_id, :active]

ATTRIBUTE_TYPES = {
  category_id: {
    type: :BelongsTo,
    collection_label_field: :name,  # Which field to show in dropdown
    remote: true                     # Enable AJAX search for large collections
  }
}
```

### HasMany (Nested Forms)

If `Product` has many `Variants`:

```ruby
# In your model
class Product < ApplicationRecord
  has_many :variants
  accepts_nested_attributes_for :variants, allow_destroy: true
end

# Create a resource manager for the nested resource
# app/resource_managers/variants_resource_manager.rb
class VariantsResourceManager < Krudmin::ResourceManagers::Base
  MODEL_CLASSNAME = "Variant"
  EDITABLE_ATTRIBUTES = [:size, :color, :sku]
  ATTRIBUTE_TYPES = {}
end

# In the parent resource manager
EDITABLE_ATTRIBUTES = [:name, :price, :variants]

ATTRIBUTE_TYPES = {
  variants: :HasMany
}
```

### HasOne (Inline Nested Form)

If `Product` has one `Detail`:

```ruby
# In your model
class Product < ApplicationRecord
  has_one :detail
  accepts_nested_attributes_for :detail
end

# In your resource manager
EDITABLE_ATTRIBUTES = [:name, :price, :detail]

ATTRIBUTE_TYPES = {
  detail: { type: :HasOne, required: true }
}
```

## Grouped Form Sections

Organize your edit forms into visual groups:

```ruby
EDITABLE_ATTRIBUTES = {
  general: [:name, :description, :price],
  status: [:active, :featured],
  media: [:image_url, :video_url]
}

PRESENTATION_METADATA = {
  general: { label: "General Information", class: "col-lg-6 col-md-12" },
  status: { label: "Status & Visibility", class: "col-lg-6 col-md-12" },
  media: { label: "Media", class: "col-md-12" }
}
```

## Enabling Authorization

To restrict access based on user roles:

```ruby
# In your initializer
Krudmin::Config.with do |config|
  config.pundit_enabled = true
end

# Create a policy
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

## Custom Controllers

For admin pages that aren't standard CRUD, extend `Krudmin::CustomController`:

```ruby
# app/controllers/admin/dashboard_controller.rb
class Admin::DashboardController < Krudmin::CustomController
  def index
    @total_products = Product.count
    @recent_orders = Order.recent.limit(10)
  end
end
```

## Next Steps

- [Resource Managers](/docs/resource_managers.md) - Deep dive into all configuration options
- [Field Types](/docs/fields.md) - Complete reference for all 18+ field types
- [Configuration](/docs/configuration.md) - Full configuration options
- [Search & Filtering](/docs/search_and_filtering.md) - Search system customization
- [Authorization](/docs/authorization.md) - Pundit policy details
- [Navigation Menu](/docs/navigation_menu.md) - Menu configuration
- [Views & Themes](/docs/views_and_themes.md) - UI customization
