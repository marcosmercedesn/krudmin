# Kanban Board Feature — Design Plan

This document captures the full design for a Kanban board view for Krudmin
ResourceManagers that manage models with AASM (or similar) state machine fields.
It is intended as a reference for future implementation.

---

## 1. Goals and Scope

Provide a drag-and-drop Kanban board as an optional, per-resource view alongside
the existing list (`index`) view. Key requirements:

- Drag cards between state columns; transitions persist via the existing
  `transition` action.
- Clicking a card opens a slide-over panel with the full edit/show form.
- Custom filtering (reuses the existing Ransack search infrastructure).
- WIP (work-in-progress) limits per column with visual indicators.
- Smooth, mobile-compatible UI (SortableJS + scroll-snap).
- Real-time multi-user sync via ActionCable (optional/progressive enhancement).
- Zero configuration for the common case; fully opt-in via a single constant.

Explicit v1 non-goals:

- No manual drag-reordering within a column. Column ordering follows the
  resource's existing `ORDER_BY` configuration.
- No swimlanes, nested grouping, or multi-board layouts.
- No keyboard drag-and-drop in v1. Keyboard-accessible state changes can be
  added later via buttons in the panel/card chrome.
- No automatic inference of complex workflow graphs when multiple events can
  reach the same target state unless an explicit mapping is provided.

---

## 2. ResourceManager Configuration API

Add one constant to any ResourceManager:

```ruby
KANBAN_BOARD = {
  # Required
  state_field: :status,           # AR column / AASM column

  # Required — at least one column
  columns: [
    { state: :draft,     label: "Backlog",   wip_limit: nil },
    { state: :submitted, label: "In Review", wip_limit: 10  },
    { state: :approved,  label: "Approved",  wip_limit: 5   },
    { state: :paid,      label: "Done",      wip_limit: nil },
  ],

  # Optional
  card_attributes:  [:name, :due_date, :assignee],  # defaults to first 4 listable_attributes
  per_column_limit: 20,                              # items fetched per column (default 20)
  includes:         [:assignee, :project],           # merged with LISTABLE_INCLUDES for board queries
  card_partial:     nil,                             # custom partial, defaults to "board_card"
  panel_action:     :edit,                           # :edit or :show
  transition_mode:  :event_first,                    # :event_first or :direct_write
  transition_events: {
    draft: :submit,
    submitted: { approved: :approve, rejected: :reject },
    approved: { paid: :pay }
  },
}.freeze
```

Enabling helpers derived from this constant (via `constantized_methods`):

| Method | Returns |
|---|---|
| `kanban_board_enabled?` | `true` when `KANBAN_BOARD` is present and non-empty |
| `kanban_state_field` | `:status` |
| `kanban_columns` | Array of column hashes |
| `kanban_card_attributes` | Array of attribute symbols for the card face |
| `kanban_per_column_limit` | Integer |

Recommended semantics for optional keys:

| Key | Purpose | Default |
|---|---|---|
| `includes` | Eager-loaded associations for board rendering | `[]` |
| `card_partial` | Override card rendering partial | `"board_card"` |
| `panel_action` | Which resource page loads in the slide-over | `:edit` |
| `transition_mode` | Prefer event resolution first, or always write the state field directly | `:event_first` |
| `transition_events` | Explicit current-state/target-state to event mapping | `nil` |

If `transition_events` is supplied, it takes precedence over any inferred event
resolution and should be treated as the source of truth for the board.

---

## 3. Routes

Add a `board` collection route alongside existing resource routes:

```ruby
resources :cars do
  member do
    post :activate
    post :deactivate
    post :transition
  end
  collection do
    get  :board
    post :bulk_destroy
    post :bulk_activate
    post :bulk_deactivate
  end
end
```

Routing helper: `board_admin_cars_path` → `GET /admin/cars/board`

Add `board` to `DEFINED_ACTION_METHODS` in `Krudmin::ResourceManagers::Routing`
and expose `board_path` / `board_route_path` from the router, then delegate and
`helper_method` it through `KrudminResourceManagerControllerSupport`.

The board should be exposed in the UI as a peer to `index`, not as a custom
action per row. Recommended integration:

- Add a toolbar button on list pages when `kanban_board_enabled?` and
  `board_route?` are both true.
- Add a reciprocal "List" button on the board page.
- Reuse the same controller/resource labels and breadcrumbs as `index`.

---

## 4. Controller — `board` Action

Add to `Krudmin::ApplicationController`:

```ruby
def board
  @board_columns = krudmin_manager.kanban_columns.map do |col|
    state_field = krudmin_manager.kanban_state_field
    base_scope  = items.result                          # respects search/filter
    col_scope   = base_scope.where(state_field => col[:state])

    {
      state:     col[:state],
      label:     col[:label].presence || col[:state].to_s.humanize,
      wip_limit: col[:wip_limit],
      items:     col_scope.limit(krudmin_manager.kanban_per_column_limit),
      total:     col_scope.count
    }
  end
end
```

`items` is already a `Krudmin::SearchForm`-backed scope, so filters from the
filter bar are automatically applied.

Implementation notes:

- `board` should follow the same authorization path as `index`: use
  `policy_scope` when Pundit is enabled, and expose `board_access?` by reusing
  the `index?` policy decision unless the app defines a dedicated `board?`
  helper later.
- Board queries should eager-load `LISTABLE_INCLUDES + KANBAN_BOARD[:includes]`
  to avoid card-level N+1 queries.
- Column record ordering should follow `ORDER_BY`; drag-and-drop changes state,
  not rank. This keeps v1 consistent with the existing list semantics.
- Extract the board query building into a private method such as
  `kanban_relation` or `build_board_columns` so the same logic can be reused by
  Turbo Stream refreshes and ActionCable broadcasts.
- Add a database index on the state field, and consider a composite index on
  `[state_field, first_order_column]` for larger tables.

---

## 5. Drag-and-Drop Mechanics (SortableJS)

### Vendor file

SortableJS 1.15.6 UMD minified build (`sortable.js`).
Place at: `app/assets/javascripts/krudmin/vendor/sortable.js`
Add to `JS_SOURCES` in `Krudmin::AssetBuilder` just after `sweetalert.js`.

The UMD wrapper assigns `window.Sortable` when no module system is present,
which is correct for the concatenated-bundle strategy.

### `kanban-board` Stimulus controller

```
app/assets/javascripts/krudmin/controllers/kanban_board_controller.js
```

```js
KrudminApp.register("kanban-board", class extends Stimulus.Controller {
  static targets = ["list", "card", "column"];
  static values  = { transitionBaseUrl: String, resource: String };

  connect() {
    this.sortables = [];
    this.listTargets.forEach((list) => {
      const s = Sortable.create(list, {
        group:       this.resourceValue + "-cards",
        animation:   150,
        ghostClass:  "krudmin-board-card--ghost",
        dragClass:   "krudmin-board-card--drag",
        onEnd: (event) => this.onDrop(event),
      });
      this.sortables.push(s);
    });
  }

  disconnect() {
    this.sortables.forEach((s) => s.destroy());
    this.sortables = [];
  }

  onDrop(event) {
    const cardId   = event.item.dataset.cardId;   // on the turbo-frame, not inner div
    const toState  = event.to.dataset.state;       // on the .krudmin-board-column-body
    const fromState = event.from.dataset.state;
    if (toState === fromState) return;

    const url  = this.transitionBaseUrlValue + "/" + cardId + "/transition";
    const csrf = (document.querySelector('meta[name="csrf-token"]') || {}).content || "";

    const body = new FormData();
    body.append("force_state",        toState);
    body.append("context",            "kanban");
    body.append("authenticity_token", csrf);

    fetch(url, {
      method:  "POST",
      headers: { Accept: "text/vnd.turbo-stream.html" },
      body,
    }).then((res) => {
      if (res.ok) return res.text().then((html) => Turbo.renderStreamMessage(html));
      event.from.appendChild(event.item);          // rollback on failure
    }).catch(() => event.from.appendChild(event.item));
  }
});
```

**Critical detail:** `data-card-id` must be on the draggable root element
(the `turbo-frame`), **not** on any inner div, because `event.item` is the
direct child of the SortableJS list container.

---

## 6. Slide-Over Panel (kanban-panel Stimulus Controller)

```
app/assets/javascripts/krudmin/controllers/kanban_panel_controller.js
```

The `kanban-panel` controller must be registered on a **common ancestor** of
both the board columns and the panel markup. Register both controllers on the
same root element:

```haml
.krudmin-board-root{data: { controller: "kanban-board kanban-panel", ... }}
  .krudmin-board
    = render partial: "board_column", ...
  .krudmin-board-panel-backdrop{data: { "kanban-panel-target": "backdrop", action: "click->kanban-panel#close" }}
  .krudmin-board-panel{data: { "kanban-panel-target": "panel" }}
    ...
    %turbo-frame#board-modal.krudmin-board-panel-body
```

Stimulus routes `data-action="click->kanban-panel#open"` on card bodies only
when the controller's element is an ancestor of those cards. Sibling placement
breaks event delegation.

```js
KrudminApp.register("kanban-panel", class extends Stimulus.Controller {
  static targets = ["panel", "backdrop"];

  open(event) {
    const url = event.currentTarget.dataset.cardUrl;
    if (!url) return;
    document.getElementById("board-modal").src = url;
    this.panelTarget.classList.add("is-open");
    this.backdropTarget.classList.add("is-open");
  }

  close() {
    this.panelTarget.classList.remove("is-open");
    this.backdropTarget.classList.remove("is-open");
    const frame = document.getElementById("board-modal");
    if (frame) { frame.src = ""; frame.innerHTML = ""; }
  }
});
```

---

## 7. State Transition — `force_state` Support

The drag handler cannot always know the correct AASM event name; it only knows
the target state. Add `force_state` support to `TransitionHandler`:

```ruby
def valid?
  if params[:force_state].present?
    model.update_column(force_state_field, params[:force_state])
  else
    method_name = "#{event_name}!"
    return false unless model.respond_to?(method_name)
    model.public_send(method_name)
  end
rescue StandardError => error
  model.errors.add(:base, error.message) if model.respond_to?(:errors)
  false
end

def force_state_field
  params.fetch(:state_field, krudmin_manager.kanban_state_field).to_sym
rescue KeyError
  :status
end
```

Recommended transition resolution order:

1. If `KANBAN_BOARD[:transition_events]` defines a mapping for the current
  state and target state, use that event.
2. Else, if the resource's `StateMachine` field metadata exposes a unique event
  that reaches the target state, use that event.
3. Else, only fall back to direct state writes when
  `KANBAN_BOARD[:transition_mode] == :direct_write`.
4. If no unique event can be resolved and direct writes are disabled, reject
  the drop and render an error toast.

This is a better default than always using `update_column`, because Krudmin's
workflow support already models transitions as events and apps may depend on
their guards, validations, or side effects.

**Note:** `update_column` skips validations and callbacks. For apps that need
validations on state change, direct writes should be opt-in only.

---

## 8. Turbo Stream Response

`app/views/krudmin/core_theme/board.turbo_stream.erb`:

```erb
<%= turbo_stream.replace "kanban-column-#{params[:from_state]}" do %>
  <%= render "board_column", column: @source_column %>
<% end %>
<%= turbo_stream.replace "kanban-column-#{params[:to_state]}" do %>
  <%= render "board_column", column: @target_column %>
<% end %>
<%= turbo_stream.replace "kanban-card-#{model_id}" do %>
  <%= render(krudmin_manager.kanban_card_partial || "board_card", card_item: model) %>
<% end %>
<turbo-stream action="toast" type="success"
  message="<%= transitioned_message(params[:event] || params[:force_state]) %>">
</turbo-stream>
<turbo-stream action="init_controls"></turbo-stream>
```

The `turbo_stream_response` in `ValidListContext` must render `"board"` when
`params[:context] == "kanban"`, otherwise fall back to `"transition"`.

Refreshing whole source/target columns is safer than replacing only the moved
card because it keeps these values correct without extra client bookkeeping:

- column counters and WIP badges
- empty-column placeholders
- per-column truncation (`per_column_limit`)
- card order after applying `ORDER_BY`

Panel save behavior should use the same principle:

- On successful edit inside the slide-over, re-render the affected card.
- If the saved record changed state, re-render both old and new columns.
- Preserve the panel open state for validation failures; close it only after a
  successful save when the response came from the board context.

---

## 9. Real-Time Multi-User Sync (ActionCable — Optional)

```ruby
# app/channels/krudmin/kanban_board_channel.rb
module Krudmin
  class KanbanBoardChannel < ActionCable::Channel::Base
    def subscribed
      stream_from "krudmin_kanban_#{params[:resource]}_#{params[:board_key]}"
    end
  end
end
```

On successful drag, broadcast column-level refresh payloads instead of only the
card HTML when possible. That keeps counters, placeholders, and ordering in
sync across clients.

Recommended payload shape:

```json
{
  "type": "kanban_refresh",
  "record_id": 42,
  "from_state": "submitted",
  "to_state": "approved"
}
```

The subscriber can then request or receive Turbo Stream fragments for the two
affected columns. This keeps the browser logic thin and aligned with the
server-rendered source of truth.

This is a progressive enhancement — the board works without ActionCable.

---

## 10. Filter Bar

Reuse the existing Ransack `SearchForm`. Render a compact horizontal filter bar
above the board using `simple_form_for(search_form, url: board_path)`.

The `board` action calls `items.result` which already applies the active
search scope, so filters work with zero extra code.

Reset URL: `board_path(reset_search: 1)` — handled by the existing
`Krudmin::Searchable` concern.

The board and list views should intentionally share the same persisted search
state. A user filtering `Cars` in the list should see the same filtered subset
when switching to the board, and vice versa.

Board-specific UI state such as the currently open panel, horizontal scroll
position, or collapsed filter bar should not be stored in the existing search
cookie; keep those as client-only concerns.

---

## 11. Authorization, Navigation, and Audit Behavior

Authorization expectations:

- Visiting the board should require the same policy access as `index`.
- Dragging a card should require transition permission for that record.
- When the app implements event-specific policies such as
  `transition_approve?`, event-based resolution should honor them.
- If the implementation falls back to direct state writes, authorization should
  still require the generic `transition?` or a board-specific predicate to
  avoid bypassing event-level access control.

Navigation expectations:

- The board button belongs in the page toolbar, not the row action panel.
- The board should use the same breadcrumb root and resource labels as `index`.
- The board page title should remain resource-centric, e.g. `"Cars Board"`.

Audit expectations:

- Event-driven transitions should flow through Krudmin's existing transition
  audit path and keep the event name in metadata.
- If direct writes are used, the audit trail should still record a transition
  entry with `from_state`, `to_state`, and `context: "kanban"` in metadata.
- Panel-based edits from the board should be recorded as ordinary updates; only
  state changes should be recorded as transitions.

---

## 12. WIP Limits

Each column tracks `total` (the full unfiltered count for that state) and
`items` (paginated to `per_column_limit`). The column header badge shows:

- `total / wip_limit` in danger red when `total > wip_limit`
- `total` in secondary grey otherwise
- Nothing when `wip_limit` is `nil`

WIP enforcement (blocking drops) is not implemented by default — the visual
indicator is sufficient for most use cases.

Recommended counting semantics:

- `total` should count the full filtered relation for that state, not only the
  records currently rendered under `per_column_limit`.
- The badge should reflect the filtered board state the user is looking at,
  not the global unfiltered count; otherwise the numbers feel inconsistent when
  search is active.

---

## 13. CSS Architecture

File: `app/assets/stylesheets/krudmin/board.scss`
Import in: `app/assets/stylesheets/krudmin/core_theme/application.scss`

Key layout rules:

```scss
// Board root — scope anchor for both Stimulus controllers
.krudmin-board-root { position: relative; }

// Horizontal scrolling column strip
.krudmin-board {
  display: flex;
  flex-wrap: nowrap;
  gap: 1rem;
  overflow-x: auto;
  align-items: flex-start;
  -webkit-overflow-scrolling: touch;
  scroll-snap-type: x mandatory;
}

// Fixed-width columns
.krudmin-board-column {
  flex: 0 0 320px;
  background: var(--bs-light, #f8f9fa);
  border: 1px solid var(--bs-border-color, #dee2e6);
  border-radius: 0.5rem;
  scroll-snap-align: start;
}

// Cards look like Trello/Jira cards
.krudmin-board-card {
  background: #fff;
  border: 1px solid rgba(0,0,0,0.08);
  border-radius: 0.375rem;
  box-shadow: 0 1px 3px rgba(0,0,0,0.06);
  cursor: grab;
}

// Slide-over panel — toggled by .is-open on individual elements
.krudmin-board-panel {
  position: fixed;
  top: 0; right: 0; bottom: 0;
  width: 480px;
  transform: translateX(100%);
  transition: transform 0.3s cubic-bezier(0.4,0,0.2,1);
  z-index: 1051;
  &.is-open { transform: translateX(0); }
}
.krudmin-board-panel-backdrop {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.4);
  opacity: 0; pointer-events: none;
  z-index: 1050;
  transition: opacity 0.3s ease;
  &.is-open { opacity: 1; pointer-events: auto; }
}
```

**Important:** Do **not** put `overflow: hidden` on any wrapper element that
contains `.krudmin-board`. It will clip the horizontal scroll and hide columns
beyond the viewport.

Additional UI details worth standardizing:

- Render an explicit empty-state block inside empty columns so drop zones stay
  visible and understandable.
- Make the whole card draggable, but reserve a clearly clickable content area
  for opening the panel.
- Use `touch-action: pan-x pan-y` carefully so touch dragging does not fight
  horizontal board scrolling on mobile.
- Keep column widths fixed in v1; responsive behavior should come from the
  scroll container, not shrinking columns below card readability.

---

## 14. View Files

| File | Purpose |
|---|---|
| `app/views/krudmin/core_theme/board.html.haml` | Main board page |
| `app/views/krudmin/core_theme/_board_column.html.haml` | Single column partial |
| `app/views/krudmin/core_theme/_board_card.html.haml` | Single card partial |
| `app/views/krudmin/core_theme/_board_filter_bar.html.haml` | Compact filter form |
| `app/views/krudmin/core_theme/board.turbo_stream.erb` | Turbo Stream after card move |

Suggested DOM contract:

- Column wrapper IDs: `kanban-column-<state>`
- Card wrapper IDs: `kanban-card-<id>`
- Sortable drop zone data: `data-state="approved"`
- Panel frame ID: `board-modal`

These IDs make Turbo Stream replacement and system tests deterministic.

---

## 15. Generator

```bash
rails generate krudmin:kanban_board ModelName
```

Injects a `KANBAN_BOARD` constant into the ResourceManager and adds
`collection { get :board }` to the routes file. Reads AASM states from the
model automatically to pre-populate columns.

Generator refinements worth adding:

- If the model has a `StateMachine` field config already, seed
  `transition_events` from it when possible.
- If the model uses `enum` without AASM, warn that direct writes are the only
  safe default unless the user provides explicit event mappings.
- Offer a `--panel show|edit` option so generated defaults match the intended
  UX.

---

## 16. Known Implementation Gotchas

### data-card-id placement
`event.item` in SortableJS is the **direct child** of the sortable list
container. If `data-card-id` is on an inner div rather than the outermost
draggable element (the `turbo-frame`), `event.item.dataset.cardId` will be
`undefined` and no transition will fire.

### Stimulus controller scope
Stimulus routes actions only to a controller that **contains** the element
firing the action. The `kanban-panel` controller must be an ancestor of all
card bodies. If it is placed as a sibling of the board, clicks on cards will
never reach it. Register both `kanban-board` and `kanban-panel` on the same
root wrapper element.

### overflow: hidden breaks horizontal scroll
Bootstrap's `.container-fluid` and any custom wrapper with `overflow: hidden`
will clip the `.krudmin-board` flex row, making columns past the first viewport
width invisible. The board's root element must have `overflow: visible` or
use `overflow-x: auto` directly.

### SortableJS UMD global name
The vendored UMD build assigns `window.Sortable` (capital S). Reference it as
`Sortable.create(...)` in the controller. In `typeof` checks use
`typeof Sortable !== 'undefined'`.

### force_state vs AASM events
`update_column` used for `force_state` skips AASM guards, validations, and
callbacks. For models where state transitions have side effects (emails,
webhooks, audit log), map the target state back to the appropriate AASM event
and call `model.send("#{event}!")` instead.

### column counts drift if only the card is replaced
Replacing only the card Turbo Frame after a move is not enough. The source and
target column headers, placeholders, and `per_column_limit` windows can become
wrong. Refresh the affected columns, not just the moved card.

### policy checks can diverge from drag behavior
If the board uses direct state writes while the rest of the app uses event-based
policy methods such as `transition_approve?`, drag-and-drop can bypass the
intended authorization granularity. Prefer event resolution first.

---

## 17. Testing and Operational Checklist

Recommended test coverage:

- ResourceManager helper tests for `kanban_*` methods and configuration
  fallbacks.
- Routing tests for `board_path` and `board_route?`.
- Controller/request tests for `GET /board` with and without filters.
- Transition handler tests covering event resolution, direct-write fallback,
  authorization failure, and invalid transitions.
- Feature specs for:
  - board page renders columns and cards
  - filters persist across list/board switching
  - clicking a card opens the panel
  - saving inside the panel refreshes card/column state
  - drag move succeeds and updates both columns
  - unauthorized users cannot access the board or drag cards

Operational checklist:

- Add an index on the state field.
- Rebuild the Krudmin asset bundle after adding new JS/CSS sources.
- Hard-refresh the browser after bundle changes during development.
- Confirm board views work both with and without `REMOTE_CRUD`.
- Confirm audit entries and policy checks behave correctly for board-driven
  transitions.

---

## 18. Phased Delivery

| Phase | Scope |
|---|---|
| **1 — Read-only board** | `board` action, views, column/card layout, filter bar, WIP badge |
| **2 — Drag-and-drop** | SortableJS vendor, `kanban-board` controller, event-first transition resolution, Turbo Stream response |
| **3 — Slide-over panel** | `kanban-panel` controller, panel HAML, edit form loading via Turbo Frame |
| **4 — Real-time sync** | ActionCable channel, JS consumer, broadcast on move |
| **5 — Generator** | `krudmin:kanban_board` generator |
