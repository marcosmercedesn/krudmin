module Krudmin
  module MutationHandlers
    class TransitionHandler < SimpleDelegator
      SUCCESS_FLASH_TYPE = :success
      FAILURE_FLASH_TYPE = :error

      attr_reader :event_name, :success_message, :failure_message

      def initialize(controller, event_name, success_message, failure_message)
        @event_name = event_name.to_s
        @success_message = success_message
        @failure_message = failure_message

        super(controller)
      end

      def valid?
        method_name = "#{event_name}!"
        return false unless model.respond_to?(method_name)

        model.public_send(method_name)
      rescue StandardError => error
        model.errors.add(:base, error.message) if model.respond_to?(:errors)
        false
      end

      def perform
        valid? ? valid_path : invalid_path
      end

      def self.call(controller, event_name, success_message, failure_message)
        new(controller, event_name, success_message, failure_message).perform
      end

      private

      def valid_path
        valid_context_dispatcher.new(self, success_message, self.class::SUCCESS_FLASH_TYPE).dispatch
      end

      def invalid_path
        invalid_context_dispatcher.new(self, failure_message, self.class::FAILURE_FLASH_TYPE).dispatch
      end

      def model_context
        params[:context]
      end

      def valid_context_dispatcher
        case model_context
        when "form" then ValidFormContext
        else ValidListContext
        end
      end

      def invalid_context_dispatcher
        case model_context
        when "form" then InvalidFormContext
        else InvalidListContext
        end
      end

      class ValidListContext < Krudmin::ActionDispatcher
        private

        def html_response(format)
          format.html do
            flash[flash_type] = message

            redirect_to resource_root, status: :see_other
          end
        end

        def turbo_stream_response(format)
          format.turbo_stream { render "transition" }
        end
      end

      class InvalidListContext < ValidListContext
        private

        def turbo_stream_response(format)
          format.turbo_stream { render partial: "error_toast", locals: { error_messages: [message] } }
        end
      end

      class ValidFormContext < Krudmin::ActionDispatcher
        def dispatch
          flash[flash_type] = [message]

          redirect_to edit_resource_path(model), status: :see_other
        end
      end

      class InvalidFormContext < ValidFormContext; end
    end
  end
end
