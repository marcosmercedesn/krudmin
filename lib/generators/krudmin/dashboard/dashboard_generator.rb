module Krudmin
  module Generators
    class DashboardGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      desc "Generate a Krudmin dashboard class and controller"

      class_option :namespace, type: :string, default: "admin", desc: "Controller namespace"

      def create_dashboard_class
        template "dashboard.rb.tt", "app/dashboards/#{dashboard_file_name}.rb"
      end

      def create_controller
        template "controller.rb.tt", "app/controllers/#{namespace_path}#{controller_file_name}_controller.rb"
      end

      def print_route_instructions
        say ""
        say "Dashboard generated!", :green
        say ""
        say "Add to your routes:", :yellow
        say ""
        if namespace_name.present?
          say "  namespace :#{namespace_name} do"
          say "    get :#{route_name}, to: \"#{controller_file_name}#show\""
          say "    root to: \"#{controller_file_name}#show\""
          say "  end"
        else
          say "  get :#{route_name}, to: \"#{controller_file_name}#show\""
          say "  root to: \"#{controller_file_name}#show\""
        end
        say ""
        say "Optional navigation menu entry:", :yellow
        say ""
        if namespace_name.present?
          say "  menu.link label: \"Dashboard\", link: :#{namespace_name}_#{route_name}_path, module_path: :#{namespace_name}, icon: :dashboard"
        else
          say "  menu.link label: \"Dashboard\", link: :#{route_name}_path, icon: :dashboard"
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

      def controller_file_name
        file_name.underscore
      end

      def dashboard_file_name
        [namespace_name, controller_file_name].compact.reject(&:blank?).join("_")
      end

      def dashboard_class_name
        [namespace_name.presence&.camelize, class_name].compact.join
      end

      def controller_class_name
        [namespace_name.presence&.camelize, "#{class_name}Controller"].compact.join("::")
      end

      def route_name
        controller_file_name
      end
    end
  end
end