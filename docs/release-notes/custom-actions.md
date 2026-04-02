# Release Notes — Custom Actions DSL

Date: 2026-04-02

Summary
- Adds a first-class `custom_action` DSL to `Krudmin::ResourceManagers::Base` for declaring domain-specific member actions (e.g. `generate_invoice`, `clone`). The DSL wires presentation, authorization, routing helpers, and a generator scaffold so host apps can opt in with minimal boilerplate.

Key changes
- `custom_action` macro: register actions and normalize metadata (`label`, `icon`, `method`, `confirm`, `placement`, `route`, `presenter_options`).
- `custom_actions` accessor: instance-level normalized metadata via the constants-to-methods exposer.
- `member_action_path` heuristics: broader helper-name permutations (singular/plural, common namespaced variants) and support for callable/string/symbol `route` overrides.
- Pundit integration: render-time checks (when `authorize: true`) and guidance to call `authorize` in host controller methods. The engine provides a `pundit_user` mapping and defers Pundit inclusion to avoid load-order issues.
- Boot-time validations: invalid names, reserved controller action collisions, duplicate definitions, invalid HTTP methods, invalid `placement` or `route` option types will raise helpful errors at class-load/boot time.
- Optional opt-in `Krudmin::CustomActionsController` (convenience dispatch) while generator scaffolds explicit host controller member methods by default.
- Generator: `rails generate krudmin:custom_action RESOURCE action_name` prints a route snippet, a controller method stub (with `authorize` example and Turbo/HTML responses), and a spec template.
- Tests: unit, presenter, request, and feature specs added; guidance included to avoid test load-order leaks (prefer requiring only necessary files in unit tests and restore global config after mutation).

Upgrade / Migration notes for host apps
- Add a member route for each new custom action. Example (admin namespace):

```ruby
namespace :admin do
  resources :orders do
    post :generate_invoice, on: :member
  end
end
```

- Implement the host controller member method with an authorization call and the desired response formats (Turbo/Turbo Stream, HTML, JSON). Example:

```ruby
module Admin
  class OrdersController < Krudmin::ApplicationController
    def generate_invoice
      @order = Order.find(params[:id])
      authorize @order, :generate_invoice?
      GenerateInvoiceJob.perform_later(@order.id, current_user.id)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(...) }
        format.html { redirect_back fallback_location: admin_order_path(@order), notice: "Queued invoice" }
        format.json { head :accepted }
      end
    end
  end
end
```

- Ensure Pundit policies expose the predicate (e.g. `def generate_invoice?; ...; end`). If your app uses a custom current-user helper, set `Krudmin::Config.current_user_method` in the Krudmin initializer so the engine can map `_current_user` appropriately.

- Avoid naming a custom action with reserved controller method names (`index, show, new, edit, create, update, destroy`). Boot-time validation will raise on conflicts.

Developer notes
- Boot-time validation will raise informative errors; fix the ResourceManager definition (rename or correct options) to resolve.
- Unit tests: prefer requiring focused files rather than booting the whole engine to avoid load-order issues (Pundit/ActionView). If a spec mutates global config (e.g. `Krudmin::Config.current_user_method`), restore the previous value in an `ensure` block.
- Path-builder heuristics were expanded to increase compatibility with common host naming schemes — if you want deterministic routes, pass a `route:` callable or helper name in the `custom_action` options.

Files / locations touched
- `lib/krudmin/resource_managers/base.rb` — macro, normalization, `member_action_path` heuristics, boot-time validation
- `lib/krudmin/action_buttons/custom_action_button.rb` — presenter wiring and Pundit-aware rendering
- `lib/krudmin/list_action_panel.rb` — safe rendering fallback
- `app/controllers/concerns/krudmin/authorizable.rb` — deferred Pundit include and `pundit_user` mapping
- Specs: unit, presenter, request, feature files under `spec/lib/krudmin` and `spec/features`

How to try locally

```bash
# run unit tests for the new members
bundle exec rspec spec/lib/krudmin/resource_managers/custom_actions_spec.rb
bundle exec rspec spec/lib/krudmin/resource_managers/member_action_path_spec.rb

# run the feature spec for the test app
bundle exec rspec spec/features/cars/car_custom_action_spec.rb
```

If you want, I can add a short `CHANGELOG.md` entry instead of this file or wire this into an existing release note process.
