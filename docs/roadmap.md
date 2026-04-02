# Krudmin Roadmap & Improvement Recommendations

Generated: 2026-03-31
Updated: 2026-04-01

## High Impact, Low Effort

### 1. Fix existing deprecations

Quick wins that prevent breakage on upgrades:

- `include Pundit` → `include Pundit::Authorization` in `authorizable.rb` (already warning)
- `factory_girl` reference in `engine.rb` → `factory_bot`
- Poltergeist/PhantomJS in test setup is dead — switch to `cuprite` or `selenium`
- `to_s(:format)` patterns in the codebase (not just specs) will break on Ruby 3.4+

### 2. CSV/Excel export & import

Every admin panel needs this. Export: a simple `index.csv.erb` response with a download button in the toolbar. Import: a CSV upload endpoint that maps columns to model attributes with validation and error reporting.

Export is low effort; import is medium effort but critical for CRM/ERP onboarding (migrating existing data from spreadsheets).

## High Impact, Medium Effort

### 4. ResourceManager validation at boot time

Right now, if you misconfigure a ResourceManager (wrong model name, missing association, bad attribute type), you get cryptic errors at request time. Adding a validation step that runs on boot and raises clear error messages would save developers hours of debugging:

```ruby
# Validate on app boot
Krudmin::ResourceManagers::Base.descendants.each(&:validate!)
```

Check: MODEL_CLASSNAME exists, ATTRIBUTE_TYPES reference valid fields, associations have `accepts_nested_attributes_for`, etc.

### 5. Custom actions beyond CRUD

ERPs need domain-specific operations: "Generate Invoice from Order," "Convert Lead to Customer," "Clone Record," "Send Email," "Mark as Paid." The current action button system only supports show/edit/destroy/activate. A custom action DSL would unlock business logic:

```ruby
class OrdersResourceManager < Krudmin::ResourceManagers::Base
  custom_action :generate_invoice, label: "Generate Invoice", icon: :file_text,
                confirm: "Generate invoice for this order?",
                method: :post, class: "btn-success"

  custom_action :clone, label: "Clone", icon: :copy, method: :post

  LISTABLE_ACTIONS = [:show, :edit, :generate_invoice, :clone, :active, :destroy]
end
```

Each custom action maps to a controller method the host app defines.

### 6. Audit trail / activity logging

Business systems need "who changed what, when." An audit concern that automatically tracks create/update/destroy events with user attribution:

```ruby
# config/initializers/krudmin.rb
config.audit_enabled = true
config.audit_backend = :paper_trail  # or :audited, or :custom

# In views: a collapsible "Activity" panel on show pages
# showing recent changes with diffs
```

### 8. Relational navigation

CRMs need "show me all Orders for this Customer" with linked views. Currently each resource is isolated. A related-records panel on show pages would connect the data:

```ruby
class CustomersResourceManager < Krudmin::ResourceManagers::Base
  RELATED_RESOURCES = {
    orders: { label: "Orders", scope: ->(customer) { Order.where(customer: customer) } },
    invoices: { label: "Invoices", scope: ->(customer) { Invoice.where(customer: customer) } }
  }
end
```

Renders as tabbed tables on the show page with links to each related record.

## Modernization (High Impact, High Effort)

### 9. Remove remaining jQuery usage

Turbo Streams, Stimulus controllers, and Trix are all integrated. jQuery remains only because Select2 and daterangepicker are jQuery plugins. The remaining work is:

- Replace **Select2** with a vanilla JS alternative (Tom Select, Slim Select, or Choices.js)
- Replace **daterangepicker** with a vanilla JS date picker
- Remove `jquery-rails` gem dependency

### 10. File attachments (Active Storage)

CRMs need document uploads on records (contracts, images, invoices). A `:File` or `:Attachment` field type backed by Active Storage:

```ruby
ATTRIBUTE_TYPES = {
  avatar: :Image,           # Single image with preview
  contract: :Attachment,    # Single file with download link
  documents: :Attachments   # Multiple files
}
```

### 11. Multi-tenancy support

ERPs typically scope data per organization/tenant. A built-in scoping mechanism:

```ruby
# config/initializers/krudmin.rb
config.tenant_scope = ->(user) { { organization_id: user.organization_id } }

# Automatically applied to all queries, form defaults, and authorization
```

## Developer Experience

### 13. Configurable per-resource overrides without subclassing

Right now, customizing a controller action requires overriding the method. A hooks/callbacks system would be cleaner:

```ruby
class CarsResourceManager < Krudmin::ResourceManagers::Base
  before_create { |model| model.created_by = current_user }
  after_destroy { |model| AuditLog.record(:destroy, model) }

  # Scope visible records
  scope { |user| user.admin? ? model_class.all : model_class.where(team: user.team) }
end
```

### 14. API mode

The `_form.json.erb` and `index.json.erb` exist but are minimal. A proper API mode with JSON serialization, pagination metadata, and filtering would allow the admin to be used as a backend for custom frontends (React, mobile apps).

## Recommended Priority Order

| Priority | Item | Why |
|----------|------|-----|
| 1 | Fix deprecations (#1) | Prevents breakage, zero risk |
| 2 | ResourceManager validation (#4) | Biggest DX pain point |
| 3 | CSV/Excel export & import (#2) | Small effort, high value, CRM essential |
| 5 | Custom actions (#5) | Unlocks business logic beyond CRUD |
| 6 | Audit trail (#6) | Business compliance requirement |
| 7 | Relational navigation (#8) | Makes data browsing feel like a CRM |
| 9 | File attachments (#10) | Document management |
| 10 | Remove jQuery (#9) | Modernization, smaller bundle |
| 11 | Multi-tenancy (#11) | SaaS/enterprise requirement |
| 13 | Callbacks/hooks (#13) | Cleaner customization |
| 14 | API mode (#14) | Custom frontend support |

## CRM/ERP Readiness Assessment

Krudmin today is a **solid admin panel generator**. To become a viable CRM/ERP framework, items #2–#8 are the critical path. They transform krudmin from "CRUD with a nice UI" into "a platform you can build business applications on."

The architecture supports this evolution — the ResourceManager pattern, presenter system, and Stimulus controllers are well-structured for extension. The gap is in domain-specific features (workflows, dashboards, audit, related records) that business applications require beyond basic CRUD.
