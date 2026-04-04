module Krudmin
  module MutationHandlers
    class ModalFormContextUpdate < SimpleDelegator
      attr_reader :model, :success_message, :redirect_action_method
      def initialize(controller, model, success_message, redirect_action_method: :edit)
        @model = model
        @success_message = success_message
        @redirect_action_method = redirect_action_method

        super(controller)
      end

      def successful_html_response(format)
        format.html do
          flash[:info] = [success_message]

          case redirect_action_method
          when :index
            redirect_to resource_root
          when :show
            redirect_to resource_path(model)
          else
            redirect_to edit_resource_path(model)
          end
        end
      end

      def successful_turbo_stream_response(format)
        format.turbo_stream do
          instance_variable_set(:@model_id, model.id)

          unless redirect_action_method == :edit
            render "show", locals: { messages: [ActionResultMessage.new("info", success_message)] }
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

      def self.call(controller, model, success_message, redirect_action_method: :edit)
        new(controller, model, success_message, redirect_action_method: redirect_action_method).perform
      end
    end
  end
end
