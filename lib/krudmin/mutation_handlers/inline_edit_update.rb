module Krudmin
  module MutationHandlers
    class InlineEditUpdate < SimpleDelegator
      attr_reader :model, :success_message, :new_record

      def initialize(controller, model, success_message, new_record: nil)
        @model = model
        @success_message = success_message
        @new_record = new_record

        super(controller)
      end

      def perform
        respond_to do |format|
          format.html do
            flash[:info] = [success_message]
            redirect_to edit_resource_path(model), status: :see_other
          end

          format.turbo_stream do
            render "inline_edit_success", locals: { success_message: success_message, new_record: new_record }
          end
        end
      end

      def self.call(controller, model, success_message, new_record: nil)
        new(controller, model, success_message, new_record: new_record).perform
      end
    end
  end
end
