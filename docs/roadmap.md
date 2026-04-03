# Krudmin Roadmap & Improvement Recommendations

Generated: 2026-03-31
Updated: 2026-04-02

## Cross-Product Readiness (Framework Assessment)

This section focuses on Krudmin as a framework used to build many kinds of products:

- CRMs
- member/community management systems
- back-office/admin tools
- invoicing and operations portals
- internal ERPs and workflow-heavy dashboards

### Current Baseline in Codebase

What is already strong enough to build on:

- ResourceManager-driven CRUD, search, list/show/form views, and authorization hooks
- workflow/state transitions (AASM-backed `StateMachine` field and transition actions)
- custom member actions (resource-level `custom_action` DSL + action buttons)
- audit trail/activity logging
- dashboards and dashboard scopes/columns
- Turbo/remote CRUD flows for faster operator workflows

What is still required for production-grade apps across domains:

- accounting primitives (ledger-grade money tracking, recurring billing, reconciliation)
- document output pipeline (PDF generation, batch print jobs, card templates)
- QR identity and secure validation flows
- stronger tenancy and data boundaries (if multi-organization)
- integrations (payments, email/SMS, accounting tools)

## Recommended Framework Features Before Building Products on Krudmin

### Phase 1: Platform Foundation (implement first)

### F1. Domain Starter Packs (generator presets)

Create optional starter packs by vertical so teams bootstrap faster while still using the same framework core. Example packs:

- CRM pack: `Lead`, `Account`, `Contact`, `Opportunity`, `PipelineStage`, `Task`
- Member pack: `Member`, `MembershipPlan`, `Subscription`, `Donation`, `Event`, `Attendance`
- Admin/Ops pack: `Invoice`, `Payment`, `Project`, `Budget`, `Document`, `Approval`

Why first: this keeps Krudmin generic while drastically reducing time-to-first-product.

### F2. Billing Toolkit (Recurring, Usage, and Ledger-safe primitives)

Implement reusable billing primitives for many products: recurring charges, proration, grace periods, penalties, write-offs, and dunning states.

Minimum behavior:

- automatic invoice issuance per active subscription or contract
- ledger-safe money fields (`amount_cents`, `currency`)
- partial payment support
- overdue transitions + reminders

### F3. Funds/Payments Extensions

Support patterns that many apps need (donations, grants, sponsorships, deposits):

- one-time and recurring transactions
- campaign/fund/allocation tagging
- receipt numbering + PDF receipts
- configurable compliance tags

### F5. Document Output + QR Toolkit

Add a reusable document pipeline:

- signed payloads for QR content (not raw IDs)
- printable PDF templates (single and batch)
- template variables and theming
- document revocation/reissue/version history

### F6. ResourceManager Validation at Boot (#4)

Keep this high priority. Misconfigured resources can break critical product workflows.

### Phase 2: Product Builder Efficiency (next)

### F7. Bulk Import/Export with Validation (#2 extended)

Import entities and historical transactions from spreadsheets with:

- preview + column mapping
- row-level validation report
- idempotency key for re-import safety

### F8. Relational Navigation (#8)

For each primary resource, surface related-record panels (tabs/sections) such as:

- invoices/payments
- contacts/activities/tasks
- documents/notes/audit
- events/attendance/subscriptions

### F9. Planning + Budgeting Module

Implement reusable planning lifecycle:

- planned budget vs actual spend (variance)
- approval workflow for budget lines
- registration caps and waitlists
- attendance check-in and export

### F10. Communications Hub

Add campaign-capable messaging:

- email/SMS/WhatsApp queueing hooks
- audience segmentation from search filters
- reminder templates (due, overdue, event, follow-up reminders)

### Phase 3: Scale and Productization

### F11. Multi-tenancy + Role Matrix (#11)

If this will be sold or reused by multiple organizations, implement strict tenant scoping plus role-based permissions (admin, treasurer, event coordinator, read-only, etc.).

### F12. API Mode + Webhooks (#14 expanded)

Expose stable APIs and outbound webhooks for:

- payment received
- state changed
- document issued/overdue
- workflow transition completed

### F13. Remove Legacy jQuery Dependencies (#9)

Do this after business-critical modules are stable, unless front-end modernization is required early by your team.

## Additional Framework Recommendations

### 1. Financial Controls

- immutable posted transactions (corrections via reversal entries)
- period close and lock
- reconciliation workflow for bank/cashbox

### 2. Compliance and Security

- PII masking in lists and exports
- retention/anonymization tooling
- stronger authentication options (MFA-ready)
- signed URL expiry for exported sensitive documents

### 3. Usability and Operations

- saved views/filters by role
- global search across primary entities and transactions
- keyboard-first operator shortcuts
- queue and background job dashboards (failed exports, failed card batches)

### 4. Reporting and KPIs

- recurring revenue and collection rate metrics
- lifecycle conversion/churn/reactivation metrics
- campaign and workflow conversion metrics
- budget variance and participation/usage trends

## Recommended Priority Order for Framework Evolution

| Priority | Item | Why |
|----------|------|-----|
| 1 | F1 Domain starter packs | Reusable accelerators across verticals |
| 2 | F2 Billing toolkit | Common revenue workflow building block |
| 3 | F5 Document + QR toolkit | Reusable output/identity/document capability |
| 4 | F6 ResourceManager validation | Prevents runtime failures in critical flows |
| 5 | F7 Import/export | Faster onboarding from legacy spreadsheets |
| 6 | F8 Relational navigation | Better operator productivity |
| 7 | F9 Planning/budgeting | Supports operations-heavy products |
| 8 | F10 Communications hub | Improves collections and engagement |
| 9 | F11 Multi-tenancy + role matrix | Required for multi-org deployments |
| 10 | F12 API + webhooks | Integration and automation |

## Existing Roadmap Items (General Platform)

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

Status update: the custom action DSL now exists and should be considered a platform capability. Focus should shift to domain-specific action libraries (invoicing, donation receipts, reminders, card lifecycle).

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
| 4 | Custom actions (#5) | Unlocks business logic beyond CRUD |
| 5 | Relational navigation (#8) | Makes data browsing feel like a CRM |
| 6 | File attachments (#10) | Document management |
| 7 | Remove jQuery (#9) | Modernization, smaller bundle |
| 8 | Multi-tenancy (#11) | SaaS/enterprise requirement |
| 9 | Callbacks/hooks (#13) | Cleaner customization |
| 10 | API mode (#14) | Custom frontend support |

## CRM/ERP Readiness Assessment

Krudmin today is a **solid admin panel generator**. To become a viable CRM/ERP framework, items #2–#8 are the critical path. They transform krudmin from "CRUD with a nice UI" into "a platform you can build business applications on."

The architecture supports this evolution — the ResourceManager pattern, presenter system, and Stimulus controllers are well-structured for extension. The gap is in domain-specific features (workflows, dashboards, related records, and deeper business modules) that business applications require beyond basic CRUD.

## Framework Readiness Summary

Krudmin is already a strong base framework. The best next step is to invest in reusable platform modules that repeatedly benefit every product built on top of it (validation, billing primitives, import/export, relational navigation, document output, and integrations), rather than implementing one product directly inside the framework.
