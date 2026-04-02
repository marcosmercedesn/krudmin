# Custom Actions DSL — Design

Status: Draft

## Purpose

Provide a declarative DSL on `ResourceManagers::Base` to register domain-specific member actions ("custom actions") such as `generate_invoice`, `clone`, `send_email`, and `mark_as_paid`. The macro should make it easy to:

- Declare the action and presentation metadata in the resource manager.
- Render action buttons consistently in list rows and resource toolbars.
- Provide a predictable mapping to host-app controller member methods and route patterns.
- Gate rendering and execution with authorization hooks (Pundit) and optional confirmations.

This reduces boilerplate: currently authors must create button classes/partials, add routes, and write controller stubs manually.

## Goals

- First-class, simple macro: `custom_action :name, **options`.
- Reuse existing action-button presenters so UI remains consistent.
- Safe defaults: `method: :post` for side-effects, `authorize: true`, `turbo: true`.
- Clear generator output that scaffolds the minimal host edits (route snippet, controller stub, spec).

## Macro Signature

```ruby
custom_action(name, options = {})
```

- `name` — Symbol. The action identifier used in `LISTABLE_ACTIONS` and to map to the controller method.
- `options` — Hash of supported keys (below).

## Supported Options and Defaults

- `label` — String. Button text. Default: `name.to_s.humanize`.
- `icon` — Symbol or string. Optional icon name.
- `method` — Symbol. HTTP verb to execute the action. Default: `:post` (recommended for non-idempotent ops).
- `confirm` — String. Confirmation message rendered as `data-confirm`.
- `class` — String. Custom CSS classes for the button (e.g., `btn-success`).
- `turbo` — Boolean. Whether responses will typically be Turbo/Turbo Stream friendly. Default: `true`.
- `authorize` — Boolean. If `true` (default), engine will check policy at render time (and recommend controller check at execution).
- `placement` — Symbol or Array `:list`, `:toolbar`, `:both`. Default: `:list` (row actions). Use `:toolbar` to show in form toolbars.
- `if` — Callable `(resource, user, context) -> boolean` or proc for conditional display (optional).
- `route` — String or `proc` — Optional override to compute URL; if set, used instead of path helper inference.
- `presenter_options` — Hash passed through to the action presenter.

All option keys are normalized to snake_case.

## Normalization Rules

- Accept either shorthand symbol `{ custom_action :name }` or full hash `{ custom_action :name, label: "X" }`.
- Store normalized structure in a `CUSTOM_ACTIONS` registry on the ResourceManager class.
- Normalized shape example:

```ruby
{
  name: :generate_invoice,
  label: "Generate Invoice",
  icon: :file_text,
  method: :post,
  confirm: "Generate invoice for this order?",
  class: "btn-success",
  turbo: true,
  authorize: true,
  placement: [:list],
  if: ->(resource,user,ctx){ ... }
}
```

## Storage & Access

- ResourceManagers should expose `custom_actions` as an instance method (via constants-to-methods exposer pattern). Example: `resource_manager.custom_actions` returns an array or hash of normalized definitions.
- Convenience lookup: `resource_manager.custom_action_for(:generate_invoice)` → normalized hash or `nil`.

## Rendering

- The action-presenter pipeline should be extended to detect custom actions. When rendering an action button:
  - Use the normalized metadata to set the label, icon, `class`, `data-confirm`, and `data-method` (Rails `link_to` style: `data-method` or `form` fallback).
  - If `turbo: true`, include `data-turbo` attributes as appropriate (or rely on `link_to` with `data: { turbo: true }`).
  - Respect the `if` predicate when deciding whether to render the button.
  - If Pundit is present and `authorize: true`, evaluate `policy(resource).public_send("#{name}?")` and skip rendering if false.

- Placement: action buttons appear in per-row action lists when `placement` includes `:list`. When `placement` includes `:toolbar`, add to the form toolbar (new/edit/show toolbars) via existing toolbar partials.

## URL / Path Builder

- Recommended host route convention (explicit in docs & generator):

```ruby
namespace :admin do
  resources :orders do
    post :generate_invoice, on: :member
  end
end
```

- Engines can't reliably create host route helpers. Provide a helper on resource manager that attempts to build the path using conventional helper names, falling back to `options[:route]` when provided.

Example path builder pseudo-code:

```ruby
# inside ResourceManager
def member_action_path(resource, action, opts = {})
  return instance_exec(resource, &opts[:route]) if opts[:route].respond_to?(:call)
  # e.g. admin_generate_invoice_order_path(resource)
  helper_name = [action, resource_name.singularize, "path"].join("_")
  if respond_to? helper_name
    send(helper_name, resource)
  else
    raise "No route found for custom action #{action} — add a member route in host app"
  end
end
```

Docs should insist that host apps add a `member` route for the action (generator will provide the snippet).

## Controller Mapping & Execution

- Conventions: the host app should define a member action method in the corresponding controller, e.g. `Admin::OrdersController#generate_invoice`.
- Inside the controller method example:

```ruby
def generate_invoice
  @order = Order.find(params[:id])
  authorize @order, :generate_invoice?
  GenerateInvoiceJob.perform_later(@order.id, current_user.id)
  respond_to do |format|
    format.turbo_stream { render turbo_stream: turbo_stream.replace(... ) }
    format.html { redirect_back fallback_location: admin_order_path(@order), notice: "Invoice job queued" }
    format.json { head :accepted }
  end
end
```

- The engine should *not* silently dispatch to a catch-all controller by default — prefer explicit host controller methods for clarity and authorization. An optional opt-in `CustomActionsController` can be provided that dispatches by action name as convenience; if used, it must perform authorization and be opt-in in the initializer.

## Authorization

- Render-time: if `authorize: true` and Pundit available, evaluate `policy(resource).public_send("#{name}?")`.
- Execution-time: the controller must perform `authorize resource, :#{name}?` (generator will scaffold this pattern).
- Note: presence of `authorize: false` does not remove responsibility of host controller to check permissions — document clearly.

## Generator

`rails generate krudmin:custom_action RESOURCE action_name [--namespace=admin] [--no-specs]`

Generator outputs:

- `routes.rb` snippet for the host to paste (member route).
- Controller method stub in host controller (with `authorize` call and example Turbo stream response). It will *not* automatically modify `routes.rb` to avoid surprising changes to host app.
- Spec template showing how to call the action and assert responses.
- Example Turbo stream partial to update the row or show a toast.

The generator should print a small checklist to the console: add route, implement logic, run tests.

## Tests

- Unit tests for macro normalization and `resource_manager.custom_actions` accessor.
- Presenter tests that the action button renders expected attributes (`data-confirm`, `data-method`, CSS classes, icon markup).
- Controller spec example (generator) that stubs the operation and asserts Turbo stream/redirect behavior.
- Feature/integration test that exercises the end-to-end flow.

## Validation and Boot-time Checks

At boot (or during `rake assets:precompile`), validate:

- `custom_action` names are valid Ruby method names and do not collide with reserved controller methods (index, show, new, edit, create, update, destroy).
- No duplicate action names across the same ResourceManager.
- Options shape is valid (recognized keys, boolean values where expected).

Failures should raise a helpful error with remediation steps.

## Security & Operational Guidance

- Default to `POST` for side-effects, require CSRF tokens on forms/links.
- For long-running business ops, recommend enqueuing background jobs and returning `202 Accepted` / Turbo-stream responses that show progress.
- Recommend auditing these operations (integrate with Audit Trail feature #6).

## Backwards Compatibility

- `krudmin:action` generator remains supported for authors who want low-level control and custom button classes.
- `custom_action` DSL is additive and does not remove the existing button system.

## Example

```ruby
class OrdersResourceManager < Krudmin::ResourceManagers::Base
  custom_action :generate_invoice, label: "Generate Invoice", icon: :file_text,
                confirm: "Generate invoice for this order?",
                method: :post, class: "btn-success", placement: :list

  custom_action :clone, label: "Clone", icon: :copy, method: :post, placement: [:list, :toolbar]

  LISTABLE_ACTIONS = [:show, :edit, :generate_invoice, :clone, :active, :destroy]
end
```

Host `routes.rb` snippet the generator will suggest:

```ruby
namespace :admin do
  resources :orders do
    post :generate_invoice, on: :member
    post :clone, on: :member
  end
end
```

Host controller stub (generator output):

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
      end
    end
  end
end
```

## Next steps

1. Implement the macro and normalization (low-risk, small change).
2. Add accessor methods and unit tests.
3. Wire the presenter to render custom buttons.
4. Add the generator.

---

Document created by the development assistant. Feel free to request edits, tighter constraints, or to start implementing step 2.

## Implementation notes

- Path builder heuristics: the ResourceManager `member_action_path(view_context, resource, action_name)` now supports plural/singular base names and common namespaced permutations (e.g. `admin_generate_invoice_order_path`, `generate_invoice_admin_order_path`). This improves resolution for host apps that namespace controllers under `admin` or use singularized helper names. When the action metadata provides a callable `:route`, that callable is executed in the `view_context` so Rails URL helpers are available.

- Pundit integration: rendering and execution respect `authorize: true` by default. The engine defers including Pundit until controllers are initialized and defines a `pundit_user` override that returns Krudmin's `_current_user`. Host apps should set `Krudmin::Config.current_user_method` in the Krudmin initializer so `_current_user` maps to their app's current user helper.

- Optional dispatch controller: the engine provides an opt-in `Krudmin::CustomActionsController` that can dispatch custom actions centrally, but the generator will prefer creating explicit host controller member methods to keep authorization and business logic clear.

## Testing & integration notes

- Unit tests should avoid requiring the entire `lib/krudmin` boot file: requiring every file at unit-test time can load engine code before the Rails app and test harness are fully set up (Pundit, ActionView, and other helpers), which can introduce order-dependent failures. Prefer requiring only the specific classes under test (for example `resource_managers/base`, `list_action_panel`, and the specific action button classes) in isolated unit specs.

- Specs that mutate global configuration (for example `Krudmin::Config.current_user_method`) must restore the previous value in an `ensure` block so configuration changes don't leak into later examples and cause intermittent failures when running the full suite.

- Boot-time validations: it's recommended (and planned) to validate `custom_action` definitions at boot or during `rake assets:precompile` for the following conditions:
  - Names are valid Ruby method names and do not conflict with controller core actions.
  - No duplicate action names exist on the same ResourceManager.
  - Option keys are recognized and boolean values are normalized.

These checks should produce developer-friendly errors that suggest how to fix the problem (e.g., rename the action or change the option key).

## Generator checklist (what the generator will print)

- Route snippet to paste into `config/routes.rb` (member `post` by default).
- Controller member method stub with `authorize resource, :action?` and a Turbo/HTML example response.
- A spec template you can adapt for request/controller testing.
- A brief checklist reminding the developer to: add the route, implement business logic, and run the test suite.
