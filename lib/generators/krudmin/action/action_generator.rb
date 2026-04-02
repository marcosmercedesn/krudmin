module Krudmin
  module Generators
    class ActionGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      desc "Generate a custom Krudmin action button"

      class_option :model_action, type: :boolean, default: true, desc: "Inherit from ModelActionButton (vs Base)"
      class_option :specs, type: :boolean, default: true, desc: "Generate RSpec spec"

      def create_button_class
        template "action_button.rb.tt",
                 "lib/krudmin/action_buttons/#{file_name}_button.rb"
      end

      def create_list_partial
        template "_list.html.haml.tt",
                 "app/views/krudmin/core_theme/action_buttons/#{file_name}_button/_list.html.haml"
      end

      def create_form_partial
        template "_form.html.haml.tt",
                 "app/views/krudmin/core_theme/action_buttons/#{file_name}_button/_form.html.haml"
      end

      def create_spec
        return unless options[:specs]

        template "action_button_spec.rb.tt",
                 "spec/lib/krudmin/action_buttons/#{file_name}_button_spec.rb"
      end

      def print_post_install
        say ""
        say "Action button generated!", :green
        say ""
        say "Add the following require to lib/krudmin.rb:", :yellow
        say ""
        say "  require \"krudmin/action_buttons/#{file_name}_button\""
        say ""
        say "Add :#{file_name} to LISTABLE_ACTIONS in your ResourceManager:", :yellow
        say ""
        say "  LISTABLE_ACTIONS = [:show, :edit, :#{file_name}, :active, :destroy]"
        say ""
        say "Add a route for the action:", :yellow
        say ""
        say "  resources :your_resources do"
        say "    member do"
        say "      post :#{file_name}"
        say "    end"
        say "  end"
        say ""
        say "Add a controller method for the action:", :yellow
        say ""
        say "  def #{file_name}"
        say "    # your custom action logic"
        say "  end"
        say ""
      end

      private

      def button_class_name
        "#{class_name}Button"
      end

      def parent_button_class
        options[:model_action] ? "ModelActionButton" : "Base"
      end

      def human_name
        file_name.humanize
      end
    end
  end
end
