module Krudmin
  module Dashboards
    class Context
      attr_reader :controller

      delegate :view_context, :params, :_current_user, to: :controller

      def initialize(controller)
        @controller = controller
      end

      def resource_accessible?(resource_manager)
        return true unless Krudmin::Config.pundit_enabled?

        controller.send(:policy, resource_manager.model_class).index?
      end

      def authorized_relation(resource_manager)
        relation = resource_manager.scope

        return relation unless Krudmin::Config.pundit_enabled?

        controller.send(:policy_scope, relation)
      end
    end
  end
end