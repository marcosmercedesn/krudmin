# Dashboards

Krudmin includes a ResourceManager-backed dashboard system for building admin home pages and KPI screens without bypassing the authorization and scoping rules already defined by your resources.

## Why dashboards are ResourceManager-backed

Widgets use ResourceManagers instead of querying models directly. This keeps dashboards aligned with the rest of Krudmin:

- index permissions are respected
- `policy_scope` stays in the query path when Pundit is enabled
- resource-specific scopes and display rules stay close to the resource definition
- dashboards do not become a second, less secure data access layer

The flow is:

```text
Widget -> ResourceManager.scope -> policy_scope -> dashboard scope -> widget rendering
```

## Dashboard Class

Create a dashboard class under `app/dashboards/`:

```ruby
class AdminDashboard < Krudmin::Dashboard
  page_title "Operations Dashboard"
  page_description "A summary of the most important operational metrics."

  toolbar do |b|
    b.link :admin_orders_path, label: "Orders", icon: :shopping_cart
    b.link :admin_customers_path, label: "Customers", icon: :users
  end

  widget :count,
         resource: OrdersResourceManager,
         label: "Orders Today",
         scope: :today,
         icon: :shopping_bag,
         path: :admin_orders_path

  widget :chart,
         resource: OrdersResourceManager,
         label: "Orders by Month",
         group_by: :created_at,
         period: :month,
         path: :admin_orders_path

  widget :table,
         resource: OrdersResourceManager,
         label: "Recent Orders",
         scope: :recent,
         columns: :dashboard_summary,
         limit: 10,
         path: :admin_orders_path

  widget :list,
         resource: CustomersResourceManager,
         label: "Newest Customers",
         scope: :recent,
         secondary_attribute: :created_at,
         path: :admin_customers_path
end
```

## Controller

Create a controller that inherits from `Krudmin::DashboardController`:

```ruby
class Admin::DashboardController < Krudmin::DashboardController
end
```

By convention, `Admin::DashboardController` resolves `AdminDashboard`.

## Routes

Typical routing setup:

```ruby
namespace :admin do
  get :dashboard, to: "dashboard#show"
  root to: "dashboard#show"
end
```

## Supported Widgets

### Count

Displays the total number of records in the authorized relation.

```ruby
widget :count,
       resource: OrdersResourceManager,
       scope: :today,
       label: "Orders Today",
       icon: :shopping_bag,
  background: :mint,
       tone: :success
```

### Table

Displays a limited table of records.

```ruby
widget :table,
       resource: OrdersResourceManager,
       scope: :recent,
  background: :slate,
       columns: :dashboard_summary,
       limit: 8
```

### List

Displays a compact list of records using the ResourceManager label plus an optional secondary attribute.

```ruby
widget :list,
       resource: CustomersResourceManager,
       scope: :recent,
  background: :ocean,
       secondary_attribute: :created_at
```

### Chart

Displays a lightweight bar chart using grouped counts from the authorized relation.

```ruby
widget :chart,
       resource: OrdersResourceManager,
  group_by: :status,
  background: :indigo

widget :chart,
       resource: OrdersResourceManager,
       group_by: :created_at,
  period: :month,
  background: :charcoal
```

## Widget Background Colors

Widgets support a `background:` option for card-level background styling.

Available backgrounds:

- `:default`
- `:slate`
- `:ocean`
- `:mint`
- `:sand`
- `:rose`
- `:indigo`
- `:charcoal`

Background options are enabled by the dashboard controller. `Krudmin::DashboardController` ships with this default palette:

```ruby
%i[default slate ocean mint sand rose indigo charcoal]
```

You can override it in your dashboard controller:

```ruby
class Admin::DashboardController < Krudmin::DashboardController
  def widget_background_options
    %i[default mint charcoal]
  end
end
```

If a widget uses a background not included in `widget_background_options`, Krudmin safely falls back to `:default`.

Example with multiple colors:

```ruby
widget :count,
  resource: OrdersResourceManager,
  label: "Orders",
  background: :mint,
  tone: :success

widget :table,
  resource: OrdersResourceManager,
  label: "Recent Orders",
  background: :slate,
  columns: :dashboard_summary

widget :chart,
  resource: OrdersResourceManager,
  label: "Orders by Status",
  group_by: :status,
  background: :charcoal,
  tone: :primary
```

## ResourceManager Extension Points

Dashboards can use two optional ResourceManager constants.

### `DASHBOARD_SCOPES`

Named scopes for widgets:

```ruby
class OrdersResourceManager < Krudmin::ResourceManagers::Base
  DASHBOARD_SCOPES = {
    today: ->(relation, _user, _context) { relation.where(created_at: Time.current.all_day) },
    recent: ->(relation, _user, _context) { relation.order(created_at: :desc) }
  }
end
```

Each scope receives:

- `relation` — the already authorized relation
- `user` — the current user
- `context` — dashboard execution context

### `DASHBOARD_COLUMNS`

Named column presets for table widgets:

```ruby
class OrdersResourceManager < Krudmin::ResourceManagers::Base
  DASHBOARD_COLUMNS = {
    dashboard_summary: [:number, :customer_name, :status, :total]
  }
end
```

## Generator

Generate a starter dashboard with:

```bash
rails generate krudmin:dashboard Dashboard
```

With a custom namespace:

```bash
rails generate krudmin:dashboard Dashboard --namespace=admin
```

## Demo

This repository ships a working demo dashboard in the test application:

- `spec/test_app/app/dashboards/admin_dashboard.rb`
- `spec/test_app/app/controllers/admin/dashboard_controller.rb`

It demonstrates all shipped widget types against ResourceManagers instead of raw models.