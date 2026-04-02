# Workflow / State Machine Support (AASM)

Krudmin supports workflow transitions through a `StateMachine` field type backed by [AASM](https://github.com/aasm/aasm).

## 1. Model setup (AASM)

```ruby
class Order < ApplicationRecord
  include AASM

  enum :status, {
    draft: 0,
    submitted: 1,
    approved: 2,
    rejected: 3,
    paid: 4,
  }

  aasm column: :status, enum: true do
    state :draft, initial: true
    state :submitted, :approved, :rejected, :paid

    event(:submit)  { transitions from: :draft, to: :submitted }
    event(:approve) { transitions from: :submitted, to: :approved }
    event(:reject)  { transitions from: :submitted, to: :rejected }
    event(:pay)     { transitions from: :approved, to: :paid }
  end
end
```

## 2. ResourceManager setup

```ruby
ATTRIBUTE_TYPES = {
  status: {
    type: :StateMachine,
    transitions: {
      draft: [:submit],
      submitted: [:approve, :reject],
      approved: [:pay],
      rejected: [:submit],
      paid: []
    },
    transition_labels: {
      submit: "Submit",
      approve: "Approve",
      reject: "Reject",
      pay: "Mark as Paid"
    },
    colors: {
      draft: :secondary,
      submitted: :warning,
      approved: :success,
      paid: :info,
      rejected: :danger
    }
  }
}
```

Add `:status` to `LISTABLE_ATTRIBUTES` and `DISPLAYABLE_ATTRIBUTES` to render badges and transition buttons.

## 3. Route setup

```ruby
resources :orders do
  member { post :transition }
end
```

Krudmin handles transition execution via `Krudmin::ApplicationController#transition`.

## 4. Authorization (Pundit)

Use either:

- `transition?` for generic transition checks
- `transition_<event>?` for event-specific checks (e.g., `transition_approve?`)

## 5. Generator

```bash
rails generate krudmin:state_machine Order
```

This creates a workflow concern scaffold and integration instructions.
