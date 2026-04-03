# Integration Test Suite Generator

The `krudmin:integration_specs` generator creates a complete, ready-to-use integration test suite for a Krudmin resource using Capybara and RSpec. This enforces testing best practices and eliminates boilerplate.

## Overview

This generator scaffolds:
- **Page Object** — Reusable page class with resource-specific helpers
- **CRUD Specs** — Create, read, update, destroy tests
- **State Transition Specs** — Activate, deactivate, and bulk action tests
- **Search & Filter Specs** — Test search and filtering behavior (optional)
- **Pagination Specs** — Test pagination (optional)
- **Inline Editing Specs** — Test inline field editing (optional)
- **Nested Forms Specs** — Test HasMany/HasOne nested forms (optional)
- **FactoryBot Factory** — Basic factory with standard traits
- **Page Features Helpers** — Reusable Capybara helper methods

## Installation

The generator is part of Krudmin. No additional setup required.

## Usage

### Basic Usage

```bash
rails generate krudmin:integration_specs Car
```

This generates:
```
spec/support/pages/car_page.rb
spec/features/cars/crud/
  ├── create_spec.rb
  ├── read_spec.rb
  ├── update_spec.rb
  └── destroy_spec.rb
spec/features/cars/state_transitions/
  ├── activate_spec.rb
  ├── deactivate_spec.rb
  └── bulk_actions_spec.rb
spec/features/cars/search_and_filters_spec.rb
spec/features/cars/pagination_spec.rb
spec/factories/cars.rb
```

### With Optional Features

```bash
# Include nested forms, inline editing, state machine, and authorization specs
rails generate krudmin:integration_specs Product --nested-forms --inline-editing --state-machine --authorization

# Skip search and pagination specs
rails generate krudmin:integration_specs Order --no-search --no-pagination

# Disable factory generation (e.g., if manually managed)
rails generate krudmin:integration_specs Invoice --no-factory
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--nested-forms` | false | Generate specs for HasMany/HasOne nested forms |
| `--inline-editing` | false | Generate specs for inline field editing |
| `--state-machine` | false | Generate specs for AASM state machine transitions |
| `--authorization` | false | Generate specs for Pundit policy authorization |
| `--no-pagination` | false | Skip pagination specs |
| `--no-search` | false | Skip search and filter specs |
| `--factory` | true | Generate FactoryBot factory |
| `--namespace` | admin | Controller namespace (used in page object helpers) |

## Generated Files Explained

### Page Object (`spec/support/pages/{resource}_page.rb`)

Contains navigation, assertion, and action methods for clean spec code:

```ruby
class CarPage
  include Capybara::DSL
  include PageFeatures

  def initialize(url:, model:)
    @url = url
    @model = model
  end

  def visit_page(page: 1, limit: 25)
    visit("#{url}?#{{page: page, limit: limit}.to_query}")
  end

  def on_index_page?
    has_content?("Manage Cars")
  end

  def has_model_activated?
    has_content?("was successfully activated")
  end
end
```

**Usage in specs:**
```ruby
let(:car_page) { CarPage.new(url: admin_cars_path, model: car) }
car_page.visit_page
expect(car_page).to have_model_activated
```

### CRUD Specs

Organized by operation and context:

```
spec/features/cars/crud/
├── create_spec.rb      # Valid/invalid data flows
├── read_spec.rb        # Show page navigation
├── update_spec.rb      # Edit form and persistence
└── destroy_spec.rb     # Deletion and confirmation
```

**Example: Create Spec**
```ruby
describe "Car Creation", type: :feature do
  it "creates a new car and shows success message" do
    car_page.visit_page
    click_link("Add")
    fill_form_for(:car, model: "Civic", year: 2024)
    submit_form

    expect(page).to have_content("Civic was successfully created")
  end
end
```

### State Transition Specs

```
spec/features/cars/state_transitions/
├── activate_spec.rb       # From inactive → active
├── deactivate_spec.rb     # From active → inactive
└── bulk_actions_spec.rb   # Multi-select + bulk state changes
```

**Example: Bulk Actions**
```ruby
it "bulk activates multiple records" do
  select_rows(car_1, car_2)
  apply_bulk_action(":activate")

  expect(car_1.reload).to be_active
  expect(car_2.reload).to be_active
end
```

### Support Specs (Optional)

#### Search & Filters (`search_and_filters_spec.rb`)
```ruby
it "searches by model name" do
  search_for("Civic")

  expect(page).to have_content("Civic")
  expect(page).not_to have_content("Camry")
end
```

#### Pagination (`pagination_spec.rb`)
```ruby
it "navigates to the next page" do
  create_list(:car, 30)
  visit(admin_cars_path)
  click_link("2")

  expect(current_url).to include("page=2")
end
```

#### Inline Editing (`inline_editing_spec.rb`)
```ruby
it "edits field inline in the list view" do
  inline_edit_field(car, 'model', 'Corolla')

  expect(car.reload.model).to eq('Corolla')
end
```

#### Nested Forms (`nested_forms_spec.rb`)
```ruby
it "creates car with nested insurance" do
  fill_form_for(:car, model: "Accord")
  fill_in(:car_car_insurance_attributes_license_number, with: "ABC123")
  submit_form

  expect(car.car_insurance.license_number).to eq("ABC123")
end
```

#### State Machine Transitions (`state_machine_spec.rb`)
```ruby
it "transitions from draft to submitted on submit event" do
  car = create(:car, status: :draft)
  car_page.visit_page
  click_show_link_for(car)
  click_button("Submit")
  accept_confirmation

  expect(car.reload.status).to eq("submitted")
end

it "blocks invalid transitions" do
  car = create(:car, status: :draft)
  car_page.visit_page
  click_show_link_for(car)

  # Approve button doesn't exist (can only submit from draft)
  expect(page).not_to have_button("Approve")
end

it "follows valid transition chain" do
  car = create(:car, status: :draft)
  # draft → submitted → approved → paid
end
```

#### Authorization (`authorization_spec.rb`)
```ruby
it "admin can view and edit all records" do
  login_as(create(:user, role: :admin))
  car_page.visit_page

  expect(car_page).to have_add_button
  expect(car_page).to have_edit_link_for(car)
end

it "manager cannot delete records" do
  login_as(create(:user, role: :manager))
  car_page.visit_page

  expect(car_page).to have_destroy_link_for(car)  # Can see
end

it "unauthorized users cannot access page" do
  logout
  visit(admin_cars_path)

  expect(page).to have_access_denied_message
end
```

### Factory (`spec/factories/{resources}.rb`)

Basic template with standard traits:

```ruby
FactoryBot.define do
  factory :car do
    name { FFaker::Company.name }
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
```

**TODO items:**
1. Add model-specific attributes
2. Add associations (`association :car_brand`)
3. Add conditional traits (`trait :with_insurance { ... }`)

## Page Features Helpers

Generated specs use reusable helper methods in `spec/support/page_features.rb`:

| Helper | Purpose |
|--------|---------|
| `fill_form_for(model, attrs)` | Fill multiple form fields at once |
| `submit_form` | Click primary form button |
| `accept_confirmation` / `dismiss_confirmation` | Handle JS dialogs |
| `select_rows(*models)` | Select multiple records for bulk action |
| `apply_bulk_action(action)` | Execute bulk action with confirmation |
| `search_for(term)` | Search by keyword |
| `filter_by(field, value)` | Apply filter by select dropdown |
| `go_to_page(num)` | Navigate to pagination page |
| `inline_edit_field(model, field, value)` | Edit inline and save |

Page object assertions:

| Assertion | Purpose |
|-----------|---------|
| `page.on_state?(state)` | Verify current state machine state |
| `page.has_state_button?(event)` | Check if state transition button exists |
| `page.does_not_have_state_button?(event)` | Verify button hidden (invalid transition) |
| `page.does_not_have_add_button` | Verify add button is hidden |
| `page.does_not_have_edit_link_for?(model)` | Verify edit denied for record |
| `page.does_not_have_destroy_link_for?(model)` | Verify delete denied for record |
| `page.has_forbidden_message?` | Check authorization error message |
| `page.has_access_denied_message?` | Check access denied banner |

These are added automatically if `spec/support/page_features.rb` doesn't already include them.

## Running the Tests

```bash
# Run all integration tests for a resource
bundle exec rspec spec/features/cars/

# Run a specific test file
bundle exec rspec spec/features/cars/crud/create_spec.rb

# Run with coverage
bundle exec rspec spec/features/cars/ --coverage

# Watch for changes (requires guard-rspec)
bundle exec guard
```

## Customization

### Updating the Page Object

Add resource-specific helpers:

```ruby
# spec/support/pages/car_page.rb
class CarPage
  # ... existing code ...

  def has_brand_badge?(brand_name)
    has_selector?(".brand-badge", text: brand_name)
  end

  def select_transmission(type)
    select(type, from: :car_transmission)
  end
end
```

Then use in specs:

```ruby
car_page.select_transmission("Automatic")
expect(car_page).to have_brand_badge("Toyota")
```

### Updating Factories

Fill in model-specific attributes and associations:

```ruby
factory :car do
  model { FFaker::Vehicle.model }
  year { Random.new.rand(2000..2024) }
  transmission { :automatic }
  active { true }
  car_brand { association :car_brand }

  trait :inactive do
    active { false }
  end

  trait :manual_transmission do
    transmission { :manual }
  end

  trait :with_insurance do
    after(:create) do |car|
      create(:car_insurance, car: car)
    end
  end
end
```

### Adjusting for Your ResourceManager

Update spec files to match your `ResourceManager` configuration:

1. **For EDITABLE_ATTRIBUTES**: Adjust `fill_form_for(:model, ...)` calls
2. **For SEARCHABLE_ATTRIBUTES**: Update `search_and_filters_spec.rb` filter names
3. **For BULK_ACTIONS**: Update bulk action values in `bulk_actions_spec.rb`
4. **For associations**: Fill in nested form helpers in `nested_forms_spec.rb`
5. **For Pundit policies**: Update role/action expectations in `authorization_spec.rb`

Example CRUD create spec adjustment:

```ruby
# Original
fill_form_for(:car, model: "Test")

# Customized for YOUR model
fill_form_for(:car,
  model: "Civic",
  year: 2024,
  transmission: "automatic",
  car_brand_id: car_brand.id
)
```

### Customizing Authorization Tests

The authorization spec template assumes Pundit and user roles (`admin`, `manager`, `user`). Adjust for your setup:

```ruby
# If using different roles
context "as a editor user" do
  let(:editor) { create(:user, role: :editor) }
  before { login_as(editor) }

  it "can create but not delete" do
    # Your policy rules here
  end
end

# If using a different auth method
login_as(admin_user)  # Devise
# or
log_in(admin_user)    # Custom
# or
post('/login', session: { email: admin_user.email, password: 'password' })  # Form-based
```

## Best Practices

1. **Keep page objects focused** — Only interaction and navigation methods
2. **Use factories over database seeding** — Keeps tests isolated and fast
3. **Test user journeys, not implementation** — Click buttons, fill forms, assert outcomes
4. **Organize by feature** — CRUD, state changes, search, etc.
5. **Tag JavaScript-heavy tests** — `type: :feature, js: true` only when needed
6. **Avoid brittle selectors** — Use page object helpers instead of inline CSS/XPath
7. **Use transactions for non-JS tests** — Faster than database cleanup
8. **Mock external APIs** — Don't call real services in tests
9. **Test state machine constraints via UI** — Verify buttons/links are hidden for invalid transitions
10. **Create factories with state traits** — `create(:car, :draft)` for easy state setup

## Troubleshooting

### Tests are slow
- Use `js: true` only on specs that genuinely need JavaScript
- Enable test database transactions in `rails_helper.rb`:
  ```ruby
  config.use_transactional_fixtures = true
  ```

### Capybara can't find elements
- Add `sleep 1` temporarily to debug timing issues
- Use `page.save_screenshot` to inspect page state
- Check page object CSS selectors match your views

### Factory errors
- Ensure all required model attributes are defined in factory
- Check associations are correctly set up
- Use `create`/`build`/`build_stubbed` appropriately

### State machine tests are failing
- Verify AASM is configured correctly in your model
- Check that state column matches (default: `:status`)
- Ensure event methods are exposed in the controller/view
- Look for transition callbacks that might affect state (e.g., `:before_submit`)
- Update event button names in specs to match your actual UI
- Add state traits to your factory: `trait :draft { status { :draft } }`

### Authorization tests are not working
- Verify `login_as` helper is available (from Devise gem)
- Check that your test users can be created with roles
- Ensure Pundit policy is properly defined for the resource
- Verify policy methods match your actions (`:index?`, `:show?`, `:create?`, etc.)
- Test authentication vs authorization separately:
  - **Authentication**: User logged in? (Devise)
  - **Authorization**: User allowed to perform action? (Pundit)
- If using record-level authorization, create scoped test users and records
- Add `include Pundit::Test` to support `expect_pundit_authorize` if needed

## See Also

- [Feature Specs Guide](https://relishapp.com/rspec/rspec-rails/docs/feature-specs/feature-spec)
- [Capybara Cheat Sheet](https://www.cheatsheetank.com/capybara)
- [Page Object Pattern](https://www.selenium.dev/documentation/test_practices/encouraged/page_object_models/)
