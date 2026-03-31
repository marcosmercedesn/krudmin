module Krudmin
  module MutationHandlers
    class InlineEditUpdate < SimpleDelegator
      attr_reader :model, :success_message

      def initialize(controller, model, success_message)
        @model = model
        @success_message = success_message

        super(controller)
      end

      def perform
        respond_to do |format|
          format.html do
            flash[:info] = [success_message]
            redirect_to edit_resource_path(model), status: :see_other
          end

          format.turbo_stream do
            render "inline_edit_success", locals: { success_message: success_message }
          end
        end
      end

      def self.call(controller, model, success_message)
        new(controller, model, success_message).perform
      end
    end
  end
end
