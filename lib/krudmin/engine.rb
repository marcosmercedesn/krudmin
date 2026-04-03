require "devise"
require "jquery-rails"
require "kaminari"
require "momentjs-rails"
require "sassc-rails"
require "bootstrap"
require "simple_form"
require "turbo-rails"
require "pundit"
require "ransack"
require_relative "../config"

module Krudmin
  class Engine < ::Rails::Engine
    isolate_namespace Krudmin

    # Register vendored assets (Trix editor JS/CSS) so Sprockets can find them
    initializer "krudmin.assets" do |app|
      app.config.assets.paths << root.join("vendor", "assets", "javascripts")
      app.config.assets.paths << root.join("vendor", "assets", "stylesheets")
    end

    config.generators do |gen|
      gen.test_framework :rspec
      gen.fixture_replacement :factory_girl, dir: "spec/factories"
    end

    config.after_initialize do
      config.i18n.load_path += Dir["#{config.root}/config/locales/**/*.yml"]
    end
  end
end
