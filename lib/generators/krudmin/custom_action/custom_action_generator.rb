module Krudmin
  module Generators
    class CustomActionGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Generate a custom action for a Krudmin resource"

      argument :resource, type: :string, desc: "Resource name (e.g., Order)"
      argument :action_name, type: :string, desc: "Action name (e.g., generate_invoice)"

      class_option :namespace, type: :string, default: "admin", desc: "Controller namespace"
      class_option :specs, type: :boolean, default: true, desc: "Generate RSpec spec"
      class_option :method, type: :string, default: "post", desc: "HTTP method"

      def create_controller_stub
        template "controller_method.rb.tt",
                 "tmp/generators/#{action_name}_controller_stub.rb"
      end

      def create_spec
        return unless options[:specs]

        template "custom_action_spec.rb.tt",
                 "spec/requests/#{namespace_path}#{plural_resource}_#{action_name}_spec.rb"
      end

      def print_checklist
        say ""
        say "Custom action '#{action_name}' generated for #{resource_class}!", :green
        say ""
        say "Checklist:", :yellow
        say ""
        say "1. Add the custom_action DSL to your ResourceManager:", :yellow
        say ""
        say "  # app/resource_managers/#{plural_resource}_resource_manager.rb"
        say "  class #{plural_resource_class}ResourceManager < Krudmin::ResourceManagers::Base"
        say "    custom_action :#{action_name}, label: \"#{human_action_name}\", icon: :cog,"
        say "                  method: :#{http_method}, placement: :list"
        say ""
        say "    LISTABLE_ACTIONS = [:show, :edit, :#{action_name}, :active, :destroy]"
        say "  end"
        say ""
        say "2. Add the member route to config/routes.rb:", :yellow
        say ""
        if namespace_name.present?
          say "  namespace :#{namespace_name} do"
          say "    resources :#{plural_resource} do"
          say "      #{http_method} :#{action_name}, on: :member"
          say "    end"
          say "  end"
        else
          say "  resources :#{plural_resource} do"
          say "    #{http_method} :#{action_name}, on: :member"
          say "  end"
        end
        say ""
        say "3. Add the controller method (see tmp/generators/#{action_name}_controller_stub.rb):", :yellow
        say ""
        say "  # app/controllers/#{namespace_path}#{plural_resource}_controller.rb"
        say "  def #{action_name}"
        say "    @#{resource_name} = #{resource_class}.find(params[:id])"
        say "    authorize @#{resource_name}, :#{action_name}?"
        say "    # Your business logic here"
        say "    redirect_back fallback_location: #{namespace_prefix}#{singular_resource}_path(@#{resource_name}), notice: \"#{human_action_name} completed\""
        say "  end"
        say ""
        say "4. (If using Pundit) Add the policy predicate:", :yellow
        say ""
        say "  # app/policies/#{resource_name}_policy.rb"
        say "  def #{action_name}?; user.admin?; end"
        say ""
        say "5. Run tests: bundle exec rspec", :yellow
        say ""
      end

      private

      def resource_name
        resource.underscore.singularize
      end

      def resource_class
        resource.classify
      end

      def singular_resource
        resource_name
      end

      def plural_resource
        resource_name.pluralize
      end

      def plural_resource_class
        resource_class.pluralize
      end

      def human_action_name
        action_name.humanize
      end

      def http_method
        options[:method]
      end

      def namespace_name
        options[:namespace]
      end

      def namespace_path
        namespace_name.present? ? "#{namespace_name}/" : ""
      end

      def namespace_prefix
        namespace_name.present? ? "#{namespace_name}_" : ""
      end

      def controller_class_prefix
        namespace_name.present? ? "#{namespace_name.camelize}::" : ""
      end
    end
  end
end
