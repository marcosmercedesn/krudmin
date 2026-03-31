# Architecture

This document describes the internal architecture of the Krudmin Rails Engine.

## System Overview

Krudmin is a Rails Engine that generates admin CRUD interfaces. It follows a layered architecture:

```
┌─────────────────────────────────────────────────────┐
│                     HTTP Request                     │
├─────────────────────────────────────────────────────┤
│                     Routes                           │
│          (host app defines resources)                │
├─────────────────────────────────────────────────────┤
│                   Controllers                        │
│   Krudmin::ApplicationController + Concerns          │
│   (Searchable, Authorizable, ModelStatusToggler,     │
│    CrudMessages, ActionButtonsSupport)               │
├─────────────────────────────────────────────────────┤
│              Resource Managers                        │
│   Define model metadata: fields, types, actions      │
│   Convention: CarsController → CarsResourceManager   │
├──────────────┬──────────────┬───────────────────────┤
│ Fields       │ Presenters   │ Mutation Handlers      │
│ Type system  │ Rendering    │ CRUD + status ops      │
│ Parsing      │ form/show/   │ CreateHandler          │
│              │ list/search  │ UpdateHandler           │
│              │              │ DestroyHandler          │
│              │              │ SwitchOn/OffHandler     │
├──────────────┴──────────────┴───────────────────────┤
│                    Views (HAML)                       │
│   Themed partials: fields, action buttons, layout    │
├─────────────────────────────────────────────────────┤
│              Supporting Systems                       │
│  SearchForm, NavigationMenu, Toolbar, ParamsParser   │
│  ActionButtons, ListActionPanel, ActivableLabeler    │
└─────────────────────────────────────────────────────┘
```

## Core Components

### 1. Engine Setup

**`lib/krudmin/engine.rb`**

The Rails Engine is configured with:
- `isolate_namespace Krudmin` — keeps Krudmin's models, controllers, and routes isolated
- RSpec test framework configuration
- I18n locale loading after initialization

**`lib/krudmin.rb`**

Main entry point that requires all components: fields, action buttons, mutation handlers, resource managers, navigation, search, and supporting modules.

**`lib/config.rb`**

Global configuration via `Krudmin::Config` module. All settings have sensible defaults.

### 2. Controllers

**`app/controllers/krudmin/application_controller.rb`**

The base controller providing all CRUD actions. Host application controllers inherit from this:

```ruby
class Admin::CarsController < Krudmin::ApplicationController
end
```

**Actions provided:** `index`, `new`, `create`, `edit`, `update`, `show`, `destroy`

**Concerns mixed in:**

| Concern | Purpose |
|---------|---------|
| `KrudminControllerSupport` | Router, current user, navigation menu, model_id |
| `KrudminResourceManagerControllerSupport` | Resource manager delegation, model loading, params, routing |
| `Authorizable` | Pundit authorization (optional, via config) |
| `ModelStatusToggler` | `activate`/`deactivate` actions |
| `CrudMessages` | I18n flash messages for all operations |
| `Searchable` | Search form params, cookie-based persistence |
| `ActionButtonsSupport` | Toolbar and list action panel builders |
| `HelperIncluder` | Dynamic helper method exposure to views |

**`app/controllers/krudmin/custom_controller.rb`**

Lightweight base for non-CRUD admin pages. Includes navigation and action buttons but no resource manager.

### 3. Resource Managers

**`lib/krudmin/resource_managers/base.rb`**

The central configuration class. Each admin resource has a ResourceManager that defines:
- Which model class to use
- Which attributes are editable, listable, searchable, displayable
- Field type overrides
- Default ordering, eager loading, actions
- Layout/presentation metadata

**Convention:** `Admin::CarsController` → `CarsResourceManager` (inferred from controller name in `KrudminResourceManagerControllerSupport`).

**`lib/krudmin/resource_managers/attribute_collection.rb`**

Manages the collection of field attributes. Processes `ATTRIBUTE_TYPES` metadata, combines with ActiveRecord schema info, handles grouped attributes, and generates strong params.

**`lib/krudmin/resource_managers/attribute.rb`**

Wraps a single field with its type and options. Responsible for:
- Instantiating Field objects (`new_field`)
- Parsing values through field types (`parse_with_field`)
- Generating permitted params for strong params
- Auto-detecting types from ActiveRecord columns (`from_inferred_type`)

**`lib/krudmin/resource_managers/routing.rb`**

Generates URL helpers by introspecting Rails routes. Creates methods like `resource_root`, `new_resource_path`, `edit_resource_path`, and checks for route existence (`index_route?`, `activate_route?`, etc.).

**`lib/krudmin/resource_managers/associated_type_resolver.rb`**

Resolves field types for delegated/associated attributes (e.g., `car_brand_description` resolves through the `car_brand` association to find the `description` column type).

### 4. Fields System

**`lib/krudmin/fields/base.rb`**

Abstract base class for all field types. Key responsibilities:
- Parse input values (`parse`)
- Access model data (`data`, `value`)
- Render through presenters (`render`)
- Generate permitted params (`permitted_attribute`)
- Provide search configuration (`search_config_for`, `search_criteria_for`)

**`lib/krudmin/fields/associated.rb`**

Base for association-backed fields (BelongsTo, HasMany, HasOne). Handles:
- Associated class resolution
- Foreign key detection
- Association name derivation
- Nested attributes setup
- Collection filtering

**Field Type Hierarchy:**

```
Base
├── String
│   ├── Text
│   ├── Email
│   ├── Password
│   ├── Hidden
│   └── RichText
├── Number
│   ├── Decimal
│   └── Currency
├── Boolean
├── Date
│   └── DateTime
└── Associated
    ├── BelongsTo
    │   └── EnumType
    ├── HasMany
    │   ├── HasManyIds
    │   └── HasOne
    │       └── BelongsToOne
    └── (abstract)
```

**`lib/krudmin/fields/inflector.rb`**

Maps ActiveRecord column types to Field classes:
- `:string` → String, `:text` → Text
- `:integer`, `:bigint`, `:float`, `:decimal` → Number
- `:datetime` → DateTime, `:date` → Date
- `:boolean` → Boolean

### 5. Presenters

**`lib/krudmin/presenters/base_field_presenter.rb`**

Abstract presenter handling rendering in different contexts:
- `render_form` — Form input
- `render_show` — Read-only display
- `render_list` — Table cell value
- `render_search` — Search filter input
- `render_json` — JSON serialization

Presenters are theme-aware: they render partials from `app/views/krudmin/{theme}/fields/{type}/`.

Each field type has a corresponding presenter (e.g., `BelongsToFieldPresenter`, `DateFieldPresenter`).

### 6. Mutation Handlers

**`lib/krudmin/mutation_handlers/`**

Service objects managing CRUD operations and response dispatch:

| Handler | Operation | Success Response |
|---------|-----------|------------------|
| `CreateHandler` | `model.save` | Redirect to edit (HTML) or render edit (JS) |
| `UpdateHandler` | `model.save` | Same as Create |
| `DestroyHandler` | `model.destroy` | Redirect to index (HTML) or render destroy (JS) |
| `SwitchOnHandler` | `model.activate!` | Context-aware (form redirect or list JS) |
| `SwitchOffHandler` | `model.deactivate!` | Same as SwitchOn with warning flash |

**Response Dispatch:**
- `FormContextUpdate` — Standard form: redirect to edit path with flash
- `ModalFormContextUpdate` — Modal form: HTML redirect or JS render
- `ActionDispatcher` — Base dispatcher using `respond_to` for HTML/JS/JSON

### 7. Search System

**`lib/krudmin/search_form.rb`**

Builds search UI and generates Ransack-compatible query params. Manages field-specific search criteria and operators.

**`app/controllers/concerns/krudmin/searchable.rb`**

Persists search state in cookies (`PersistedSearchResults`) so filters survive page navigation. Supports `?reset_search=1` to clear.

**`lib/krudmin/search_form/search_phrases_support.rb`**

Maps human-readable operators to Ransack predicates: `contains` → `:cont`, `equals` → `:eq`, `greater_than` → `:gt`, etc.

### 8. Navigation Menu

**`lib/krudmin/navigation_menu.rb`**

Builder for the sidebar navigation. Configured via a proc in `Krudmin::Config.navigation_menu`. Supports:
- `link` — Simple link items
- `node` — Auto-generated Manage/Add New links for resources
- Conditional visibility via `visible_if` procs
- Icon support via Font Awesome

### 9. Action Buttons and Toolbar

**`lib/krudmin/toolbar.rb`**

DSL for building page toolbars (save, cancel, show, etc.). Uses `content_for(:toolbar)`.

**`lib/krudmin/action_buttons/`**

Button classes for common actions. Each button knows how to render itself in form and list contexts. Types: Save, Cancel, Edit, Show, Destroy, New, Active, Search, Link, ModelAction.

**`lib/krudmin/list_action_panel.rb`**

Generates per-row action buttons in the list view from the `LISTABLE_ACTIONS` array.

### 10. Params Parser

**`lib/krudmin/params_parser.rb`**

Converts form params into model-ready data. For each param, finds the field type from the ResourceManager and calls `parse_with_field()` to transform the value (e.g., date string parsing, nested attribute handling).

### 11. Supporting Utilities

- **`ConstantsToMethodsExposer`** — Mixin that converts class constants (e.g., `SEARCHABLE_ATTRIBUTES`) into instance/class methods
- **`ActivableLabeler`** — Renders boolean values as colored badges (Active/Inactive)
- **`AppRouter`** — Wraps Rails routes for route existence checking

## Request Flow

### Index (List)

```
GET /admin/cars
  → ApplicationController#index
  → Searchable: load persisted search params from cookie
  → KrudminResourceManagerControllerSupport#item_list
    → CarsResourceManager#items (with includes, order, ransack)
    → Kaminari pagination
  → Render index.html.haml
    → _search_form.html.haml (SearchForm + SearchFilter)
    → Table with sortable headers
    → _list_item.html.haml per row (field presenters + action panel)
    → Pagination controls
```

### Create

```
POST /admin/cars
  → ApplicationController#create
  → set_model (builds new)
  → model.attributes = model_params (via ParamsParser)
  → authorize_model (if Pundit)
  → CreateHandler.perform
    → model.save
    → If valid: FormContextUpdate (redirect to edit)
    → If invalid: render new with errors
```

### Activate/Deactivate

```
POST /admin/cars/:id/activate
  → ModelStatusToggler#activate
  → SwitchOnHandler.perform
    → model.activate!
    → Dispatch via ActionDispatcher
      → Form context: redirect to edit
      → List context: HTML redirect or JS render
```

## View Structure

Views are organized under `app/views/krudmin/core_theme/`:

```
core_theme/
├── index.html.haml          # List view
├── show.html.haml           # Detail view
├── edit.html.haml           # Edit form
├── new.html.haml            # New form
├── _form.html.haml          # Shared form partial
├── _list_item.html.haml     # Single list row
├── _search_form.html.haml   # Search/filter form
├── _general_fields.html.haml # Field group container
├── _messages.html.haml      # Flash messages
├── *.js.erb / *.json.erb    # AJAX response templates
├── action_buttons/           # Button partials (per type)
├── fields/                   # Field partials (per type)
│   ├── string/
│   ├── boolean/
│   ├── belongs_to/
│   ├── has_many/
│   └── ...
└── layouts/                  # Application layout + components
```

## Data Flow: Field Rendering

```
ResourceManager.field_for(:name, model)
  → AttributeCollection.attribute_for(:name)
    → Attribute.new_field(model)
      → Krudmin::Fields::String.new(:name, model, options)
        → .render(:form, view_context)
          → StringFieldPresenter.render_form
            → view_context.render("krudmin/core_theme/fields/string/_form_field", ...)
```

## Dependencies

| Gem | Purpose |
|-----|---------|
| bootstrap (4.x) | CSS framework |
| cocoon | Nested forms (has_many add/remove) |
| devise | Authentication |
| font-awesome-rails | Icons |
| hamlit | HAML templates |
| jquery-rails | jQuery |
| kaminari | Pagination |
| momentjs-rails | Date/time formatting in JS |
| pundit | Authorization (optional) |
| ransack | Search/filtering |
| sassc-rails | SASS compilation |
| simple_form | Form builder |
| summernote-rails | Rich text editor |
| turbolinks | SPA-like navigation |
