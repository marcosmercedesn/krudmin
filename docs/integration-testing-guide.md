# Integration Testing Guide for Krudmin

A comprehensive guide for writing, maintaining, and extending integration tests for Krudmin admin resources using Capybara, RSpec, and page objects.

## Quick Reference

**When to use integration specs:**
- Testing complete user workflows (form → submit → verification)
- Testing state transitions and status changes
- Testing authorization and role-based access
- Testing search, filtering, and pagination
- Testing nested forms and associations
- Testing inline editing
- Testing AASM state machines

**When to use unit specs instead:**
- Testing model validations/business logic
- Testing controller filters/before_actions
- Testing helper methods
- Testing service/presenter logic

## File Organization

### Directory Structure
```
spec/
├── features/
│   ├── resources/
│   │   ├── crud/
│   │   │   ├── create_spec.rb
│   │   │   ├── read_spec.rb
│   │   │   ├── update_spec.rb
│   │   │   └── destroy_spec.rb
│   │   ├── state_transitions/
│   │   │   ├── activate_spec.rb
│   │   │   ├── deactivate_spec.rb
│   │   │   └── bulk_actions_spec.rb
│   │   ├── state_machine_spec.rb
│   │   ├── authorization_spec.rb
│   │   ├── search_and_filters_spec.rb
│   │   ├── pagination_spec.rb
│   │   ├── inline_editing_spec.rb
│   │   └── nested_forms_spec.rb
│   └── other_resource/
├── support/
│   ├── pages/
│   │   ├── resource_page.rb
│   │   └── other_resource_page.rb
│   └── page_features.rb
├── factories/
│   ├── resources.rb
│   └── other_resources.rb
└── rails_helper.rb
```

### Naming Conventions

**Files:**
- `resource_name_spec.rb` (singular model name)
- Plural directory: `resources/` (plural model name)
- Grouped by feature: `crud/`, `state_transitions/`, etc.

**Spec descriptions:**
```ruby
describe "< Model> FEATURE", type: :feature do
  # ✅ Good
  describe "Car Creation", type: :feature
  describe "Car Activation", type: :feature
  describe "Car Authorization (Pundit Policy)", type: :feature

  # ❌ Avoid
  describe "CarsController", type: :feature  # Too technical
  describe "POST /admin/cars", type: :feature  # Use HTTP semantics
  describe "create action", type: :feature  # Focus on user flow
end
```

**Test names:**
```ruby
# ✅ Good - describe user action and outcome
it "creates a new car and shows success message"
it "activates car from list actions"
it "admin can view and edit all records"
it "manager cannot delete records"

# ❌ Avoid
it "works"
it "should create"
it "creates car"  # Outcome missing
it "test activation"  # "test" is redundant
```

## Page Object Pattern

### Structure

```ruby
# spec/support/pages/resource_page.rb
class ResourcePage
  include Capybara::DSL
  include PageFeatures

  attr_reader :url, :model

  def initialize(url:, model:)
    @url = url
    @model = model
  end

  # ===== Grouping sections with comments =====

  # ===== Navigation =====
  def visit_page(page: 1, limit: 25)
    visit("#{url}?#{{page: page, limit: limit}.to_query}")
  end

  # ===== Assertions (named predicates) =====
  def on_index_page?
    has_content?("Manage Resources")
  end

  # ===== Row Actions =====
  def click_edit_model_link
    click_edit_link_for(model)
  end

  # ===== Form Assertions =====
  def has_created_message_visible?
    has_content?("was successfully created")
  end
end
```

### Page Object Best Practices

✅ **DO:**
- Organize methods into logical groups with comments
- Use predicate methods (`on_index_page?` not `check_on_index_page`)
- Keep methods focused and re-usable
- Extract complex interactions into helper methods
- Add resource-specific assertions

❌ **DON'T:**
- Use page object for controller/model testing
- Put business logic in page object (just interaction)
- Create methods that click AND assert (separate concerns)
- Use hard-coded CSS selectors (use `class:` parameters)
- Make page objects stateful beyond the model

### Adding Resource-Specific Helpers

```ruby
# Good: Extract repeatable interactions
class ProductPage
  def mark_as_featured
    within(row_css_for(model)) do
      find('.btn-feature').click
    end
  end

  def has_price_displayed?(expected_price)
    has_content?("$#{expected_price}")
  end

  def fill_pricing_section(cost:, selling_price:)
    fill_in(:product_cost, with: cost)
    fill_in(:product_selling_price, with: selling_price)
  end
end
```

## Test Patterns

### CRUD Specs

**Create Spec Pattern:**
```ruby
describe "Creation", type: :feature do
  let(:page_obj) { ResourcePage.new(url: admin_resources_path, model: build_stubbed(:resource)) }

  before do
    page_obj.visit_page
    click_link("Add")
  end

  context "with valid data" do
    it "creates and shows success message" do
      fill_form_for(:resource, name: "Test")
      submit_form

      expect(page).to have_content("Test was successfully created")
    end

    it "persists to database" do
      fill_form_for(:resource, name: "Persistent")
      submit_form

      expect(Resource.last.name).to eq("Persistent")
    end
  end

  context "with invalid data" do
    it "shows validation errors" do
      submit_form  # Empty form

      expect(page).to have_content("can't be blank")
    end

    it "preserves form data on error" do
      fill_in(:resource_name, with: "Partial")
      submit_form

      expect(find_field(:resource_name).value).to eq("Partial")
    end
  end
end
```

**Update Spec Pattern:**
```ruby
describe "Update", type: :feature do
  let!(:resource) { create(:resource, name: "Original") }
  let(:page_obj) { ResourcePage.new(url: admin_resources_path, model: resource) }

  before do
    page_obj.visit_page
    click_edit_link_for(resource)
  end

  context "with valid data" do
    it "updates and shows confirmation" do
      fill_in(:resource_name, with: "Updated")
      submit_form

      expect(page).to have_content("Updated was successfully modified")
      expect(resource.reload.name).to eq("Updated")
    end
  end

  context "with invalid data" do
    it "reverts on validation error" do
      fill_in(:resource_name, with: "")
      submit_form

      expect(resource.reload.name).to eq("Original")
    end
  end
end
```

**Delete Spec Pattern:**
```ruby
describe "Destruction", type: :feature, js: true do
  let!(:resource) { create(:resource) }

  before { visit(admin_resources_path) }

  it "destroys record and confirms" do
    click_destroy_link_for(resource)
    accept_confirmation

    expect(page).to have_content("was successfully destroyed")
    expect(Resource.exists?(resource.id)).to be(false)
  end
end
```

### State Transition Patterns

```ruby
describe "State Transitions", type: :feature, js: true do
  let!(:resource) { create(:resource, status: :draft) }

  context "valid transitions" do
    it "transitions when button clicked" do
      visit(admin_resource_path(resource))
      click_button("Submit")
      accept_confirmation

      expect(resource.reload.status).to eq("submitted")
    end
  end

  context "invalid transitions" do
    it "hides forbidden buttons" do
      visit(admin_resource_path(resource))

      expect(page).not_to have_button("Approve")
    end
  end

  context "multi-step workflows" do
    it "allows complete state chain" do
      # draft → submitted → approved → paid
      visit(admin_resource_path(resource))

      click_button("Submit")
      accept_confirmation
      expect(resource.reload.status).to eq("submitted")

      click_link("Refresh")  # or page refresh
      click_button("Approve")
      accept_confirmation
      expect(resource.reload.status).to eq("approved")
    end
  end
end
```

### Authorization Patterns

```ruby
describe "Authorization", type: :feature do
  let(:resource) { create(:resource) }

  context "admin user" do
    before { login_as(create(:user, role: :admin)) }

    it "has full access" do
      visit(admin_resources_path)
      expect(page).to have_link("Add")
      expect(page).to have_content(resource.name)
    end
  end

  context "manager user" do
    before { login_as(create(:user, role: :manager)) }

    it "has limited access" do
      visit(admin_resources_path)
      expect(page).not_to have_link("Add")
    end
  end

  context "unauthenticated user" do
    it "is redirected to login" do
      visit(admin_resources_path)
      expect(current_path).to eq(new_user_session_path)
    end
  end
end
```

## Common Patterns & Anti-Patterns

### ✅ DO: Test User Journeys

```ruby
# Good: User story focus
it "can create a product and immediately activate it" do
  product_page.visit_page
  click_link("Add")
  fill_form_for(:product, name: "Widget", price: "9.99")
  submit_form

  product_page.visit_page
  click_activation_link_for(Product.last)
  accept_confirmation

  expect(Product.last).to be_active
end
```

### ❌ DON'T: Test Implementation Details

```ruby
# Bad: Testing controller action directly
it "calls ProductService.create" do
  expect(ProductService).to receive(:create)
  # ...
end

# Bad: Testing model logic in feature spec
it "validates presence of name" do
  expect(build(:product, name: nil)).not_to be_valid
end
```

### ✅ DO: Use Factories for Setup

```ruby
# Good
before { create(:user, role: :admin) }
before { create_list(:product, 5) }
```

### ❌ DON'T: Create Records via UI in Fixtures

```ruby
# Bad: Slow, brittle, tests UI twice
before do
  visit(admin_products_path)
  click_link("Add")
  fill_in(:product_name, with: "Test")
  # ... just for setup!
end
```

### ✅ DO: Use Meaningful Assertions

```ruby
# Good: User-facing assertions
expect(page).to have_content("Product successfully created")
expect(page).to have_activate_link_for(product)
expect(page_obj).to be_on_edit_page
```

### ❌ DON'T: Assert Implementation

```ruby
# Bad
expect(page).to have_selector(".btn-success.btn-lg")  # CSS coupling
expect(Product.count).to eq(1)  # Implementation detail
```

## Performance Optimization

### Use Transactional Fixtures
```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  config.use_transactional_fixtures = true  # Faster than database_cleaner for non-JS
end
```

### Tag JS Tests
```ruby
# Only JavaScript tests need `, js: true`
describe "Inline Editing", type: :feature, js: true do
end

# Non-JS tests use default (no tag needed)
describe "CRUD", type: :feature do
end
```

### Avoid N+1 Queries
```ruby
# spec/support/pages/resource_page.rb
class ResourcePage
  def visit_page
    visit("#{url}?limit=25")  # Constrain result set
  end
end
```

### Minimize Waits
```ruby
# Don't sleep!
# ❌ sleep 1
# ✅ use Capybara's built-in waits
find(".submit-button")  # Auto-waits
```

## Maintaining Tests as Features Change

### When Adding a Feature

1. **Add page object helper first:**
   ```ruby
   # spec/support/pages/resource_page.rb
   def has_subscribe_button?
     has_button?("Subscribe")
   end
   ```

2. **Create feature spec:**
   ```ruby
   # spec/features/resources/subscribe_spec.rb
   describe "Subscription", type: :feature do
     it "subscribes user" do
       expect(page_obj).to have_subscribe_button
       click_button("Subscribe")
       expect(page).to have_content("Subscribed!")
     end
   end
   ```

3. **Update related specs:**
   - CRUD specs (show button in list/show)
   - Authorization (who can subscribe?)
   - State machine (does subscription affect states?)

### When Refactoring

**Update Page Object First:**
```ruby
# Old selector changed
# OLD: .btn-edit-item
# NEW: [data-action="edit"]

def click_edit_model_link
  within(row_css_for(model)) do
    find("[data-action='edit']").click
  end
end
```

**Then Verify Specs Pass:**
```bash
bundle exec rspec spec/features/resources/ -v
```

### When Fixing Flaky Tests

**Identify the Issue:**
```ruby
# ❌ Race condition with JavaScript
find(".button", visible: true)
find(".button")  # Default wait is 2 seconds

# ✅ Wait for AJAX
click_button
expect(page).to have_content("Success")  # Auto-waits for element
```

**Use Explicit Waits Rarely:**
```ruby
# Only if absolutely necessary
within_wait_time(5) do
  find(".loading-complete")
end
```

## Debugging Integration Tests

### Screenshots & Snapshots

```ruby
# config/rails_helper.rb
Capybara::Screenshot.autosave_on_failure = true

# In failing test, check:
# tmp/capybara/example_name.png
```

### Save & Open Page

```ruby
it "does something" do
  visit(admin_resources_path)
  save_and_open_page  # Opens browser
  # ... debug
end
```

### Print Debug Information

```ruby
it "does something" do
  visit(admin_resources_path)

  puts "Current path: #{current_path}"
  puts "Page content: #{page.text[0..200]}"
  puts "All links: #{all('a').map(&:text)}"
end
```

### Check Capybara Matchers

```ruby
# available?
page.has_content?("Text")
page.has_selector?(".btn")
page.has_no_link?("Disabled Link")

# debug helpers
page.body  # Full HTML
page.html  # Same as above
page.text  # All text
```

## Testing Checklist

Before committing specs, verify:

- [ ] **File Organization** — Spec in correct directory (`crud/`, `state_transitions/`, etc.)
- [ ] **Naming** — File and test names describe user action, not implementation
- [ ] **Page Object** — Resource-specific logic extracted to page object
- [ ] **Setup** — Use factories, not UI-driven creation
- [ ] **Assertions** — User-facing assertions, not implementation details
- [ ] **JS Flag** — Only `js: true` where needed
- [ ] **Isolation** — Tests don't depend on other tests
- [ ] **Cleanup** — No dangling created records
- [ ] **Performance** — No unnecessary sleeps or waits
- [ ] **Docs** — Complex interactions documented in comments
- [ ] **Related Specs** — Updated CRUD/auth/state specs if feature-adjacent
- [ ] **Run Suite** — All specs pass: `bundle exec rspec spec/features/resource_name/`

## Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Test fails intermittently | Race condition with JS | Use `has_content?` (auto-waits) or explicit wait |
| "Element not found" | Wrong selector or timing | Use `page.save_screenshot` to debug |
| Authorization tests fail | Wrong user role or factory | Verify factory creates correct role |
| CRUD specs but not factory creation | Transaction isolation | Ensure factory doesn't depend on saved records |
| Form submission hangs | Validation error or redirect | Check browser console in screenshot |
| Nested form not filling | Complex form structure | Add custom page object helper |
| State machine transitions fail | Event method name mismatch | Verify event names in AASM config |

## Reference

### Common Capybara Methods

```ruby
# Navigation
visit(path)
current_path
current_url

# Finding Elements
find(".selector")
find_field(:field_name)
find_button("Button Text")
find_link("Link Text")

# Clicking & Form Input
click_link("Text")
click_button("Text")
click_on("Text or ID")
fill_in(:field_name, with: "value")
select("Option", from: :dropdown)
check(:checkbox)
uncheck(:checkbox)

# Assertions
expect(page).to have_content("text")
expect(page).to have_selector(".class")
expect(page).to have_no_link("Hidden Link")

# Dialogs
accept_alert  # JS alert()
accept_confirm  # JS confirm()
dismiss_confirm
accept_prompt

# Page Content
page.text
page.body
page.html
page.current_window
```

### RSpec Hooks

```ruby
describe "Feature" do
  before(:all)    { # Once per group }
  before(:each)   { # Before each test (default} }
  after(:each)    { # After each test }
  after(:all)     { # Once per group }
end
```

## Resources

- [Capybara Documentation](https://github.com/teamcapybara/capybara)
- [RSpec Documentation](https://rspec.info)
- [Page Object Model Pattern](https://www.selenium.dev/documentation/test_practices/encouraged/page_object_models/)
- [Krudmin Integration Test Generator](docs/integration_test_generator.md)
