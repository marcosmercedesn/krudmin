module Krudmin
  module MutationHandlers
    class ModalFormContextUpdate < SimpleDelegator
      attr_reader :model, :success_message
      def initialize(controller, model, success_message)
        @model = model
        @success_message = success_message

        super(controller)
      end

      def successful_html_response(format)
        format.html do
          flash[:info] = [success_message]

          redirect_to edit_resource_path(model)
        end
      end

      def successful_turbo_stream_response(format)
        format.turbo_stream do
          instance_variable_set(:@model_id, model.id)

          # If the model was just created, render the `create` turbo stream
          # which inserts the new row into the list. For updates, keep the
          # existing `edit` behavior that replaces the existing row.
          if model.respond_to?(:previous_changes) && model.previous_changes.key?("id")
            render "create", locals: { messages: [ActionResultMessage.new("info", success_message)] }
          else
            render "edit", locals: { messages: [ActionResultMessage.new("info", success_message)] }
          end
        end
      end

      def perform
        respond_to do |format|
          successful_html_response(format)

          successful_turbo_stream_response(format)
        end
      end

      def self.call(controller, model, success_message)
        new(controller, model, success_message).perform
      end
    end
  end
end
