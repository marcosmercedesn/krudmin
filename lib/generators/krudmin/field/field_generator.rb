module Krudmin
  module Generators
    class FieldGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      desc "Generate a custom Krudmin field type with presenter and view partials"

      class_option :parent, type: :string, default: "Base", desc: "Parent field class (e.g., String, Number)"
      class_option :specs, type: :boolean, default: true, desc: "Generate RSpec spec"

      def create_field_class
        template "field.rb.tt", "lib/krudmin/fields/#{file_name}.rb"
      end

      def create_presenter_class
        template "presenter.rb.tt", "lib/krudmin/presenters/#{file_name}_field_presenter.rb"
      end

      def create_form_partial
        copy_file "_form_field.html.haml",
                  "app/views/krudmin/core_theme/fields/#{file_name}/_form_field.html.haml"
      end

      def create_search_partial
        copy_file "_search.html.haml",
                  "app/views/krudmin/core_theme/fields/#{file_name}/_search.html.haml"
      end

      def create_spec
        return unless options[:specs]

        template "field_spec.rb.tt", "spec/lib/krudmin/fields/#{file_name}_spec.rb"
      end

      def print_post_install
        say ""
        say "Field type generated!", :green
        say ""
        say "Add the following require to lib/krudmin.rb:", :yellow
        say ""
        say "  require \"krudmin/fields/#{file_name}\""
        say ""
        say "Then use it in a ResourceManager:", :yellow
        say ""
        say "  ATTRIBUTE_TYPES = {"
        say "    my_attribute: :#{class_name}"
        say "  }"
        say ""
      end

      private

      def parent_class_name
        parent = options[:parent]
        parent == "Base" ? "Base" : parent
      end

      def parent_require
        return nil if parent_class_name == "Base"

        parent_class_name.underscore
      end
    end
  end
end
