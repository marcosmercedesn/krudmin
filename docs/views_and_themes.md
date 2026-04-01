# Views and Themes

Krudmin uses HAML templates organized by theme. The default theme is `core_theme`, built on Bootstrap 4 with CoreUI.

## Theme Structure

Views are located at `app/views/krudmin/{theme}/`:

```
app/views/krudmin/core_theme/
├── index.html.haml              # List view
├── show.html.haml               # Detail view
├── edit.html.haml               # Edit form
├── new.html.haml                # New form
├── _form.html.haml              # Shared form partial
├── _list_item.html.haml         # Single table row
├── _search_form.html.haml       # Search/filter form
├── _general_fields.html.haml    # Field group container
├── _messages.html.haml          # Flash messages
├── _error_messages.html.haml    # Form validation errors
│
├── edit.js.erb                  # AJAX edit response
├── new.js.erb                   # AJAX new response
├── show.js.erb                  # AJAX show response
├── destroy.js.erb               # AJAX destroy response
├── activate.js.erb              # AJAX activate response
├── deactivate.js.erb            # AJAX deactivate response
├── form_errors.js.erb           # AJAX validation errors
├── index.json.erb               # JSON list response
├── _form.json.erb               # JSON form response
│
├── action_buttons/              # Button partials
│   ├── new_button/
│   │   ├── _form.html.haml
│   │   └── _list.html.haml
│   ├── edit_button/
│   ├── show_button/
│   ├── destroy_button/
│   ├── active_button/
│   ├── save_button/
│   ├── cancel_button/
│   ├── link_button/
│   └── search_button/
│
├── fields/                      # Field partials
│   ├── string/
│   │   ├── _form_field.html.haml
│   │   ├── _search.html.haml
│   │   └── _show.html.haml
│   ├── text/
│   ├── number/
│   ├── boolean/
│   ├── date/
│   ├── date_time/
│   ├── email/
│   ├── password/
│   ├── hidden/
│   ├── rich_text/
│   ├── enum_type/
│   ├── belongs_to/
│   ├── belongs_to_one/
│   ├── has_many/
│   ├── has_many_ids/
│   └── has_one/
│
└── layouts/
    └── krudmin/
        ├── core_theme.html.haml         # Main layout
        ├── sessions.html.haml           # Login layout
        └── core_theme/
            ├── _header.html.haml        # Top navbar
            ├── _sidebar_menu.html.haml  # Sidebar navigation
            ├── _toolbar.html.haml       # Action toolbar
            ├── _messages.html.haml      # Flash messages
            └── _breadcrumbs.html.haml   # Breadcrumbs
```

## Configuring the Theme

```ruby
Krudmin::Config.with do |config|
  config.theme = "krudmin/core_theme"
  config.layout = "krudmin/core_theme"
end
```

## Overriding Views

To customize any view, copy it from the engine to your application at the same path. Rails will use your application's version over the engine's.

For example, to customize the list item rendering:

```bash
# Copy from the engine
cp $(bundle show krudmin)/app/views/krudmin/core_theme/_list_item.html.haml \
   app/views/krudmin/core_theme/_list_item.html.haml
```

Then edit the copy in your application.

## Customizing Per-Controller

### Toolbar Buttons

Override toolbar buttons by creating partials in your controller's view directory.

For **list view** toolbar (appears above the list):

```haml
-# app/views/admin/cars/_list_action_buttons.html.haml
- configure_toolbar(:list, self) do |b|
  - b.button :new, new_resource_path(form_context: :modal), remote: remote_crud
  - b.button :search
  - b.link "https://google.com", label: "Google", icon: :external_link,
           html_options: { data: { sweet_confirm: confirm_destroy_message } }
```

For **form view** toolbar (appears in the edit/new form):

```haml
-# app/views/admin/cars/_form_action_buttons.html.haml
- configure_toolbar(:form, self) do |b|
  - b.button :save, form_submit_path, form: f, remote: remote_crud
  - b.button :cancel, resource_root
  - b.button :show, model
  - b.button :active, model
```

### Action Buttons

Each action button has two partial variants:
- `_form.html.haml` — Rendered in form toolbar context
- `_list.html.haml` — Rendered in list row context

Button types: `new_button`, `edit_button`, `show_button`, `destroy_button`, `active_button`, `save_button`, `cancel_button`, `search_button`, `link_button`.

## Field Partials

Each field type renders through partials in `fields/{type}/`:

- `_form_field.html.haml` — Form input rendering
- `_search.html.haml` — Search filter rendering
- `_show.html.haml` — Read-only display (optional, some use inline rendering)

### Customizing a Field's Form Input

To override how a specific field type renders its form input, create a partial at:

```
app/views/krudmin/core_theme/fields/{type}/_form_field.html.haml
```

The partial receives these locals:
- `f` — SimpleForm form builder
- `field` — The field presenter instance
- `options` — Additional options hash

## Layouts

### Main Layout (`core_theme.html.haml`)

The main layout includes:
- Header with user menu, profile link, logout
- Sidebar with navigation menu
- Main content area with breadcrumbs, toolbar, flash messages, and page content

### Sessions Layout (`sessions.html.haml`)

A simplified layout for login/logout pages without sidebar or navigation.

## CSS & JavaScript

### Stylesheets

The main stylesheet is at `app/assets/stylesheets/krudmin/core_theme/application.scss`:
- Bootstrap 4
- Font Awesome
- Summernote (rich text editor)
- Vendor: daterangepicker, toast, select2
- CoreUI theme

### JavaScript

The main JS is at `app/assets/javascripts/krudmin/core_theme/application.js`:
- jQuery 3, Rails UJS, Popper, Bootstrap
- Turbo, Moment.js, nested-fields.js
- Vendor: daterangepicker, SweetAlert, Select2, Toast, Cookies
- Krudmin adapters: datepicker, select2, summernote, tooltip, turbo-forms, belongs-to-one controls

### JavaScript Events

Krudmin dispatches custom events:

| Event | When | Use |
|-------|------|-----|
| `turboforms:updated` | After AJAX form submission | Re-initialize dynamic controls |
| `krudmin:updateControls` | After dynamic content load | Reinitialize select2, datepickers, etc. |
| `updateBelongsToLookups` | After association change | Refresh belongs-to dropdowns |

### UI State Persistence

Krudmin persists certain UI states in cookies:
- **Sidebar collapsed/expanded** — `sidebar-minimized`, `brand-minimized`, `sidebar-hidden`
- **Card collapse state** — Persisted in `sessionStorage`
- **Search filters** — Persisted in `krudmin_search_results` cookie

## Flash Messages

Flash messages are rendered as Bootstrap alerts:

| Flash Key | CSS Class | Color |
|-----------|-----------|-------|
| `:info` | `alert-info` | Blue |
| `:success` | `alert-success` | Green |
| `:warning` | `alert-warning` | Yellow |
| `:error` | `alert-danger` | Red |

AJAX responses use `toastr` toast notifications.

## Pagination

Pagination uses Kaminari with Bootstrap-styled templates located in `app/views/kaminari/`. The paginator position is configured via `Krudmin::Config.paginator_position` or per Resource Manager via `PAGINATOR_POSITION`.

## Confirmation Dialogs

Delete, activate, and deactivate actions use SweetAlert confirmation dialogs. The confirmation messages are I18n-translated from:

```yaml
krudmin:
  confirm_destroy: "Are you sure you want to delete %{label}?"
  confirm_activation: "Are you sure you want to activate %{label}?"
  confirm_deactivation: "Are you sure you want to deactivate %{label}?"
```

## I18n

All UI strings are translatable via `config/locales/en.yml`. Key namespaces:

```yaml
krudmin:
  dashboard: "Dashboard"
  search:
    contains: "Contains"
    equals: "Equals"
    # ...
  messages:
    created: "%{label} was successfully created"
    modified: "%{label} was successfully modified"
    # ...
  tooltips:
    new_resource: "Add New"
    edit_resource: "Edit"
    # ...
  actions:
    add: "Add"
    manage: "Manage"
    save: "Save"
    cancel: "Cancel"
    # ...
```
