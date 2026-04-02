module Krudmin
  module Generators
    class StateMachineGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      desc "Generate AASM workflow concern and Krudmin integration snippets"

      class_option :attribute, type: :string, default: "status", desc: "State machine column name"
      class_option :specs, type: :boolean, default: true, desc: "Generate RSpec concern spec"

      def create_workflow_concern
        template "workflow_concern.rb.tt", "app/models/concerns/#{file_name}_workflow.rb"
      end

      def create_workflow_spec
        return unless options[:specs]

        template "workflow_spec.rb.tt", "spec/models/concerns/#{file_name}_workflow_spec.rb"
      end

      def print_post_install
        say ""
        say "State machine scaffold generated!", :green
        say ""
        say "1) Include the concern in your model:", :yellow
        say "  class #{class_name} < ApplicationRecord"
        say "    include #{workflow_module_name}"
        say "  end"
        say ""
        say "2) Add route:", :yellow
        say "  resources :#{file_name.pluralize} do"
        say "    member { post :transition }"
        say "  end"
        say ""
        say "3) Configure ResourceManager:", :yellow
        say "  ATTRIBUTE_TYPES = {"
        say "    #{attribute_name}: {"
        say "      type: :StateMachine,"
        say "      transitions: { draft: [:submit], submitted: [:approve, :reject], approved: [:pay] },"
        say "      colors: { draft: :secondary, submitted: :warning, approved: :success, paid: :info, rejected: :danger }"
        say "    }"
        say "  }"
      end

      private

      def workflow_module_name
        "#{class_name}Workflow"
      end

      def attribute_name
        options[:attribute]
      end
    end
  end
end
