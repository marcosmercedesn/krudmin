require "fileutils"
require "pathname"
require "sass-embedded"

module Krudmin
  class AssetBuilder
    JS_SOURCES = [
      ["jquery-rails", "vendor/assets/javascripts/jquery3.js"],
      ["popper_js", "assets/javascripts/popper.js"],
      ["bootstrap", "assets/javascripts/bootstrap.js"],
      [nil, "app/assets/javascripts/krudmin/vendor/turbo.js"],
      ["momentjs-rails", "vendor/assets/javascripts/moment.js"],
      [nil, "app/assets/javascripts/krudmin/vendor/daterangepicker.js"],
      [nil, "app/assets/javascripts/krudmin/vendor/js.cookie.js"],
      [nil, "app/assets/javascripts/krudmin/vendor/toast.js"],
      [nil, "app/assets/javascripts/krudmin/vendor/select2.js"],
      [nil, "app/assets/javascripts/krudmin/vendor/select2-en.js"],
      [nil, "app/assets/javascripts/krudmin/vendor/sweetalert.js"],
      [nil, "vendor/assets/javascripts/trix.js"],
      [nil, "vendor/assets/javascripts/stimulus.js"],
      [nil, "app/assets/javascripts/krudmin/core_theme/constants.js"],
      [nil, "app/assets/javascripts/krudmin/stimulus-loader.js"],
      [nil, "app/assets/javascripts/krudmin/controllers/tooltip_controller.js"],
      [nil, "app/assets/javascripts/krudmin/controllers/select2_controller.js"],
      [nil, "app/assets/javascripts/krudmin/controllers/datepicker_controller.js"],
      [nil, "app/assets/javascripts/krudmin/controllers/nested_fields_controller.js"],
      [nil, "app/assets/javascripts/krudmin/controllers/bulk_actions_controller.js"],
      [nil, "app/assets/javascripts/krudmin/controllers/inline_edit_controller.js"],
      [nil, "app/assets/javascripts/krudmin/controllers/remote_modal_controller.js"],
      [nil, "app/assets/javascripts/krudmin/controllers/belongs_to_one_controller.js"],
      [nil, "app/assets/javascripts/krudmin/controllers/belongs_to_controller.js"],
      [nil, "app/assets/javascripts/krudmin/controllers/sidebar_controller.js"],
      [nil, "app/assets/javascripts/krudmin/controllers/navigation_controller.js"],
      [nil, "app/assets/javascripts/krudmin/controllers/card_collapse_controller.js"],
      [nil, "app/assets/javascripts/krudmin/controllers/search_panel_controller.js"],
      [nil, "app/assets/javascripts/krudmin/trix-adapter.js"],
      [nil, "app/assets/javascripts/krudmin/sweet-confirm.js"],
      [nil, "app/assets/javascripts/krudmin/turbo-stream-actions.js"],
      [nil, "app/assets/javascripts/krudmin/core_theme/app.js"]
    ].freeze

    STYLE_ENTRYPOINT = "app/assets/stylesheets/krudmin/core_theme/application.scss".freeze
    JS_LOGICAL_PATH = "krudmin/core_theme/application.js".freeze
    CSS_LOGICAL_PATH = "krudmin/core_theme/application.css".freeze
    SASS_SILENCED_DEPRECATIONS = [
      "import",
      "slash-div",
      "global-builtin",
      "color-functions",
      "if-function"
    ].freeze

    def self.output_root(app_root:)
      Pathname.new(app_root).join("tmp", "krudmin-assets")
    end

    def self.build_if_needed!(app_root:)
      new(app_root: app_root).build_if_needed!
    end

    def self.build!(app_root:)
      new(app_root: app_root).build!
    end

    def initialize(app_root:, engine_root: Krudmin::Engine.root)
      @app_root = Pathname.new(app_root)
      @engine_root = Pathname.new(engine_root)
    end

    def build_if_needed!
      build! unless fresh?
    end

    def build!
      FileUtils.mkdir_p(js_output_path.dirname)
      FileUtils.mkdir_p(css_output_path.dirname)

      write_if_changed(js_output_path, bundled_javascript)
      write_if_changed(css_output_path, compiled_stylesheet)
    end

    private

    attr_reader :app_root, :engine_root

    def bundled_javascript
      JS_SOURCES.map do |gem_name, relative_path|
        source_path = source_file(gem_name, relative_path)
        <<~JS
          // Source: #{source_path}
          #{File.read(source_path)}
        JS
      end.join("\n\n")
    end

    def compiled_stylesheet
      result = Sass.compile(
        source_file(nil, STYLE_ENTRYPOINT).to_s,
        load_paths: stylesheet_load_paths,
        style: :expanded,
        quiet_deps: true,
        silence_deprecations: SASS_SILENCED_DEPRECATIONS
      )

      result.css
    end

    def stylesheet_load_paths
      [
        engine_root.join("app/assets/stylesheets").to_s,
        engine_root.join("vendor/assets/stylesheets").to_s,
        gem_asset_path("bootstrap", "assets/stylesheets").to_s
      ]
    end

    def fresh?
      [js_output_path, css_output_path].all?(&:exist?) && latest_source_mtime <= oldest_output_mtime
    end

    def latest_source_mtime
      source_paths.map(&:mtime).max
    end

    def oldest_output_mtime
      [js_output_path.mtime, css_output_path.mtime].min
    end

    def source_paths
      @source_paths ||= begin
        javascript_paths = JS_SOURCES.map { |gem_name, relative_path| source_file(gem_name, relative_path) }
        stylesheet_paths = Dir[engine_root.join("app/assets/stylesheets/**/*.{css,scss,sass}").to_s].map { |path| Pathname.new(path) }
        vendor_stylesheet_paths = Dir[engine_root.join("vendor/assets/stylesheets/**/*.{css,scss,sass}").to_s].map { |path| Pathname.new(path) }

        (javascript_paths + stylesheet_paths + vendor_stylesheet_paths + [gem_asset_path("bootstrap", "assets/stylesheets/_bootstrap.scss")]).uniq
      end
    end

    def source_file(gem_name, relative_path)
      gem_name ? gem_asset_path(gem_name, relative_path) : engine_root.join(relative_path)
    end

    def gem_asset_path(gem_name, relative_path)
      gem_spec = Gem.loaded_specs.fetch(gem_name) do
        raise LoadError, "Missing gem dependency for Krudmin asset build: #{gem_name}"
      end

      Pathname.new(gem_spec.full_gem_path).join(relative_path)
    end

    def js_output_path
      self.class.output_root(app_root: app_root).join(JS_LOGICAL_PATH)
    end

    def css_output_path
      self.class.output_root(app_root: app_root).join(CSS_LOGICAL_PATH)
    end

    def write_if_changed(path, contents)
      return if path.exist? && path.read == contents

      path.write(contents)
    end
  end
end