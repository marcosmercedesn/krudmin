module Krudmin
  module MutationHandlers
    class FormContextUpdate < SimpleDelegator
      attr_reader :controller, :model, :success_message, :redirect_action_method
      def initialize(controller, model, success_message, redirect_action_method: :edit)
        @model = model
        @success_message = success_message
        @redirect_action_method = redirect_action_method

        super(controller)
      end

      def perform
        flash[:info] = [success_message]

        case redirect_action_method
        when :index
          redirect_to resource_root, status: :see_other
        when :show
          redirect_to resource_path(model), status: :see_other
        else
          redirect_to edit_resource_path(model), status: :see_other
        end
      end

      def self.call(controller, model, success_message, redirect_action_method: :edit)
        new(controller, model, success_message, redirect_action_method: redirect_action_method).perform
      end
    end
  end
end
