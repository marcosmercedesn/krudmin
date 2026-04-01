module Krudmin
  class Dashboard
    class << self
      def inherited(subclass)
        super
        subclass.instance_variable_set(:@widget_definitions, widget_definitions.dup)
        subclass.instance_variable_set(:@page_title, @page_title)
        subclass.instance_variable_set(:@page_description, @page_description)
        subclass.instance_variable_set(:@toolbar_block, @toolbar_block)
      end

      def page_title(value = nil)
        return @page_title if value.nil?

        @page_title = value
      end

      def page_description(value = nil)
        return @page_description if value.nil?

        @page_description = value
      end

      def toolbar(&block)
        return @toolbar_block unless block_given?

        @toolbar_block = block
      end

      def widget(type, resource:, **options)
        widget_definitions << Krudmin::Dashboards::WidgetDefinition.new(type: type, resource: resource, options: options)
      end

      def widget_definitions
        @widget_definitions ||= []
      end
    end

    attr_reader :context

    delegate :page_title, :page_description, :toolbar, :widget_definitions, to: :class

    def initialize(context:)
      @context = context
    end

    def widgets
      @widgets ||= widget_definitions.filter_map { |definition| definition.build(context) }
    end

    def render_toolbar(view_context)
      return unless toolbar

      view_context.configure_toolbar(:list, view_context) do |builder|
        view_context.instance_exec(builder, &toolbar)
      end
    end
  end
end