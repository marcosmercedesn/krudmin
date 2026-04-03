# Generators

Krudmin ships with Rails generators that scaffold common patterns: project setup, admin resources, dashboards, custom field types, custom action buttons, state machine workflows, and theme customization.

## Install Generator

Sets up Krudmin in a host Rails application.

```bash
rails generate krudmin:install
```

Creates:
- `config/initializers/krudmin.rb` — Configuration
- `CLAUDE.md` — AI agent instructions
- `docs/krudmin/` — Documentation
- `app/resource_managers/` — Empty directory

**Options:**

| Option | Default | Description |
|--------|---------|-------------|
| `--no-docs` | `true` | Skip documentation files |
| `--no-claude` | `true` | Skip CLAUDE.md |
| `--no-initializer` | `true` | Skip initializer |
| `--docs-only` | `false` | Only update docs/krudmin in the host project |

Refresh docs in an existing host app without touching initializer or CLAUDE.md:

```bash
rails generate krudmin:install --docs-only
```

## Resource Generator

Generates a complete admin resource: ResourceManager, controller, routes, specs, and optional Pundit policy.

```bash
rails generate krudmin:resource Product name:string price:decimal active:boolean
```

Creates:
- `app/resource_managers/products_resource_manager.rb`
- `app/controllers/admin/products_controller.rb`
- `spec/resource_managers/products_resource_manager_spec.rb`
- `spec/controllers/admin/products_controller_spec.rb`
- Routes injected into `config/routes.rb`

**Options:**

| Option | Default | Description |
|--------|---------|-------------|
| `--namespace` | `admin` | Controller namespace |
| `--policy` | `false` | Generate a Pundit policy |
| `--remote` | `false` | Enable AJAX CRUD (`REMOTE_CRUD = true`) |
| `--skip-routes` | `false` | Skip route injection |
| `--skip-specs` | `false` | Skip RSpec spec generation |

### Field Type Mapping

When you specify `field:type` arguments, the generator maps database types to Krudmin field types in `ATTRIBUTE_TYPES`:

| Argument Type | Krudmin Field |
|--------------|---------------|
| `string` | Auto-detected (no entry) |
| `text` | `:Text` |
| `integer`, `number` | `:Number` |
| `decimal` | `:Decimal` |
| `float` | `:Number` |
| `boolean` | `:Boolean` |
| `date` | `:Date` |
| `datetime` | `:DateTime` |
| `email` | `:Email` |
| `currency` | `:Currency` |
| `rich_text` | `:RichText` |
| `file`, `image` | `:File` |
| `json`, `jsonb` | `:Json` |

### Examples

Basic resource:

```bash
rails generate krudmin:resource Product name:string price:decimal active:boolean
```

With Pundit policy and AJAX:

```bash
rails generate krudmin:resource Order total:currency status:string --policy --remote
```

Without namespace:

```bash
rails generate krudmin:resource Product name:string --namespace=
```

Skip route injection (for manual route setup):

```bash
rails generate krudmin:resource Product name:string --skip-routes
```

### Route Injection

The generator automatically injects routes into `config/routes.rb`:

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

If you already have a `namespace :admin` block, the generator creates a second one. Merge them manually after generation. Use `--skip-routes` to handle routes yourself.

### After Generation

Add the resource to your navigation menu in `config/initializers/krudmin.rb`:

```ruby
menu.node label: "Products", resource: "product", module_path: :admin, icon: :list
```

## Dashboard Generator

Generates a dashboard class and controller.

```bash
rails generate krudmin:dashboard Dashboard
rails generate krudmin:dashboard Dashboard --namespace=admin
```

Creates:
- `app/dashboards/admin_dashboard.rb`
- `app/controllers/admin/dashboard_controller.rb`

See [Dashboards](dashboard.md) for widget configuration.

## Field Generator

Scaffolds a custom field type with field class, presenter, view partials, and spec.

```bash
rails generate krudmin:field Phone
```

Creates:
- `lib/krudmin/fields/phone.rb` — Field class
- `lib/krudmin/presenters/phone_field_presenter.rb` — Presenter class
- `app/views/krudmin/core_theme/fields/phone/_form_field.html.haml` — Form partial
- `app/views/krudmin/core_theme/fields/phone/_search.html.haml` — Search partial
- `spec/lib/krudmin/fields/phone_spec.rb` — RSpec spec

**Options:**

| Option | Default | Description |
|--------|---------|-------------|
| `--parent` | `Base` | Parent field class to inherit from |
| `--no-specs` | `false` | Skip spec generation |

### Choosing a Parent Class

Use `--parent` to inherit behavior from an existing field type:

```bash
# Inherit from Base (default) — a blank slate
rails generate krudmin:field Phone

# Inherit from String — gets string search predicates and text input
rails generate krudmin:field Phone --parent=String

# Inherit from Number — gets numeric formatting and right-alignment
rails generate krudmin:field Rating --parent=Number
```

The field class hierarchy is documented in [Field Types](fields.md).

### After Generation

Register the field in `lib/krudmin.rb`:

```ruby
require "krudmin/fields/phone"
```

Then use it in a ResourceManager:

```ruby
ATTRIBUTE_TYPES = {
  phone_number: :Phone
}
```

### Extending the Generated Field

The generated field class is a starting point. Override methods to customize behavior:

```ruby
# lib/krudmin/fields/phone.rb
require_relative "../presenters/phone_field_presenter"

module Krudmin
  module Fields
    class Phone < String
      PRESENTER = Krudmin::Presenters::PhoneFieldPresenter

      SEARCH_PREDICATES = [:cont, :eq, :start, :end]

      def parse(value)
        # Strip non-numeric characters before saving
        value.to_s.gsub(/[^0-9+]/, "") if value.present?
      end
    end
  end
end
```

Customize the presenter for display formatting:

```ruby
# lib/krudmin/presenters/phone_field_presenter.rb
module Krudmin
  module Presenters
    class PhoneFieldPresenter < BaseFieldPresenter
      def render_list
        format_phone(field.data)
      end

      private

      def format_phone(number)
        return "" if number.blank?
        digits = number.to_s.gsub(/\D/, "")
        "(#{digits[0..2]}) #{digits[3..5]}-#{digits[6..]}"
      end
    end
  end
end
```

Customize the form partial for input masking or custom widgets:

```haml
-# app/views/krudmin/core_theme/fields/phone/_form_field.html.haml
= form.input(attribute, { as: :string, input_html: { placeholder: "(555) 123-4567" } }.merge(input_options))
```

### Adding to the Inflector

If your field type should auto-detect from an ActiveRecord column type, add a mapping in `lib/krudmin/fields/inflector.rb`:

```ruby
def field_from_active_record(type)
  case type
  # ... existing mappings ...
  when :phone then Krudmin::Fields::Phone
  end
end
```

## Action Generator

Scaffolds a custom action button with button class, view partials, and spec.

```bash
rails generate krudmin:action generate_invoice
```

Creates:
- `lib/krudmin/action_buttons/generate_invoice_button.rb` — Button class
- `app/views/krudmin/core_theme/action_buttons/generate_invoice_button/_list.html.haml` — List row button
- `app/views/krudmin/core_theme/action_buttons/generate_invoice_button/_form.html.haml` — Form toolbar button
- `spec/lib/krudmin/action_buttons/generate_invoice_button_spec.rb` — RSpec spec

**Options:**

| Option | Default | Description |
|--------|---------|-------------|
| `--no-model-action` | `false` | Inherit from `Base` instead of `ModelActionButton` |
| `--no-specs` | `false` | Skip spec generation |

### ModelActionButton vs Base

By default, the generator creates a `ModelActionButton` subclass, which receives the model instance and provides `model_label`. Use `--no-model-action` for buttons that don't operate on a specific record (e.g., collection-level actions):

```bash
# Per-record action (default) — gets model context
rails generate krudmin:action generate_invoice

# Collection-level action — no model context
rails generate krudmin:action export_csv --no-model-action
```

### After Generation

Three steps to wire up a custom action:

**1. Register the button** in `lib/krudmin.rb`:

```ruby
require "krudmin/action_buttons/generate_invoice_button"
```

**2. Add to LISTABLE_ACTIONS** in the ResourceManager:

```ruby
class OrdersResourceManager < Krudmin::ResourceManagers::Base
  LISTABLE_ACTIONS = [:show, :edit, :generate_invoice, :active, :destroy]
end
```

**3. Add route and controller method:**

```ruby
# config/routes.rb
namespace :admin do
  resources :orders do
    member do
      post :generate_invoice
    end
  end
end
```

```ruby
# app/controllers/admin/orders_controller.rb
class Admin::OrdersController < Krudmin::ApplicationController
  def generate_invoice
    order = resource_manager.find(params[:id])
    InvoiceService.generate(order)
    redirect_to resource_root, notice: "Invoice generated for #{order.number}"
  end
end
```

### Customizing the Button

The generated button class and partials are starting points. Common customizations:

```ruby
# lib/krudmin/action_buttons/generate_invoice_button.rb
module Krudmin
  module ActionButtons
    class GenerateInvoiceButton < ModelActionButton
      def tooltip_title
        I18n.t("krudmin.tooltip.generate_invoice", label: model_label)
      end

      # Only show the button when the model meets a condition
      def visible?
        model.status == "approved"
      end
    end
  end
end
```

Customize the list partial for specific styling:

```haml
-# action_buttons/generate_invoice_button/_list.html.haml
%li.list-inline-item
  = link_to(action_path, { data: { turbo_method: :post, turbo_confirm: "Generate invoice?" }, class: "btn btn-outline-success" }.merge(html_options)) do
    %i.bi.bi-file-text
```

## State Machine Generator

Scaffolds an AASM workflow concern for a model and provides Krudmin integration guidance.

```bash
rails generate krudmin:state_machine Order
```

Creates:
- `app/models/concerns/order_workflow.rb` — AASM workflow concern
- `spec/models/concerns/order_workflow_spec.rb` — concern spec (unless `--no-specs`)

**Options:**

| Option | Default | Description |
|--------|---------|-------------|
| `--attribute` | `status` | Column used by AASM |
| `--no-specs` | `false` | Skip spec generation |

Examples:

```bash
rails generate krudmin:state_machine Order
rails generate krudmin:state_machine Lead --attribute=stage
```

After generation:

1. Include concern in the model.
2. Add `post :transition` member route.
3. Configure `ATTRIBUTE_TYPES` with `type: :StateMachine` in the ResourceManager.

## Theme Generator

Copies the entire `core_theme` for customization. Use this when you need full control over the admin UI appearance.

```bash
rails generate krudmin:theme my_theme
```

Creates:
- `app/views/krudmin/my_theme/` — Full copy of all core_theme views, partials, field templates, action buttons, dashboard widgets, and layouts

### After Generation

Update your Krudmin configuration:

```ruby
# config/initializers/krudmin.rb
Krudmin::Config.with do |config|
  config.theme = "krudmin/my_theme"
  config.layout = "krudmin/my_theme"
end
```

### When to Use the Theme Generator

The theme generator copies **all** view files. This gives full control but means you are responsible for keeping your theme in sync with Krudmin updates.

For smaller customizations, consider overriding individual partials instead — just copy the specific file you want to change into the same path under your `app/views/` directory. Rails will use your application's version over the engine's. See [Views and Themes](views_and_themes.md) for details.

## Generator Summary

| Generator | Command | Creates |
|-----------|---------|---------|
| Install | `krudmin:install` | Initializer, docs, CLAUDE.md |
| Resource | `krudmin:resource NAME field:type...` | ResourceManager, controller, routes, specs |
| Dashboard | `krudmin:dashboard NAME` | Dashboard class, controller |
| Field | `krudmin:field NAME` | Field class, presenter, partials, spec |
| Action | `krudmin:action NAME` | Button class, partials, spec |
| State Machine | `krudmin:state_machine NAME` | AASM workflow concern, optional spec |
| Theme | `krudmin:theme NAME` | Full theme directory copy |
