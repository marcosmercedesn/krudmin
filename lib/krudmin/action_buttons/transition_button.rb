module Krudmin
  module ActionButtons
    class TransitionButton < ModelActionButton
      attr_reader :event_name, :attribute

      def initialize(page, view_context, model, event_name, html_options = {}, &block)
        @event_name = event_name.to_sym

        options = html_options.dup
        @attribute = options.delete(:attribute)&.to_sym || detect_attribute!(view_context)
        @custom_label = options.delete(:label)

        super(page, view_context, model, options, &block)

        @action_path = build_action_path
      end

      def button_label
        @button_label ||= @custom_label.presence || state_machine_field.transition_label_for(event_name)
      end

      def tooltip_title
        button_label
      end

      def render_list
        return "" unless render_button?

        super
      end

      def render_form
        return "" unless render_button?

        super
      end

      def default_locals
        super.merge(attribute: attribute, button_label: button_label, event_name: event_name)
      end

      private

      def render_button?
        state_machine_field.transition_allowed?(event_name) && transition_authorized?
      end

      def transition_authorized?
        !view_context.respond_to?(:transition_access?) || view_context.transition_access?(model, event_name)
      end

      def build_action_path
        view_context.transition_path(model, event: event_name, attribute: attribute, context: page_context)
      end

      def page_context
        page == :form ? :form : :list
      end

      def state_machine_field
        @state_machine_field ||= begin
          field = view_context.krudmin_manager.field_for(attribute, model)

          unless field.is_a?(Krudmin::Fields::StateMachine)
            raise ArgumentError, "#{attribute} is not configured as a StateMachine field"
          end

          field
        end
      end

      def detect_attribute!(view_context)
        manager = view_context.krudmin_manager
        candidates = [
          *Array(manager.editable_attributes),
          *Array(manager.displayable_attributes),
          *Array(manager.listable_attributes),
          *Array(manager.searchable_attributes)
        ].uniq.select do |candidate|
          manager.field_class_for(candidate).type == Krudmin::Fields::StateMachine
        end

        return candidates.first if candidates.one?

        if candidates.empty?
          raise ArgumentError, "No StateMachine field configured for #{manager.class.name}"
        end

        raise ArgumentError, "Multiple StateMachine fields configured for #{manager.class.name}; pass attribute: explicitly"
      end
    end
  end
end
