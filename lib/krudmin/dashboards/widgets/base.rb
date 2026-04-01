module Krudmin
  module Dashboards
    module Widgets
      class Base
        DEFAULT_GRID_CLASS = "col-12 col-xl-6"

        attr_reader :context, :resource_manager, :options

        delegate :view_context, to: :context

        def initialize(context:, resource_manager:, **options)
          @context = context
          @resource_manager = resource_manager
          @options = options
        end

        def id
          @id ||= [self.class.name.demodulize.underscore, resource_manager.class.name.underscore, label.parameterize].join("-")
        end

        def type
          self.class.name.demodulize.delete_suffix("Widget").underscore.to_sym
        end

        def partial_path
          "#{Krudmin::Config.theme}/dashboard/widgets/#{type}"
        end

        def label
          options[:label] || resource_manager.resources_label
        end

        def description
          options[:description]
        end

        def icon
          options[:icon]
        end

        def tone
          options[:tone] || "primary"
        end

        def background
          selected_background = (options[:background] || :default).to_sym

          return selected_background if available_backgrounds.include?(selected_background)

          :default
        end

        def background_class
          "dashboard-widget-bg-#{background}"
        end

        def grid_class
          options[:grid] || self.class::DEFAULT_GRID_CLASS
        end

        def empty?
          false
        end

        def relation
          @relation ||= begin
            scoped_relation = context.authorized_relation(resource_manager)
            resource_manager.dashboard_relation(options[:scope], relation: scoped_relation, user: context._current_user, context:)
          end
        end

        def resource_path
          path_option = options[:path]

          return view_context.instance_exec(&path_option) if path_option.is_a?(Proc)
          return view_context.public_send(path_option) if path_option.respond_to?(:to_sym)

          view_context.polymorphic_path(resource_manager.model_class)
        rescue StandardError
          nil
        end

        def format_value(value)
          return value if value.is_a?(Numeric)
          return value.strftime("%b %d, %Y") if value.respond_to?(:strftime)

          value.presence || "-"
        end

        private

        def available_backgrounds
          @available_backgrounds ||= begin
            options = context.controller.respond_to?(:widget_background_options) ? context.controller.widget_background_options : [:default]
            Array(options).map(&:to_sym)
          end
        end
      end
    end
  end
end