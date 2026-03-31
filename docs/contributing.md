# Contributing

Thank you for your interest in contributing to Krudmin! This guide will help you get set up for development.

## Development Setup

### Prerequisites

- Ruby 3.4.6 (see `.ruby-version`)
- Bundler
- SQLite3 (for running tests)

### Getting Started

1. **Clone the repository:**

```bash
git clone https://github.com/markmercedes/krudmin.git
cd krudmin
```

2. **Install dependencies:**

```bash
bundle install
```

3. **Set up the test database:**

```bash
cd spec/test_app
bundle exec rails db:create db:migrate
cd ../..
```

4. **Run the test suite:**

```bash
bundle exec rspec
```

5. **Run the test app** (for manual testing):

```bash
cd spec/test_app
bundle exec rails s
```

Then visit `http://localhost:3000/admin`.

### Useful Commands

```bash
bundle exec rspec                    # Run all tests
bundle exec rspec spec/lib/          # Run only lib tests
bundle exec rspec spec/controllers/  # Run only controller tests
bundle exec guard                    # Auto-run tests on file changes
bundle exec rubocop                  # Run linter
```

## Project Structure

```
krudmin/
├── app/              # Engine application code (controllers, views, models)
├── config/           # Engine configuration (locales, initializers)
├── lib/              # Core library code (fields, presenters, handlers, etc.)
├── spec/             # Tests
│   ├── test_app/     # Dummy Rails app for testing
│   ├── controllers/  # Controller specs
│   ├── features/     # Feature/integration tests
│   ├── lib/          # Library unit tests
│   └── models/       # Model specs
└── docs/             # Documentation
```

## Test App

The `spec/test_app/` directory contains a full Rails application that demonstrates Krudmin features. It includes:

- **Models:** Car, CarBrand, CarOwner, CarInsurance, Passenger
- **Resource Managers:** CarsResourceManager (comprehensive example), CarBrandsResourceManager, etc.
- **Policies:** CarPolicy, CarBrandPolicy
- **Configuration:** Full initializer with navigation menu, Pundit, themes

This is the best reference for understanding how Krudmin is used.

## Making Changes

### Adding a New Field Type

1. Create field class: `lib/krudmin/fields/{type}.rb`
2. Create presenter: `lib/krudmin/presenters/{type}_field_presenter.rb`
3. Create view partials: `app/views/krudmin/core_theme/fields/{type}/`
4. Add require: `lib/krudmin.rb`
5. Add inflector mapping if needed: `lib/krudmin/fields/inflector.rb`
6. Add tests
7. Update documentation: `docs/fields.md`

### Adding a New Action Button

1. Create button class: `lib/krudmin/action_buttons/{type}_button.rb`
2. Create view partials: `app/views/krudmin/core_theme/action_buttons/{type}_button/`
3. Add require: `lib/krudmin.rb`
4. Add tests

### Modifying CRUD Behavior

- Mutation handlers: `lib/krudmin/mutation_handlers/`
- Controller: `app/controllers/krudmin/application_controller.rb`
- Concerns: `app/controllers/concerns/krudmin/`

## Guidelines

- Follow existing code style and conventions
- Write tests for new features
- Keep controllers thin — use concerns, handlers, and service objects
- Views use HAML (not ERB)
- Forms use SimpleForm
- I18n translations go in `config/locales/en.yml`
- No custom DSL — use plain Ruby classes and Rails conventions

## Code of Conduct

Please note that this project is released with a Contributor Code of Conduct. By participating in this project you agree to abide by its terms. See [code_of_conduct.md](/docs/code_of_conduct.md).

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](http://opensource.org/licenses/MIT).
