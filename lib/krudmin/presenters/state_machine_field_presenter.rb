module Krudmin
  module Presenters
    class StateMachineFieldPresenter < BaseFieldPresenter
      def render_search
        states = (field.transitions.keys + field.colors.keys).uniq
        state_options = states.map { |state| [state.to_s.humanize, state] }

        render_partial(:search,
          options_attribute: options_attribute,
          state_options: state_options)
      end

      def render_show
        render_partial(:show,
          current_state: field.current_state,
          badge_class: field.badge_class_for(field.current_state),
          transition_events: field.transition_events_for_current_state,
          transition_label_for: ->(event) { field.transition_label_for(event) })
      end

      def render_list
        render_partial(:list,
          current_state: field.current_state,
          badge_class: field.badge_class_for(field.current_state),
          transition_events: field.transition_events_for_current_state,
          transition_label_for: ->(event) { field.transition_label_for(event) })
      end
    end
  end
end
