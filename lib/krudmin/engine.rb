require "devise"
require "jquery-rails"
require "kaminari"
require "momentjs-rails"
require "bootstrap"
require "sass-embedded"
require "simple_form"
require "turbo-rails"
require "pundit"
require "ransack"
require "krudmin/asset_builder"
require_relative "../config"

module Krudmin
  class Engine < ::Rails::Engine
    isolate_namespace Krudmin

    # Register Krudmin asset sources and generated build output for Propshaft.
    initializer "krudmin.assets" do |app|
      app.config.assets.paths << root.join("vendor", "assets", "javascripts")
      app.config.assets.paths << root.join("vendor", "assets", "stylesheets")
      app.config.assets.paths << Krudmin::AssetBuilder.output_root(app_root: app.root)
    end

    initializer "krudmin.assets.build" do |app|
      ActiveSupport::Reloader.to_prepare do
        Krudmin::AssetBuilder.build_if_needed!(app_root: app.root)
      end
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
