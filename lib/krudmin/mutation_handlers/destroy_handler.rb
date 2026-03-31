module Krudmin
  module MutationHandlers
    class DestroyHandler < SimpleDelegator
      attr_reader :model, :success_message, :failure_message
      def initialize(controller, model, success_message, failure_message)
        @model = model
        @success_message = success_message
        @failure_message = failure_message

        super(controller)
      end

      def valid?
        model.destroy
      end

      def perform
        valid? ? valid_path : invalid_path
      end

      def valid_path
        respond_to do |format|
          format.html do
            flash[:error] = success_message

            redirect_to resource_root, status: :see_other
          end

          format.turbo_stream { render "destroy" }
        end
      end

      def invalid_path
        respond_to do |format|
          format.html do
            flash[:error] = failure_message

            redirect_to resource_root, status: :see_other
          end

          format.turbo_stream { render "destroy" }
        end
      end

      def self.call(controller, model, success_message, failure_message)
        new(controller, model, success_message, failure_message).perform
      end
    end
  end
end
