# Krudmin - AI Agent Instructions

This host app uses Krudmin, a Rails Engine that generates admin behavior from Resource Managers.

## Source Of Truth

Use local Krudmin docs in this app first:

- `docs/krudmin/getting_started.md`
- `docs/krudmin/architecture.md`
- `docs/krudmin/resource_managers.md`
- `docs/krudmin/fields.md`
- `docs/krudmin/configuration.md`
- `docs/krudmin/generators.md`
- `docs/krudmin/search_and_filtering.md`
- `docs/krudmin/authorization.md`
- `docs/krudmin/navigation_menu.md`
- `docs/krudmin/views_and_themes.md`
- `docs/krudmin/custom_actions.md`
- `docs/krudmin/nested-fields.md`
- `docs/krudmin/workflow_state_machine.md`
- `docs/krudmin/audit_trail.md`
- `docs/krudmin/dashboard.md`
- `docs/krudmin/integration-testing-guide.md`
- `docs/krudmin/integration_test_generator.md`

Refresh these files after engine upgrades:

`rails generate krudmin:install --docs-only`

## Core Mental Model

Krudmin convention:

Controller -> Resource Manager -> Model

- Controller is usually empty and inherits from `Krudmin::ApplicationController`.
- Resource Manager constants define fields, actions, and behavior.
- Krudmin infers the Resource Manager from controller name.

Example mapping:

- `Admin::ProductsController` -> `ProductsResourceManager`

## Key Host App Files

- `config/initializers/krudmin.rb`: global Krudmin config
- `app/resource_managers/*_resource_manager.rb`: per-resource behavior
- `app/controllers/admin/*_controller.rb`: Krudmin controllers
- `app/policies/*_policy.rb`: Pundit policies when enabled
- `docs/krudmin/*`: detailed behavior and extension docs

## Safe Default Workflow For AI Changes

1. Read the matching `docs/krudmin/*` pages for the feature.
2. Prefer updating a Resource Manager before adding custom controller logic.
3. Keep routes aligned with Krudmin member actions (`activate`, `deactivate`) when status toggles are used.
4. For associations (`HasMany`, `HasOne`, `BelongsToOne`), ensure model `accepts_nested_attributes_for` is present.
5. If Pundit is enabled, update policy methods for new actions.
6. Add or update integration specs for user-facing admin behavior.

## Minimal Resource Checklist

1. Resource Manager with `MODEL_CLASSNAME` and attribute constants.
2. Empty admin controller inheriting from `Krudmin::ApplicationController`.
3. Namespaced routes with member `activate` and `deactivate` when needed.
4. Navigation menu node in `config/initializers/krudmin.rb`.

## Notes

- `ATTRIBUTE_TYPES` can be symbol shorthand or option hashes.
- `EDITABLE_ATTRIBUTES` can be an array or grouped hash with `PRESENTATION_METADATA`.
- Inline editing supports a limited set of field types; verify in `docs/krudmin/fields.md` before enabling.
