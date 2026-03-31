module Krudmin
  module Generators
    class ResourceGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      desc "Generate a Krudmin resource manager and controller for a model"

      argument :raw_attributes, type: :array, default: [], banner: "field:type field:type"

      class_option :namespace, type: :string, default: "admin", desc: "Controller namespace"
      class_option :policy, type: :boolean, default: false, desc: "Generate a Pundit policy"
      class_option :remote, type: :boolean, default: false, desc: "Enable AJAX CRUD"

      def create_resource_manager
        template "resource_manager.rb.tt",
                 "app/resource_managers/#{plural_file_name}_resource_manager.rb"
      end

      def create_controller
        template "controller.rb.tt",
                 "app/controllers/#{namespace_path}#{plural_file_name}_controller.rb"
      end

      def create_policy
        return unless options[:policy]

        template "policy.rb.tt", "app/policies/#{file_name}_policy.rb"
      end

      def print_route_instructions
        say ""
        say "Resource generated!", :green
        say ""
        say "Add to your routes:", :yellow
        say ""
        if namespace_name.present?
          say "  namespace :#{namespace_name} do"
          say "    resources :#{plural_file_name} do"
          say "      member do"
          say "        post :activate"
          say "        post :deactivate"
          say "      end"
          say "    end"
          say "  end"
        else
          say "  resources :#{plural_file_name} do"
          say "    member do"
          say "      post :activate"
          say "      post :deactivate"
          say "    end"
          say "  end"
        end
        say ""
        say "Add to your navigation menu in config/initializers/krudmin.rb:", :yellow
        say ""
        if namespace_name.present?
          say "  menu.node label: \"#{class_name.pluralize}\", resource: \"#{file_name}\", module_path: :#{namespace_name}, icon: :list"
        else
          say "  menu.node label: \"#{class_name.pluralize}\", resource: \"#{file_name}\", icon: :list"
        end
        say ""
      end

      private

      def namespace_name
        options[:namespace]
      end

      def namespace_path
        namespace_name.present? ? "#{namespace_name}/" : ""
      end

      def controller_class_prefix
        namespace_name.present? ? "#{namespace_name.camelize}::" : ""
      end

      def plural_file_name
        file_name.pluralize
      end

      def attribute_names
        parsed_attributes.map { |a| a[:name].to_sym }
      end

      def parsed_attributes
        @parsed_attributes ||= raw_attributes.map do |attr|
          parts = attr.split(":")
          { name: parts[0], type: parts[1] || "string" }
        end
      end

      def listable_attributes
        attribute_names
      end

      def editable_attributes
        attribute_names
      end

      def searchable_attributes
        parsed_attributes.select { |a| %w[string text integer number boolean].include?(a[:type]) }.map { |a| a[:name].to_sym }
      end

      def krudmin_field_type(db_type)
        case db_type
        when "string" then nil  # auto-detected
        when "text" then ":Text"
        when "integer", "number" then ":Number"
        when "decimal" then ":Decimal"
        when "float" then ":Number"
        when "boolean" then ":Boolean"
        when "date" then ":Date"
        when "datetime" then ":DateTime"
        when "email" then ":Email"
        when "currency" then ":Currency"
        when "rich_text", "richtext" then ":RichText"
        else nil
        end
      end

      def attribute_types_hash
        parsed_attributes.select { |a| krudmin_field_type(a[:type]) }.map do |attr|
          "    #{attr[:name]}: #{krudmin_field_type(attr[:type])}"
        end.join(",\n")
      end

      def has_attribute_types?
        parsed_attributes.any? { |a| krudmin_field_type(a[:type]) }
      end

      def first_string_attribute
        attr = parsed_attributes.find { |a| %w[string text].include?(a[:type]) }
        attr ? ":#{attr[:name]}" : ":id"
      end
    end
  end
end
