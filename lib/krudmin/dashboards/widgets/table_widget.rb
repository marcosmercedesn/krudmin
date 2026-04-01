module Krudmin
  module Dashboards
    module Widgets
      class TableWidget < Base
        DEFAULT_GRID_CLASS = "col-12"

        def records
          @records ||= relation.limit(limit)
        end

        def columns
          @columns ||= resource_manager.dashboard_columns_for(options[:columns]).map(&:to_sym)
        end

        def column_label(column)
          resource_manager.field_for(column).options.fetch(:input, {}).fetch(:label, resource_manager.model_class.human_attribute_name(column))
        end

        def cell_value(record, column)
          resource_manager.field_for(column, record).to_s
        end

        def empty?
          records.none?
        end

        def limit
          options[:limit] || 10
        end
      end
    end
  end
end