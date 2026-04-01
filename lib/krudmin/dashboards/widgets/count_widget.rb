module Krudmin
  module Dashboards
    module Widgets
      class CountWidget < Base
        DEFAULT_GRID_CLASS = "col-12 col-md-6 col-xl-3"

        def value
          @value ||= relation.count
        end

        def empty?
          value.zero?
        end

        def hint
          options[:hint] || I18n.t("krudmin.labels.total_records")
        end
      end
    end
  end
end