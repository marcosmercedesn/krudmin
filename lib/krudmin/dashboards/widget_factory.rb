module Krudmin
  module Dashboards
    module WidgetFactory
      module_function

      def build(type, context:, resource_manager:, options:)
        widget_class_for(type).new(context:, resource_manager:, **options)
      end

      def widget_class_for(type)
        "Krudmin::Dashboards::Widgets::#{type.to_s.classify}Widget".constantize
      end
    end
  end
end