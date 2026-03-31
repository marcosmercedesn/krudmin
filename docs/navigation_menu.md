# Navigation Menu

Krudmin provides a configurable sidebar navigation menu. The menu is defined in the Krudmin initializer and supports links, resource nodes, icons, and conditional visibility.

## Configuration

Define the navigation menu in your initializer:

```ruby
Krudmin::Config.with do |config|
  config.navigation_menu = -> {
    Krudmin::NavigationMenu.configure do |menu, user|
      menu.node label: "Cars", resource: "car", module_path: :admin, icon: :car
      menu.node label: "Brands", resource: "car_brand", icon: :tag
      menu.link label: "Dashboard", link: :admin_root_path, icon: :dashboard
    end
  }
end
```

The `navigation_menu` config takes a lambda/proc. The lambda is called on each request, receiving the current user.

## Menu Items

### node

Creates a resource node with auto-generated "Manage" and "Add New" sub-links.

```ruby
menu.node label: "Cars",
          resource: "car",
          module_path: :admin,     # Route namespace (optional)
          icon: :car,              # Font Awesome icon name
          visible_if: -> { true }  # Visibility condition (optional)
```

A `node` with `resource: "car"` and `module_path: :admin` generates:
- **Manage Cars** → `admin_cars_path`
- **Add New Car** → `new_admin_car_path`

The route helpers are inferred from the resource name and module path.

### link

Creates a simple navigation link.

```ruby
menu.link label: "Dashboard",
          link: :admin_root_path,   # Route helper symbol or string
          module_path: :admin,      # Route namespace (optional)
          icon: :dashboard,         # Font Awesome icon name
          visible_if: -> { true }   # Visibility condition (optional)
```

## Options

| Option | Type | Description |
|--------|------|-------------|
| `label` | String | Display text for the menu item |
| `resource` | String | Resource name (used with `node` to generate sub-links) |
| `link` | Symbol/String | Route helper or URL path (used with `link`) |
| `module_path` | Symbol | Route namespace prefix (e.g., `:admin`) |
| `icon` | Symbol | Font Awesome icon name (without `fa-` prefix) |
| `visible_if` | Proc/Lambda | Condition for showing/hiding the menu item |
| `html` | Hash | Additional HTML attributes |

## Conditional Visibility

Use `visible_if` to show/hide menu items based on the current user or other conditions:

```ruby
# Only show to admins
menu.node label: "Users", resource: "user", module_path: :admin,
          visible_if: -> { user&.admin? }

# Use Pundit policy
menu.node label: "Cars", resource: "car", module_path: :admin,
          visible_if: -> { CarPolicy.new(user, nil).index? }

# Always visible (default)
menu.link label: "Dashboard", link: :admin_root_path
```

The `visible_if` proc has access to the `user` variable from the `configure` block.

## Icons

Icons use Font Awesome (included via `font-awesome-rails`). Pass the icon name as a symbol:

```ruby
menu.node label: "Cars", resource: "car", icon: :car
menu.link label: "Settings", link: :settings_path, icon: :gear
menu.link label: "Reports", link: :reports_path, icon: :chart_bar
menu.node label: "Users", resource: "user", icon: :users
```

## Complete Example

```ruby
config.navigation_menu = -> {
  Krudmin::NavigationMenu.configure do |menu, user|
    # Resource with full CRUD sub-links
    menu.node label: "Products",
              resource: "product",
              module_path: :admin,
              icon: :box

    # Resource visible only to admins
    menu.node label: "Users",
              resource: "user",
              module_path: :admin,
              icon: :users,
              visible_if: -> { user&.admin? }

    # Resource with Pundit policy check
    menu.node label: "Orders",
              resource: "order",
              module_path: :admin,
              icon: :shopping_cart,
              visible_if: -> { OrderPolicy.new(user, nil).index? }

    # Simple link
    menu.link label: "Dashboard",
              link: :admin_root_path,
              icon: :dashboard

    # External or custom link
    menu.link label: "Documentation",
              link: :docs_path,
              icon: :book
  end
}
```

## How It Works Internally

1. `Krudmin::NavigationMenu` is an Enumerable class that holds menu items
2. `configure` takes a block that receives `(menu, user)`
3. `node` calls `Node.node_for()` which generates "Manage" and "Add New" sub-items
4. `link` creates a simple `Node` instance
5. The menu iterates over `visible_items` — items where `visible?` returns true
6. The sidebar partial (`_sidebar_menu.html.haml`) renders each visible item

### Node Class

`Krudmin::NavigationMenu::Node` represents a single menu item:

- `visible?` — Checks `visible_if` proc and child visibility
- `node_for()` — Class method creating a folder with auto-generated Manage/Add New links
- `links_for()` — Generates standard resource links from the resource name and module path
