# Configuration

Krudmin is configured via the `Krudmin::Config` module in an initializer file.

## Setup

Create `config/initializers/krudmin.rb` in your Rails application:

```ruby
Krudmin::Config.with do |config|
  # Configuration options here
end
```

You can also use the block syntax:

```ruby
Krudmin::config do |cfg|
  # Configuration options here
end
```

Multiple configuration blocks can be chained:

```ruby
Krudmin::Config.with do |config|
  config.parent_controller = "ApplicationController"
  config.navigation_menu = -> { ... }
end

Krudmin::config do |cfg|
  cfg.krudmin_root_path = :admin_root_path
  cfg.pundit_enabled = true
end
```

## Configuration Options

### parent_controller

**Type:** String
**Default:** `"ActionController::Base"`

The base controller class for all Krudmin controllers. Set this to your application's base controller to inherit authentication, before_actions, and helper methods.

```ruby
config.parent_controller = "ApplicationController"
```

### krudmin_root_path

**Type:** Symbol or String
**Default:** `"#"`

The root path for the admin panel. Used in navigation and redirects.

```ruby
config.krudmin_root_path = :admin_root_path
config.krudmin_root_path = "/admin"
```

### current_user_method

**Type:** Block

A proc/block that returns the current user. Called in the context of the controller.

```ruby
config.current_user_method { current_user }
config.current_user_method { current_admin }
```

### pundit_enabled

**Type:** Boolean
**Default:** `false`

Enable Pundit-based authorization. When enabled, all CRUD actions check Pundit policies.

```ruby
config.pundit_enabled = true
```

See [Authorization](/docs/authorization.md) for details.

### theme

**Type:** String
**Default:** `"krudmin/core_theme"`

The theme directory name. Views are loaded from `app/views/krudmin/{theme}/`.

```ruby
config.theme = "krudmin/core_theme"
```

### layout

**Type:** String
**Default:** Same as `theme`

The layout template name. Defaults to the theme value.

```ruby
config.layout = "krudmin/core_theme"
config.layout = "krudmin/core_theme_top_navbar"
```

### form_wrapper

**Type:** Symbol
**Required for forms**

The SimpleForm wrapper name for standard forms. Must match a wrapper defined in `simple_form_bootstrap.rb`.

```ruby
config.form_wrapper = :horizontal_form
config.form_wrapper = :vertical_form
```

### modal_form_wrapper

**Type:** Symbol

The SimpleForm wrapper name for modal forms.

```ruby
config.modal_form_wrapper = :vertical_form
```

### require_authenticated_user_method

**Type:** Symbol

A before_action method name for authentication. Applied to controllers that require authentication.

```ruby
config.require_authenticated_user_method = :authenticate_user!        # Devise
config.require_authenticated_user_method = :authenticate_admin_user!   # Custom
```

### paginator_position

**Type:** Symbol
**Default:** `:top`

Where to render pagination controls. Can be overridden per Resource Manager via `PAGINATOR_POSITION`.

```ruby
config.paginator_position = :top            # Above the list
config.paginator_position = :bottom         # Below the list
config.paginator_position = :top_and_bottom # Both
```

### navigation_menu

**Type:** Proc/Lambda

A proc that returns a `Krudmin::NavigationMenu` instance. Called on each request.

```ruby
config.navigation_menu = -> {
  Krudmin::NavigationMenu.configure do |menu, user|
    menu.node label: "Cars", resource: "car", module_path: :admin, icon: :car
    menu.node label: "Brands", resource: "car_brand", icon: :tag
    menu.link label: "Dashboard", link: :admin_root_path, icon: :dashboard
  end
}
```

See [Navigation Menu](/docs/navigation_menu.md) for details.

### edit_profile_path

**Type:** String

URL path for the "Edit Profile" link in the header.

```ruby
config.edit_profile_path = "/admin/profile"
```

### logout_path

**Type:** String

URL path for the "Logout" link in the header.

```ruby
config.logout_path = "/users/sign_out"
```

### login_screen_intro_message

**Type:** String

HTML message displayed on the login page.

```ruby
config.login_screen_intro_message = "<h4>Welcome to Admin</h4><p>Sign in to manage your data.</p>"
```

## Complete Example

```ruby
# config/initializers/krudmin.rb

Krudmin::Config.with do |config|
  # Controller
  config.parent_controller = "ApplicationController"

  # Authentication
  config.require_authenticated_user_method = :authenticate_user!
  config.current_user_method { current_user }

  # Paths
  config.krudmin_root_path = :admin_root_path
  config.edit_profile_path = "/admin/profile"
  config.logout_path = "/users/sign_out"

  # Theme & Layout
  config.theme = "krudmin/core_theme"
  config.layout = "krudmin/core_theme"

  # Forms
  config.form_wrapper = :horizontal_form
  config.modal_form_wrapper = :vertical_form

  # Pagination
  config.paginator_position = :top

  # Authorization
  config.pundit_enabled = true

  # Login page
  config.login_screen_intro_message = "Welcome to the Admin Panel"

  # Navigation
  config.navigation_menu = -> {
    Krudmin::NavigationMenu.configure do |menu, user|
      menu.node label: "Products", resource: "product", module_path: :admin, icon: :box
      menu.node label: "Categories", resource: "category", module_path: :admin, icon: :folder
      menu.node label: "Users", resource: "user", module_path: :admin, icon: :users,
                visible_if: -> { user&.admin? }
      menu.link label: "Reports", link: :admin_reports_path, icon: :chart_bar
    end
  }
end
```

## Configuration Defaults

| Option | Default |
|--------|---------|
| `parent_controller` | `"ActionController::Base"` |
| `krudmin_root_path` | `"#"` |
| `current_user_method` | Empty proc |
| `pundit_enabled` | `false` |
| `theme` | `"krudmin/core_theme"` |
| `layout` | Same as theme |
| `paginator_position` | `:top` |
