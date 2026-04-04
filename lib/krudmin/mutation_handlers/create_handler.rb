module Krudmin
  module MutationHandlers
    class CreateHandler
      attr_reader :controller, :model, :success_message, :new_record
      def initialize(controller, model, success_message)
        @controller = controller
        @model = model
        @success_message = success_message
        @new_record = model.new_record?
      end

      def self.call(controller, model, success_message)
        new(controller, model, success_message).perform
      end

      def perform
        valid? ? valid_path : invalid_path
      end

      def on_error_view
        "new"
      end

      private

      def valid?
        model.save
      end

      def valid_path
        valid_context_mutator.(controller, model, success_message, redirect_action_method: redirect_action_method)
      end

      def redirect_action_method
        new_record ? controller.create_redirect_action : controller.update_redirect_action
      end

      def valid_context_mutator
        if controller.inline_edit_context?
          InlineEditUpdate
        elsif controller.modal_form_context?
          ModalFormContextUpdate
        else
          FormContextUpdate
        end
      end

      def invalid_path
        controller.respond_to do |format|
          format.html { controller.render on_error_view, status: :unprocessable_entity }
          format.turbo_stream { controller.render on_error_turbo_stream_view, status: :unprocessable_entity }
        end
      end

      def on_error_turbo_stream_view
        controller.inline_edit_context? ? "inline_edit_error" : "form_errors"
      end
    end
  end
end
