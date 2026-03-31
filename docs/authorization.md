# Authorization

Krudmin uses [Pundit](https://github.com/varvet/pundit) for authorization. When enabled, all CRUD actions are protected by policy checks.

## Enabling Authorization

In your Krudmin initializer:

```ruby
Krudmin::Config.with do |config|
  config.pundit_enabled = true
  config.current_user_method { current_user }
end
```

## Creating Policies

Create a policy class for each model you want to protect. Krudmin checks these actions:

| Action | Policy Method | When Checked |
|--------|--------------|--------------|
| index | `index?` | Before listing resources |
| show | `show?` | Before showing a resource |
| new | `new?` | Before showing the new form |
| edit | `edit?` | Before showing the edit form |
| create | `create?` | Before creating (via `authorize_model`) |
| update | `update?` | Before updating |
| destroy | `destroy?` | Before destroying |
| activate | `activate?` | Before activating |
| deactivate | `deactivate?` | Before deactivating |

### Example Policy

```ruby
# app/policies/product_policy.rb
class ProductPolicy < ApplicationPolicy
  def index?
    true  # Everyone can view the list
  end

  def show?
    true
  end

  def create?
    user.admin?
  end

  def new?
    create?
  end

  def update?
    user.admin?
  end

  def edit?
    update?
  end

  def destroy?
    user.admin?
  end

  def activate?
    user.admin?
  end

  def deactivate?
    user.admin?
  end

  # Optional: Scope for filtering visible records
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(published: true)
      end
    end
  end
end
```

### Record-Level Authorization

Policies receive the record, so you can make per-record decisions:

```ruby
class CarPolicy < ApplicationPolicy
  def show?
    record.year <= 9000  # Only show cars from reasonable years
  end

  def edit?
    record.year <= 9000
  end
end
```

## How It Works

The `Authorizable` concern (`app/controllers/concerns/krudmin/authorizable.rb`) integrates Pundit:

1. **Scope filtering**: For `index`, `policy_scope` filters the items list so users only see authorized records.

2. **Action authorization**: Before each action, Pundit's `authorize` is called with the model instance.

3. **View helpers**: The concern exposes `{action}_access?` methods to views. These are used by action buttons to show/hide based on authorization:

```ruby
# In views, these helpers are available:
show_access?       # Can the current user view this record?
edit_access?       # Can they edit?
destroy_access?    # Can they destroy?
activate_access?   # Can they activate?
deactivate_access? # Can they deactivate?
```

### GranularAccessControl

The `GranularAccessControl` module (inside `Authorizable`) generates access check methods for each CRUD action. These delegate to the Pundit policy:

```ruby
# Generated methods check Pundit policy
def show_access?
  policy(model).show?
end
```

When Pundit is disabled, these methods default to `true`.

## Pundit User

The `pundit_user` method is set to `_current_user`, which comes from `Krudmin::Config.current_user_method`. Make sure your config provides a valid user object:

```ruby
config.current_user_method { current_user }
```

## Navigation Menu Visibility

You can also use policies to control menu visibility:

```ruby
config.navigation_menu = -> {
  Krudmin::NavigationMenu.configure do |menu, user|
    menu.node label: "Cars", resource: "car", module_path: :admin,
              visible_if: -> { CarPolicy.new(user, nil).index? }

    menu.node label: "Users", resource: "user", module_path: :admin,
              visible_if: -> { user&.admin? }
  end
}
```

## Disabling Authorization

To disable authorization entirely (default):

```ruby
Krudmin::Config.with do |config|
  config.pundit_enabled = false  # or simply don't set it
end
```

When disabled, all actions are allowed and no policy checks are performed.
