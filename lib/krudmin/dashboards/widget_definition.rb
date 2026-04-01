module Krudmin
  module Dashboards
    class WidgetDefinition
      attr_reader :type, :resource, :options

      def initialize(type:, resource:, options: {})
        @type = type.to_sym
        @resource = resource
        @options = options
      end

      def build(context)
        resource_manager = resource.new
        return unless context.resource_accessible?(resource_manager)

        WidgetFactory.build(type, context:, resource_manager:, options:)
      end
    end
  end
end