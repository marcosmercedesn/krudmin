require_relative "base"
require_relative "../presenters/state_machine_field_presenter"

module Krudmin
  module Fields
    class StateMachine < Base
      PRESENTER = Krudmin::Presenters::StateMachineFieldPresenter

      DEFAULT_BADGE_CLASS = "secondary".freeze

      def current_state
        value.to_s
      end

      def transitions
        options.fetch(:transitions, {}).deep_symbolize_keys
      end

      def colors
        options.fetch(:colors, {}).deep_symbolize_keys
      end

      def transition_labels
        options.fetch(:transition_labels, {}).deep_symbolize_keys
      end

      def transition_events_for_current_state
        configured = Array(transitions[current_state.to_sym]).map(&:to_sym)

        # Prefer explicit configuration when present, but only keep events
        # that are currently allowed by the model.
        if configured.any?
          configured.select { |event| transition_allowed?(event) }
        else
          allowed_aasm_events
        end
      end

      def transition_allowed?(event)
        return false unless model

        model.respond_to?("may_#{event}?") && model.public_send("may_#{event}?")
      end

      def transition_label_for(event)
        transition_labels.fetch(event.to_sym, event.to_s.humanize)
      end

      def badge_class_for(state)
        colors.fetch(state.to_sym, DEFAULT_BADGE_CLASS)
      end

      private

      def allowed_aasm_events
        return [] unless model.respond_to?(:aasm)
        return [] unless model.aasm.respond_to?(:events)

        model.aasm.events(permitted: true).map { |event| event.name.to_sym }
      end
    end
  end
end
