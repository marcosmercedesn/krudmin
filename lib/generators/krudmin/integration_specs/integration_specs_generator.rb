module Krudmin
  module Generators
    class IntegrationSpecsGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      desc "Generate a complete integration test suite for a Krudmin resource"

      class_option :nested_forms, type: :boolean, default: false, desc: "Generate specs for nested forms (HasMany/HasOne)"
      class_option :inline_editing, type: :boolean, default: false, desc: "Generate specs for inline editing"
      class_option :state_machine, type: :boolean, default: false, desc: "Generate specs for AASM state machine transitions"
      class_option :authorization, type: :boolean, default: false, desc: "Generate specs for Pundit policy authorization"
      class_option :no_pagination, type: :boolean, default: false, desc: "Skip pagination specs"
      class_option :no_search, type: :boolean, default: false, desc: "Skip search/filter specs"
      class_option :factory, type: :boolean, default: true, desc: "Generate FactoryBot factory"
      class_option :namespace, type: :string, default: "admin", desc: "Controller namespace"

      def create_page_object
        template "page.rb.tt", "spec/support/pages/#{singular_name}_page.rb"
      end

      def create_crud_specs
        template "crud/create_spec.rb.tt", "spec/features/#{plural_name}/crud/create_spec.rb"
        template "crud/read_spec.rb.tt", "spec/features/#{plural_name}/crud/read_spec.rb"
        template "crud/update_spec.rb.tt", "spec/features/#{plural_name}/crud/update_spec.rb"
        template "crud/destroy_spec.rb.tt", "spec/features/#{plural_name}/crud/destroy_spec.rb"
      end

      def create_state_transition_specs
        template "state_transitions/activate_spec.rb.tt", "spec/features/#{plural_name}/state_transitions/activate_spec.rb"
        template "state_transitions/deactivate_spec.rb.tt", "spec/features/#{plural_name}/state_transitions/deactivate_spec.rb"
        template "state_transitions/bulk_actions_spec.rb.tt", "spec/features/#{plural_name}/state_transitions/bulk_actions_spec.rb"
      end

      def create_search_and_filter_spec
        return if options[:no_search]

        template "search_and_filters_spec.rb.tt", "spec/features/#{plural_name}/search_and_filters_spec.rb"
      end

      def create_pagination_spec
        return if options[:no_pagination]

        template "pagination_spec.rb.tt", "spec/features/#{plural_name}/pagination_spec.rb"
      end

      def create_inline_editing_spec
        return unless options[:inline_editing]

        template "inline_editing_spec.rb.tt", "spec/features/#{plural_name}/inline_editing_spec.rb"
      end

      def create_nested_forms_spec
        return unless options[:nested_forms]

        template "nested_forms_spec.rb.tt", "spec/features/#{plural_name}/nested_forms_spec.rb"
      end

      def create_state_machine_spec
        return unless options[:state_machine]

        template "state_machine_spec.rb.tt", "spec/features/#{plural_name}/state_machine_spec.rb"
      end

      def create_authorization_spec
        return unless options[:authorization]

        template "authorization_spec.rb.tt", "spec/features/#{plural_name}/authorization_spec.rb"
      end

      def create_factory
        return unless options[:factory]

        template "factory.rb.tt", "spec/factories/#{plural_name}.rb"
      end

      def enhance_page_features
        page_features_path = "spec/support/page_features.rb"

        if File.exist?(page_features_path)
          unless File.read(page_features_path).include?("def fill_form_for")
            append_file page_features_path, "\n" + page_features_enhancements
          end
        else
          create_file page_features_path, page_features_module
        end
      end

      def print_instructions
        say "\n✓ Integration test suite generated!", :green
        say "\nGenerated files:"
        say "  - spec/support/pages/#{singular_name}_page.rb", :cyan
        say "  - spec/features/#{plural_name}/crud/*.rb (4 files)", :cyan
        say "  - spec/features/#{plural_name}/state_transitions/*.rb (3 files)", :cyan
        say "  - spec/features/#{plural_name}/search_and_filters_spec.rb", :cyan unless options[:no_search]
        say "  - spec/features/#{plural_name}/pagination_spec.rb", :cyan unless options[:no_pagination]
        say "  - spec/features/#{plural_name}/inline_editing_spec.rb", :cyan if options[:inline_editing]
        say "  - spec/features/#{plural_name}/nested_forms_spec.rb", :cyan if options[:nested_forms]
        say "  - spec/features/#{plural_name}/state_machine_spec.rb", :cyan if options[:state_machine]
        say "  - spec/features/#{plural_name}/authorization_spec.rb", :cyan if options[:authorization]
        say "  - spec/factories/#{plural_name}.rb", :cyan if options[:factory]
        say "\n⚠️  Next steps:"
        say "  1. Update spec/factories/#{plural_name}.rb with your model attributes", :yellow
        say "  2. Customize #{plural_name}_page.rb with resource-specific helpers", :yellow
        say "  3. Adjust spec files to match your ResourceManager configuration", :yellow
        say "  4. Update TODO comments in spec files for your specific state machine/form fields", :yellow if options[:state_machine]
        say "  5. Verify authentication/authorization helpers (login_as, etc.) match your setup", :yellow if options[:authorization]
        say "  6. Run: bundle exec rspec spec/features/#{plural_name}/", :yellow
      end

      private

      def page_features_module
        File.read(File.expand_path("../../../../../../../spec/support/page_features.rb", __FILE__)) rescue minimal_page_features
      rescue
        minimal_page_features
      end

      def minimal_page_features
        <<~RUBY
          module PageFeatures
            def row_css_for(model)
              "tr.item-model-#{model.id}"
            end
          end
        RUBY
      end

      def page_features_enhancements
        <<~RUBY

          # ===== Added by integration_specs generator =====

          # Form Interactions
          def fill_form_for(model_name, attributes = {})
            attributes.each do |field, value|
              fill_in(:"#{model_name}_#{field}", with: value)
            end
          end

          def submit_form
            click_button(class: 'btn-primary')
          end

          # Dialog/Modal Confirmation
          def accept_confirmation
            accept_alert
          end

          def dismiss_confirmation
            dismiss_prompt
          end

          # Bulk Actions
          def select_rows(*models)
            models.each do |model|
              within(row_css_for(model)) do
                find('.select-item').click
              end
            end
          end

          def apply_bulk_action(action_name)
            select(action_name, from: 'bulk_action_select')
            click_button('Apply')
            accept_alert
          end

          # Search & Filtering
          def search_for(term)
            fill_in('q', with: term)
            click_button('Search')
          end

          def filter_by(field, value)
            select(value, from: "search_#{field}")
            click_button('Filter')
          end

          # Pagination
          def go_to_page(page_number)
            click_link("#{page_number}")
          end

          # Inline Editing
          def inline_edit_field(model, field, new_value)
            within(row_css_for(model)) do
              find("[data-field='#{field}']").click
              fill_in(class: 'inline-edit-input', with: new_value)
              find('.inline-edit-save').click
            end
          end
        RUBY
      end
    end
  end
end
