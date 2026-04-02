# Audit Trail / Activity Logging

Krudmin includes an opt-in audit trail that automatically tracks create, update, destroy, activate, deactivate, and transition events with user attribution and attribute diffs.

## Quick Start

### 1. Run the generator

```bash
rails generate krudmin:audit
```

This creates the migration and enables audit in your initializer.

### 2. Run migrations

```bash
rails db:migrate
```

That's it — audit is now active for all Krudmin-managed resources.

## How It Works

The `Krudmin::Auditable` concern (automatically included in `Krudmin::ApplicationController`) uses `around_action` to:

1. Capture `model.changes` **before** the save
2. Yield to the action (create/update/destroy/etc.)
3. Record `model.previous_changes` **after** the save succeeds

Each audit entry stores:
- **Who** — the current user (polymorphic)
- **What** — the model and action performed
- **When** — timestamp
- **Changes** — attribute diffs as `{ field: [old_value, new_value] }`
- **Metadata** — controller, action, IP address, transition event name

## Configuration

```ruby
Krudmin::Config.with do |config|
  # Enable/disable audit globally
  config.audit_enabled = true

  # Backend: :krudmin (built-in DB), :paper_trail, or :custom
  config.audit_backend = :krudmin

  # Attributes to never audit (global)
  config.audit_excluded_attributes = %i[updated_at created_at password_digest]
end
```

## Backends

### Built-in (`:krudmin`)

Stores audit entries in the `krudmin_audit_entries` table. This is the default when you run the generator.

```ruby
config.audit_backend = :krudmin
```

### PaperTrail (`:paper_trail`)

Read-only adapter that queries PaperTrail's `versions` table. PaperTrail handles recording automatically via model callbacks — Krudmin only reads the data for display.

```ruby
config.audit_backend = :paper_trail
```

Requirements:
- `paper_trail` gem in your Gemfile
- Models must include `has_paper_trail`

### Custom (`:custom`)

Delegate recording and querying to your own implementation via procs:

```ruby
config.audit_backend = :custom

config.audit_recorder = ->(payload) {
  MyAuditService.track(
    event: payload[:action],
    resource: "#{payload[:auditable_type]}##{payload[:auditable_id]}",
    user_id: payload[:user_id],
    changes: payload[:changes]
  )
}

config.audit_entries_provider = ->(record, limit:) {
  MyAuditService.entries_for(record).limit(limit).map do |entry|
    OpenStruct.new(
      action: entry.event,
      changes_json: entry.diff.to_json,
      user_label: entry.actor_name,
      action_label: entry.event.humanize,
      created_at: entry.timestamp,
      parsed_changes: entry.diff
    )
  end
}
```

### Custom Backend Class

You can also pass a class that inherits from `Krudmin::Audit::BaseBackend`:

```ruby
class MyBackend < Krudmin::Audit::BaseBackend
  def record(payload)
    # Store the audit entry
  end

  def entries_for(record, limit: 25)
    # Return an array of entry objects
  end
end

config.audit_backend = MyBackend
```

## Per-Resource Exclusions

Exclude specific attributes from audit on a per-resource basis:

```ruby
class UsersResourceManager < Krudmin::ResourceManagers::Base
  AUDIT_EXCLUDED_ATTRIBUTES = [:password_digest, :reset_password_token, :encrypted_password]

  # ...
end
```

These are merged with the global `audit_excluded_attributes` from Config.

## Activity Panel

When audit is enabled, the **show** page automatically displays a collapsible "Activity Log" panel below the resource attributes. Each entry shows:

- Timestamp
- User who made the change
- Action badge (color-coded: green=create, blue=update, red=destroy, etc.)
- Expandable attribute diff (field name, old value → new value)

## Programmatic Access

You can also use the audit module directly:

```ruby
# Record an audit entry manually
Krudmin::Audit.record(
  event: :custom_event,
  record: @order,
  user: current_user,
  changes: { "status" => ["pending", "shipped"] },
  metadata: { reason: "Manual override" }
)

# Query audit entries for a record
entries = Krudmin::Audit.entries_for(@order, limit: 50)
```

## I18n

Audit action labels can be customized via I18n:

```yaml
en:
  krudmin:
    audit:
      activity_log: "Activity Log"
      field: "Field"
      from: "From"
      to: "To"
      no_activity: "No activity recorded yet."
      n_fields_changed:
        one: "1 field changed"
        other: "%{count} fields changed"
      actions:
        create: "Created"
        update: "Updated"
        destroy: "Deleted"
        activate: "Activated"
        deactivate: "Deactivated"
        transition: "Transitioned"
```

## Database Schema

The `krudmin_audit_entries` table:

| Column | Type | Description |
|--------|------|-------------|
| `auditable_type` | string | Polymorphic model class |
| `auditable_id` | integer | Polymorphic model ID |
| `user_type` | string | Polymorphic user class (nullable) |
| `user_id` | integer | Polymorphic user ID (nullable) |
| `action` | string | create, update, destroy, activate, deactivate, transition |
| `changes_json` | text | JSON-serialized `{ field: [old, new] }` |
| `metadata` | text | JSON-serialized context (controller, IP, etc.) |
| `created_at` | datetime | When the action occurred |

Indexes: `(auditable_type, auditable_id)`, `(user_type, user_id)`, `action`, `created_at`.
