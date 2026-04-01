module Krudmin
  module Dashboards
    module Widgets
      class ListWidget < Base
        DEFAULT_GRID_CLASS = "col-12 col-xl-4"

        def records
          @records ||= relation.limit(limit)
        end

        def secondary_attribute
          options[:secondary_attribute]&.to_sym
        end

        def empty?
          records.none?
        end

        def limit
          options[:limit] || 8
        end

        def label_for(record)
          resource_manager.label_for(record)
        end

        def secondary_value_for(record)
          return unless secondary_attribute

          format_value(record.public_send(secondary_attribute))
        end
      end
    end
  end
end