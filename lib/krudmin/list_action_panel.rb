module Krudmin
  class ListActionPanel
    attr_reader :model, :actions, :view_context, :remote

    def initialize(model, actions, view_context, remote: false)
      @model = model
      @actions = actions
      @view_context = view_context
      @remote = remote
    end

    def self.for(model, actions, view_context, remote: false)
      new(model, actions, view_context, remote: remote)
    end

    def to_s
      (actions.map do |action|
        action_button(action).to_s
      end).join.html_safe
    end

    def action_button(button_type)
      manager = view_context.respond_to?(:krudmin_manager) ? view_context.krudmin_manager : nil

      if manager && manager.custom_action?(button_type)
        definition = manager.custom_action_for(button_type)
        Krudmin::ActionButtons::CustomActionButton.new(
          :list, view_context, model,
          action_definition: definition,
          html_options: { remote: remote }
        )
      else
        "Krudmin::ActionButtons::#{button_type.to_s.classify}Button".constantize.new(:list, view_context, model, remote: remote)
      end
    rescue NameError => e
      raise e unless manager&.custom_action?(button_type)
      # Fallback: if constantize fails for a custom action name, that's expected
      definition = manager.custom_action_for(button_type)
      Krudmin::ActionButtons::CustomActionButton.new(
        :list, view_context, model,
        action_definition: definition,
        html_options: { remote: remote }
      )
    end
  end
end
