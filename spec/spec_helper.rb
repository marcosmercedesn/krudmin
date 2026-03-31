require 'simplecov'
require 'active_support/all'
require 'active_model'
require "devise"
require "ostruct"

SimpleCov.start

I18n.backend.store_translations(:en,
  YAML.load(File.open('./config/locales/en.yml').read)['en']
)

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
    mocks.syntax = :expect
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  # rspec-rails 8 removed the `setup`/`teardown` Minitest shims that
  # Devise::Test::ControllerHelpers relies on. Provide them so Devise
  # can register its before/after hooks.
  config.include Module.new {
    def self.included(base)
      base.extend ClassMethods if base.respond_to?(:extend)
    end

    module ClassMethods
      def setup(*)
        # no-op: satisfies Devise's `setup` call in ControllerHelpers
      end

      def teardown(*)
        # no-op
      end
    end
  }, type: :controller

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Warden::Test::Helpers
end
